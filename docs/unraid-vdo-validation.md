# First-machine validation: nomad-lab

This is the evidence record for the first attempt. Use the
[reusable procedure](unraid-vdo-vm.md) for new VMs; do not copy these resource
allocations or machine identities without considering the new workload.

## Observed environment

| Item | First-machine value |
| --- | --- |
| Guest name | `nomad-lab` |
| CPU / RAM | 4 vCPUs / 8 GB initially; successful installation at 4 GB |
| Firmware / disk bus | OVMF UEFI / VirtIO |
| Guest disk | 80 GiB raw virtual disk |
| Ubuntu ISO | Server 26.04.1 amd64 |
| Live kernel | `7.0.0-30-generic` |
| Installed kernels | `7.0.0-30-generic`, `7.0.0-38-generic` |
| Installer | Subiquity 26.04.1, snap revision 7403 |
| VDO tools | 8.3.1.1 |
| Root filesystem | XFS, reflinks enabled |

The host's storage screenshot showed a 256 GB XFS NVMe cache pool with 106 GB
used and 150 GB free before further work. It also held appdata and other VMs.
A proposed 30–40 GB operating allowance was specific to that shared small pool;
recheck actual capacity rather than reusing the snapshot for future guests.

The later RAM screenshot showed 16 GiB installed but only 14 GiB usable, 98%
usage, and 294 MiB free (VMs 11.3 GiB, system 1.79 GiB, Docker 260 MiB).
Stopping a Home Assistant VM configured for 4 GB reduced measured usage to 82%
and left 2.48 GiB free. Its actual memory release was less than its configured
limit. The planned allocations of 8 GB for this guest, 4 GB for the existing
Ubuntu guest, and 4 GB for Home Assistant cannot all be guaranteed on 14 GiB
usable RAM alongside the host. Rebalance allocations before running all three
under load. Home Assistant is temporarily stopped; its permanent allocation
has not been changed or validated.

## Completed observations

- Created 1 GiB EFI, 2 GiB ext4 `/boot`, and the remaining ~77 GiB LVM partition.
- Created a 72 GiB physical VDO pool with compression and deduplication enabled.
- Omitting a virtual-size override let LVM select ~67.87 GiB for the shared root.
- Approximately 5 GiB remained unallocated in the volume group.
- XFS creation and mounting succeeded.
- VDO activated again after restarting the ISO environment.
- The installer accepted a preserved storage plan for XFS on the public VDO LV.
- Inspected Ubuntu GRUB and Dracut support for this layout. Root probing errors
  are tolerated by the inspected GRUB scripts; a separate `/boot` supplies the
  kernel and initrd. This is source inspection, not proof of successful boot.
- Completed installation, security updates, and all late commands at 4 GB RAM.
- Verified both installed initrds contain the VDO driver and LVM executable.
- Verified GRUB uses `root=/dev/mapper/vg0-root`, EFI bootloader files exist,
  periodic trim is enabled, and the target package audit is clean.
- Booted the installed system after a clean power-off and reconnected as
  `snake575` using the GitHub-imported SSH key. Kernel `7.0.0-38-generic` ran
  with XFS on the VDO root, SSH active, and no failed systemd units.
- The user ran `verify.sh` with sudo in the installed system; every check passed.
  Its snapshot showed 4.7 GiB used and 64 GiB available in the root filesystem,
  and the 72 GiB VDO pool reported 6.7 GiB used, 65.3 GiB available, and 42%
  space saving. These are guest/VDO measurements, not host NVMe allocation.
- The ISO was still attached (but not mounted as the live system), and PCI
  inspection still showed QXL. A boot with the ISO detached remains pending.

## Issues encountered

- The live environment had no `ubuntu` account; temporary installer SSH access
  used the root account instead.
- Live VDO utilities required installing the `vdo` package even though the
  kernel already supplied `dm_vdo`.
- QXL display-driver lockups appeared in kernel logs. Later SSH loss also
  coincided with the user stopping the VM in Unraid; an unreachable VM did not
  establish a VDO failure. QXL was still reported after the subsequent restart.
- `timedatectl list-timezones` failed during one server restart, then worked
  after the ISO restart with tzdata already present. The cause was not proven
  to be missing timezone data.
- Restarting the live ISO regenerated its SSH host keys and removed temporary
  packages and installer configuration; the disk storage remained intact.
- After entering identity and SSH settings, the user observed another VM stop
  and no successful disk boot. The host's severe RAM pressure makes a host OOM
  kill plausible, but host logs have not confirmed the cause. Read-only disk
  inspection found partial OS extraction and no complete boot configuration.
  The retries preserved the existing VDO storage. Offline checks found no XFS
  errors; `/boot` journal recovery and clearing EFI's dirty bit succeeded.
- The console client retained journal subscriptions for the previous server
  process after the server restarted. It showed old configuration events while
  security updates continued over SSH. Restarting only the console client
  refreshed progress without interrupting installation. The reusable helper
  now restarts both services when loading a new configuration.

## Remaining acceptance checks

- [ ] Confirm sustainable host RAM allocations and investigate the unexpected stop.
- [x] Inspect the interrupted install's existing root and boot files without formatting.
- [x] Finish installing Ubuntu with the preserved VDO root.
- [x] Confirm installed `update-grub` succeeds and the root argument matches.
- [x] Confirm the installed initrd contains LVM and `dm_vdo`.
- [x] Boot from the guest disk and run `verify.sh` with sudo.
- [x] Shut down cleanly and confirm a cold boot from the guest disk.
- [ ] Detach the ISO and confirm another disk boot.
- [ ] Exercise a representative project/install/worktree workload.
- [ ] Run the reusable bootstrap through another fresh VM installation.
- [ ] Validate the documented expansion sequence before adding exact commands.

Until these are complete, the runbook remains a draft recipe. Do not prepare a
golden image or migrate important data based only on the observations above.
