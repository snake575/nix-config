#!/usr/bin/env python3
"""Generate a preserved storage plan from an already prepared VDO root.

Reads devices and writes a configuration file; does not partition or format.
Requires Python's standard library only. JSON is also valid YAML.
"""

import argparse
import json
import re
import subprocess
from pathlib import Path


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def build(disk, timezone):
    if not re.fullmatch(r"/dev/vd[a-z]", disk):
        raise ValueError("Expected a whole VirtIO disk, such as /dev/vda")
    table = json.loads(output("sfdisk", "--json", disk))["partitiontable"]
    parts = table["partitions"]
    expected_types = [
        "c12a7328-f81f-11d2-ba4b-00a0c93ec93b",
        "0fc63daf-8483-4772-8e79-3d69d8477de4",
        "e6d6d379-f507-44c2-a23c-238f2a3df928",
    ]
    if table["label"] != "gpt" or len(parts) != 3:
        raise ValueError("Expected exactly EFI, boot, and LVM partitions on GPT")
    for number, (part, expected) in enumerate(zip(parts, expected_types), 1):
        if part["node"] != f"{disk}{number}" or part["type"].lower() != expected:
            raise ValueError("Partition layout does not match this runbook")
    pvs = json.loads(output("pvs", "--reportformat", "json", "-o", "pv_name,vg_name"))
    members = [p["pv_name"] for p in pvs["report"][0]["pv"] if p["vg_name"] == "vg0"]
    if members != [f"{disk}3"]:
        raise ValueError("vg0 must belong only to the selected disk's third partition")
    if output("lvs", "--noheadings", "-o", "segtype", "vg0/root") != "vdo":
        raise ValueError("vg0/root is not a VDO logical volume")
    for device, fstype in [(f"{disk}1", "vfat"), (f"{disk}2", "ext4"), ("/dev/vg0/root", "xfs")]:
        if output("blkid", "-s", "TYPE", "-o", "value", device) != fstype:
            raise ValueError(f"{device} must already contain {fstype}")

    config = [{"id": "disk", "type": "disk", "path": disk, "ptable": "gpt",
               "preserve": True, "grub_device": False}]
    for number, part in enumerate(parts, 1):
        entry = {"id": f"part-{number}", "type": "partition", "device": "disk",
                 "number": number, "size": part["size"] * table["sectorsize"],
                 "offset": part["start"] * table["sectorsize"], "preserve": True}
        if number == 1:
            entry.update(flag="boot", grub_device=True)
        elif number == 3:
            entry["flag"] = "lvm"
        config.append(entry)
    config.extend([
        {"id": "vg0", "type": "lvm_volgroup", "name": "vg0", "devices": ["part-3"], "preserve": True},
        {"id": "root", "type": "lvm_partition", "name": "root", "volgroup": "vg0",
         "path": "/dev/vg0/root", "size": int(output("blockdev", "--getsize64", "/dev/vg0/root")), "preserve": True},
        {"id": "fs-root", "type": "format", "volume": "root", "fstype": "xfs", "preserve": True},
        {"id": "fs-boot", "type": "format", "volume": "part-2", "fstype": "ext4", "preserve": True},
        {"id": "fs-efi", "type": "format", "volume": "part-1", "fstype": "fat32", "preserve": True},
        {"id": "mount-root", "type": "mount", "device": "fs-root", "path": "/"},
        {"id": "mount-boot", "type": "mount", "device": "fs-boot", "path": "/boot"},
        {"id": "mount-efi", "type": "mount", "device": "fs-efi", "path": "/boot/efi"},
    ])
    dracut_config = '''mkdir -p /target/etc/dracut.conf.d
cat > /target/etc/dracut.conf.d/90-vdo-root.conf <<'EOF'
add_dracutmodules+=" lvm "
force_drivers+=" dm_vdo "
EOF
'''
    return {"autoinstall": {
        "version": 1,
        "interactive-sections": ["identity", "ssh"],
        "refresh-installer": {"update": False},
        "source": {"id": "ubuntu-server"},
        "timezone": timezone,
        "storage": {"config": config, "swap": {"size": 0}},
        "packages": ["vdo", "lvm2", "xfsprogs", "dracut", "qemu-guest-agent"],
        "late-commands": [
            ["sh", "-c", dracut_config],
            ["curtin", "in-target", "--target=/target", "--", "vgcfgbackup", "vg0"],
            ["curtin", "in-target", "--target=/target", "--", "dracut", "--regenerate-all", "--force"],
            ["curtin", "in-target", "--target=/target", "--", "update-grub"],
            ["curtin", "in-target", "--target=/target", "--", "systemctl", "enable", "fstrim.timer"],
        ],
    }}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--disk", default="/dev/vda")
    parser.add_argument("--timezone", default="Etc/UTC")
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    try:
        config = build(args.disk, args.timezone)
    except (ValueError, KeyError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Refusing to generate storage configuration: {error}\n")
    Path(args.output).write_text(json.dumps(config, indent=2) + "\n")
    print(f"Wrote preserved XFS-on-VDO plan to {args.output}; identity and SSH remain interactive.")


if __name__ == "__main__":
    main()
