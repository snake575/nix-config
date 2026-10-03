# Ubuntu development VM on Unraid: XFS on VDO

Use this recipe for a VM with a shared development filesystem: Ubuntu, `/nix`,
home directories, projects, and caches all use one XFS root on an LVM-managed
VDO pool. EFI and `/boot` remain ordinary partitions. Home Manager supplies the
user environment after Ubuntu is installed.

**Status: installation recipe in progress, not yet proven by a cold boot.**
The procedure is reusable for new VMs within its supported environment:
**Ubuntu Server 26.04, UEFI, and a blank VirtIO disk**. Keep that compatibility
restriction until another release or layout has been tested. The first machine's
observations and remaining checks are in the [validation record](unraid-vdo-validation.md).
The reusable creation script has not yet been run through a fresh installation.
Complete the boot checks below before treating this as the standard VM template.

Choose these values for each new VM:

| Input | How to choose it |
| --- | --- |
| VM name / guest hostname | A new unique name; enter the hostname in the installer |
| CPU / RAM | Fit the intended workload and the host's available resources |
| Virtual disk capacity | Fit the workload, caches, expected growth, and host free space |
| Guest disk device | Confirm with `lsblk`; the script defaults to `/dev/vda` |
| VDO physical pool | Automatically sized from the guest disk; optional GiB override |
| Networking | LAN bridge or NAT according to access needs, with a new MAC |
| Account / Home Manager profile | Match the user environment you intend to apply |
| Download host address | The LAN address of the machine serving the scripts |

The names `vg0`, `vdopool`, and `root` are storage conventions shared by this
recipe, not VM identities. Separate guests can use the same internal names.
EFI size, boot size, and the shared-root layout are also recipe constants.
Do not change an existing VM's filesystem using this bootstrap.

## 1. Create the VM

In Unraid, use these starting settings. Recheck host capacity for every VM.

| Setting | Value |
| --- | --- |
| Name | Your chosen unique VM name |
| CPU mode | Host Passthrough |
| vCPUs | 4; choose pinning around the host's other workloads |
| Initial / maximum memory | 8 GB / 8 GB |
| Machine / BIOS | Q35 / OVMF (UEFI) |
| Install ISO | Ubuntu Server 26.04.1 amd64 |
| Primary disk | New disk sized for this VM, stored on an SSD/NVMe pool |
| Disk type / bus | Raw / VirtIO |
| Discard | Unmap (Trim) |
| Disk / ISO boot order | 1 / 2 |
| Graphics / console | Virtual / VNC; prefer VGA over QXL for this recipe |
| Sound | None |
| Network | LAN bridge or NAT; `virtio-net`, fresh MAC address |
| Host share passthrough | Leave blank; projects live inside the guest disk |

`br0` gives the guest a LAN address. `virbr0` NAT is also suitable if only outbound
internet and Tailscale access are needed. Tailscale does not require bridging.
The network model `virtio-net` is appropriate; VirtIO disk bus is a separate setting.
Do not copy another VM's pinned CPUs blindly: two VMs can compete for the same
host threads, and host services need CPU time too.

Keep the VM image on the cache pool. Check the `domains` share's primary/secondary
storage and mover settings rather than assuming `/mnt/user/domains` guarantees
NVMe placement. Sparse raw images allocate host space as they are written;
their advertised capacity does not reserve or provide physical capacity.
Budget physical capacity for the other guests, host applications, backups, and
growth. Set a free-space allowance appropriate to the pool and monitor it.
Choose which projects and caches to bring over rather than copying another
development machine's entire disk usage estimate.

The reusable layout is:

| Component | Size / purpose |
| --- | --- |
| EFI, `/boot/efi` | 1 GiB, FAT32 |
| `/boot` | 2 GiB, ext4 |
| LVM partition / `vg0` | All remaining disk space |
| VDO physical pool | Whole disk GiB minus 8 by default; optional explicit size |
| Shared XFS root | LVM calculates the size that fits after VDO overhead |
| Free VG extents | Approximately 5 GiB with automatic sizing |

For example, automatic sizing selects a 52 GiB pool on a 60 GiB disk, 72 GiB
on an 80 GiB disk, or 92 GiB on a 100 GiB disk. These are capacity calculations,
not claims that all three sizes have been tested. Choose the disk according to
the workload; no 80 GiB minimum is imposed by this recipe.

VDO metadata and slab sizing account for the difference between pool and root
sizes. The free extents are not a second development filesystem. The recipe
omits `-V`, so the initial logical root fits even without compression; compression
reduces physical usage rather than promising a larger initial filesystem.
Actual savings and performance depend on the workload. See [LVM's VDO manual](https://man7.org/linux/man-pages/man7/lvmvdo.7.html).

## 2. Run the bootstrap instead of building storage in the GUI

The files are [prepare.sh](../scripts/unraid-vdo/prepare.sh),
[build-autoinstall.py](../scripts/unraid-vdo/build-autoinstall.py), and
[verify.sh](../scripts/unraid-vdo/verify.sh).

Start from a fresh blank disk. In the installer, confirm DHCP works, then open
**Help → Enter shell**. Do not create partitions in the guided storage screens.
The shell is normally already root; no `ubuntu` account is assumed.

On a trusted machine with this repository checked out, make a small download
directory containing only the bootstrap files:

```bash
mkdir -p /tmp/vdo-vm-bundle
tar -C scripts/unraid-vdo -cf /tmp/vdo-vm-bundle/bootstrap.tar \
  prepare.sh build-autoinstall.py verify.sh
python3 -m http.server 8765 --bind HOST_LAN_IP --directory /tmp/vdo-vm-bundle
```

Replace `HOST_LAN_IP` with that machine's LAN address. Leave the server running
while downloading. It serves scripts only, never private keys or the whole home
directory. Use this temporary HTTP transfer only on a trusted local network.

In the guest's root installer shell:

```bash
curl -f http://HOST_LAN_IP:8765/bootstrap.tar -o /tmp/vdo.tar
mkdir -p /tmp/vdo
tar -xf /tmp/vdo.tar -C /tmp/vdo
vm_disk=/dev/vda
bash /tmp/vdo/prepare.sh check "$vm_disk"
bash /tmp/vdo/prepare.sh create "$vm_disk"
exit
```

`check` changes nothing. **`create` formats the selected blank disk.** It refuses
existing partitions, filesystem signatures, mounted devices, or existing LVM
volumes. Verify the disk shown by `check` is the new guest disk. The scripts
support whole VirtIO disks such as `/dev/vda`, not NVMe/SATA device names.
Replace `vm_disk` after inspecting `lsblk` if this guest uses another VirtIO
device. Pool sizing uses the actual guest disk capacity rather than a fixed VM
size. To override it, append a GiB value to both commands, for example
`bash /tmp/vdo/prepare.sh check "$vm_disk" 48`, then use the same value for
`create`. An explicit pool must leave at least 4 GiB for boot, alignment, and
reserve; pool sizes supported by the script are 10–1024 GiB. Those bounds are
script checks, not a recommendation to build an unusually small system disk.

The script installs live VDO tools, creates storage, generates a configuration
that **preserves** the prepared devices, adds target VDO/Dracut packages and boot
configuration, and restarts the installer server. Only identity and SSH remain
interactive. The helper does not supply credentials or configure Tailscale.

Enter your chosen hostname, username, and password, and enable
**Install OpenSSH server**. Complete the install. If the UI retains an old
storage screen after restarting the server, do not submit that plan; restart
the installer client or reconnect its console to load the new server state.
The generated plan is `/autoinstall.yaml` (JSON syntax, which is valid YAML).
Confirm it declares preserved `vg0/root` as XFS mounted at `/`.

When the download finishes, stop the temporary HTTP server with Ctrl+C.

## 3. Verify the installed VM before migrating anything

Keep the ISO available for recovery until boot has been proven. After installation,
boot from the virtual disk, log in, and copy/download the repository's `verify.sh`
to the guest, then run:

```bash
sudo bash verify.sh
```

This checks XFS-on-VDO root, reflinks, separate boot filesystems, LVM and VDO in
the running kernel's initrd, the GRUB root argument, and scheduled trim. Inspect
`/boot/grub/grub.cfg` to confirm its root device/UUID matches the actual XFS root.
If checks fail, fix the initrd/boot configuration before migrating data.

Shut down cleanly, detach the install ISO in Unraid, start the VM again, and rerun
the checks. A reboot inside the ISO or successful `modprobe` is not a boot test.
Review `journalctl -b -p warning` and test a small real project with the package
manager and worktree workflow before copying important workloads.

GRUB cannot directly read this VDO root. Separate ext4 `/boot` supplies the kernel
and initrd; Linux/Dracut then activates VDO. Root `grub-probe` errors alone are
not a reason to repartition: the inspected Ubuntu scripts tolerate failed root
UUID/filesystem probing and use the device path. The installed `update-grub`
result and actual cold boot are the acceptance checks.

After those checks, follow [the repository setup](../README.md#setup) to install
Nix and apply the Home Manager profile for the chosen account. This personal
repository's Linux profile is currently `snake575` and fixes the account and
home directory as `snake575` and `/home/snake575`; use that account with
`home-manager switch --flake .#snake575`, or add a profile for a different user.
Install and authenticate Tailscale separately, with a unique device identity.
Home Manager currently manages user packages/settings; it does not reproduce
this Ubuntu storage layout, Tailscale authentication, or Hermes runtime data.
Migrate selected projects and Hermes configuration/data deliberately; do not
copy temporary installer SSH keys into the installed system.

## Recovery without starting over

- **VM powered off or unreachable:** check its Unraid state first. An SSH timeout
  does not establish a filesystem failure. If display-driver lockups appear in
  the logs, stop cleanly where possible and switch the console driver to VGA.
- **ISO restarted:** packages, temporary SSH keys, and `/autoinstall.yaml` in the
  live environment disappear. Disk partitions and VDO metadata remain. Download
  the bundle again, confirm the guest disk, and run
  `bash /tmp/vdo/prepare.sh resume "$vm_disk"`, then `exit`. If the shell was
  restarted, first set `vm_disk` again; shell variables are not persistent.
  `resume` validates the existing VDO layout and does not format it. Use it only
  before target installation begins; it refuses mounted target volumes and a
  root filesystem that already contains files.
- **Creation stopped partway:** inspect `lsblk`, `pvs`, `vgs`, and `lvs -a` first.
  `resume` only works when all three filesystems and VDO root were created.
  Neither mode automatically erases a partial layout.
- **Live `vdoformat` missing:** installation of the `vdo` package is needed as
  well as `dm_vdo` kernel support; seeing the module alone is insufficient.
- **Timezone error on server restart:** verify `tzdata` and
  `timedatectl list-timezones`; investigate the command's actual failure rather
  than assuming the package is absent.
- **Installer shell says “permission denied” for a downloaded script:** execute
  shell scripts with `bash script.sh`; downloads do not automatically get the
  executable bit. Use `python3 build-autoinstall.py` for the generator.
- **Temporary SSH host key changed after ISO restart:** live SSH host keys are
  regenerated. Verify the guest's MAC/IP against its Unraid definition before
  replacing the old known-host entry. The installed guest will have its own keys.
- **Installed target exists but boot fails:** use the ISO as rescue media. Do not
  rerun `create` or start a fresh install over it. Inspect target mounts and
  regenerate its initrd inside the mounted installed system.

## Space, expansion, and future templates

Monitor all three layers: guest `df -h /`, `sudo lvs -a` / `sudo vdostats
--human-readable`, and Unraid cache free space. VDO does not prevent the host
pool from filling. Keep a separate backup appropriate to the host's pool layout;
array parity does not protect files held only on a separate cache device.

To expand later, back up first, grow the stopped VM's raw disk in Unraid, grow
partition 3, run `pvresize`, then extend the **physical VDO pool**, the public
root LV, and finally XFS. Inspect actual device sizes at each step. Growing only
the virtual root does not add backing storage. Neither XFS nor the VDO pool is
intended to be shrunk by this procedure. A tested expansion command sequence
is still pending; do not improvise `lvextend -r` across the VDO stack.

Once the first VM passes installation, workload, and cold-boot checks, a clean
powered-off base image can make later VMs easier than repeating installation.
Treat that as a separate template step: omit Hermes data/secrets and Tailscale
authentication; give clones new MACs, hostnames, machine IDs, and SSH host keys.
Back up the clean image on the array and copy active guests to NVMe. Do not clone
the current live installer or publish a disk image in Git.

## Technical references

- [Ubuntu autoinstall reference](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html): preserved storage, interactive sections, packages, and late commands.
- [Curtin storage reference](https://curtin.readthedocs.io/en/latest/topics/storage.html): disk/partition/LVM/format/mount actions and preservation.
- [Linux dm-vdo documentation](https://docs.kernel.org/admin-guide/device-mapper/vdo.html): block deduplication and LZ4 compression.
- [LVM VDO manual](https://man7.org/linux/man-pages/man7/lvmvdo.7.html): logical versus physical sizes, metadata overhead, usage statistics, and pool expansion.
- [Dracut LVM module](https://github.com/dracut-ng/dracut-ng/blob/110/modules.d/70lvm/module-setup.sh): boot-time LVM support inspected for the Ubuntu 26.04 recipe.
