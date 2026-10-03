#!/usr/bin/env bash
# Ubuntu Server 26.04 live installer, UEFI, one VirtIO target disk.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash prepare.sh MODE [DISK] [POOL_GIB]
  check   Check a blank target without changing it (default).
  create  Partition and format a blank target, then configure the installer.
  resume  Preserve existing runbook storage and restore installer configuration.
Defaults: DISK=/dev/vda; POOL_GIB=auto (whole disk GiB minus 8).
Auto sizing reserves 3 GiB for boot and approximately 5 GiB of free VG space.
EOF
}
fail() { echo "STOP: $*" >&2; exit 1; }
mode=${1:-check}
disk=${2:-/dev/vda}
pool_gib=${3:-auto}
case "$mode" in check|create|resume) ;; -h|--help) usage; exit 0 ;; *) usage; exit 1 ;; esac
[[ $# -le 3 ]] || fail "Too many arguments"
[[ $EUID == 0 ]] || fail "Run in the installer root shell or with sudo"
[[ $disk =~ ^/dev/vd[a-z]$ ]] || fail "Expected a whole VirtIO disk, such as /dev/vda"
[[ $pool_gib == auto || $pool_gib =~ ^[1-9][0-9]*$ ]] || fail "Pool size must be auto or a whole number of GiB"
[[ -d /sys/firmware/efi && -f /cdrom/casper/install-sources.yaml ]] || fail "Use the Ubuntu Server ISO in UEFI mode"
# This is the release whose installer/Dracut integration has been inspected.
source /etc/os-release
[[ $ID == ubuntu && $VERSION_ID == 26.04 ]] || fail "This recipe requires Ubuntu Server 26.04"
[[ -b $disk ]] || fail "$disk is not a block device"
for command in lsblk blockdev wipefs pvs vgs sfdisk findmnt python3 mount umount find; do
    command -v "$command" >/dev/null || fail "Missing $command"
done
if [[ $pool_gib == auto ]]; then
    disk_bytes=$(blockdev --getsize64 "$disk") || fail "Could not read target capacity"
    pool_gib=$((disk_bytes / 1073741824 - 8))
fi
[[ $pool_gib -ge 10 && $pool_gib -le 1024 ]] || fail "Pool size must be 10–1024 GiB; choose a suitable disk size or explicit pool size"
[[ $(blockdev --getro "$disk") == 0 ]] || fail "Target is read-only"
[[ -z $(lsblk -nr -o MOUNTPOINTS "$disk" | tr -d '[:space:]') ]] || fail "Target or one of its volumes is mounted"
findmnt /target >/dev/null && fail "An installation is already using /target"

check_blank() {
    [[ -z $(lsblk -nr -o MOUNTPOINTS "$disk" | tr -d '[:space:]') ]] || fail "Target became mounted"
    findmnt /target >/dev/null && fail "An installation is already using /target"
    [[ $(lsblk -nr -o NAME "$disk" | wc -l) == 1 ]] || fail "Target has partitions or mapped volumes; use resume only for this recipe's storage"
    signatures=$(wipefs --noheadings "$disk") || fail "Could not inspect target signatures"
    physical_volumes=$(pvs --noheadings -o pv_name) || fail "Could not inspect physical volumes"
    volume_groups=$(vgs --noheadings -o vg_name) || fail "Could not inspect volume groups"
    [[ -z $signatures ]] || fail "Target has existing signatures; this script will not erase them"
    [[ -z $physical_volumes ]] || fail "Unexpected existing physical volumes"
    [[ -z $volume_groups ]] || fail "Unexpected existing volume groups"
    # EFI + boot = 3 GiB; leave at least 1 GiB beyond the pool for alignment/reserve.
    [[ $(blockdev --getsize64 "$disk") -ge $(((pool_gib + 4) * 1073741824)) ]] || fail "Pool is too large for target"
}

if [[ $mode != resume ]]; then
    check_blank
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$disk"
    echo "Blank target checked: $disk; VDO physical pool: ${pool_gib} GiB"
    [[ $mode != check ]] || exit 0
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
[[ -f $script_dir/build-autoinstall.py ]] || fail "Keep build-autoinstall.py beside prepare.sh"
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y vdo lvm2 xfsprogs dosfstools e2fsprogs tzdata
timedatectl list-timezones >/dev/null
modprobe dm_vdo
dmsetup targets | awk '$1 == "vdo" { found=1 } END { exit !found }' || fail "VDO kernel target unavailable"

if [[ $mode == create ]]; then
    # The checks above deliberately prohibit formatting an existing installation.
    # Recheck after package installation in case another process touched the disk.
    check_blank
    sfdisk "$disk" <<'EOF'
label: gpt
size=1G, type=U, name="EFI"
size=2G, type=L, name="boot"
type=linux-lvm, name="LVM"
EOF
    udevadm settle
    mkfs.fat -F 32 -n EFI "${disk}1"
    mkfs.ext4 -L boot "${disk}2"
    pvcreate "${disk}3"
    vgcreate vg0 "${disk}3"
    # Omitting -V avoids logical overcommit; let LVM account for VDO overhead.
    lvcreate --type vdo -n root -L "${pool_gib}G" --compression y --deduplication y vg0/vdopool
    mkfs.xfs -K -m reflink=1 -L root /dev/vg0/root
    vgcfgbackup vg0
fi

# Never use resume to reinstall over an OS or existing development data.
if [[ $mode == resume ]]; then
    [[ -z $(lsblk -nr -o MOUNTPOINTS "$disk" | tr -d '[:space:]') ]] || fail "Target became mounted"
    findmnt /target >/dev/null && fail "An installation is already using /target"
    [[ $(lvs --noheadings -o segtype vg0/root | xargs) == vdo ]] || fail "Missing VDO root"
    check_mount=$(mktemp -d)
    trap 'umount "$check_mount" 2>/dev/null || true; rmdir "$check_mount" 2>/dev/null || true' EXIT
    mount -o ro,norecovery /dev/vg0/root "$check_mount"
    first_entry=$(find "$check_mount" -mindepth 1 -maxdepth 1 -print -quit)
    umount "$check_mount"
    rmdir "$check_mount"
    trap - EXIT
    [[ -z $first_entry ]] || fail "Root contains files; recover the installed system instead of reinstalling"
fi

# Build to a temporary file; do not overwrite the live config on validation failure.
config_file=$(mktemp)
trap 'rm -f "$config_file"' EXIT
python3 "$script_dir/build-autoinstall.py" --disk "$disk" --output "$config_file"
install -m 600 "$config_file" /autoinstall.yaml
lvs -a -o lv_name,segtype,lv_size,pool_lv,data_percent
vdostats --human-readable
systemctl restart snap.subiquity.subiquity-server.service
echo "Storage preserved and installer restarted. Return to the installer and enter your identity/SSH choices."
echo "If anything fails, inspect the existing volumes; never rerun create on a prepared disk."
