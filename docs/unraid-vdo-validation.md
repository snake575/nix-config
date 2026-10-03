# First-machine validation: nomad-lab

This is the evidence record for the first attempt. Use the
[reusable procedure](unraid-vdo-vm.md) for new VMs; do not copy these resource
allocations or machine identities without considering the new workload.

## Observed environment

| Item | First-machine value |
| --- | --- |
| Guest name | `nomad-lab` |
| CPU / RAM | 4 vCPUs / 8 GB |
| Firmware / disk bus | OVMF UEFI / VirtIO |
| Guest disk | 80 GiB raw virtual disk |
| Ubuntu ISO | Server 26.04.1 amd64 |
| Live kernel | `7.0.0-30-generic` |
| Installer | Subiquity 26.04.1, snap revision 7403 |
| VDO tools | 8.3.1.1 |
| Root filesystem | XFS, reflinks enabled |

The host's storage screenshot showed a 256 GB XFS NVMe cache pool with 106 GB
used and 150 GB free before further work. It also held appdata and other VMs.
A proposed 30–40 GB operating allowance was specific to that shared small pool;
recheck actual capacity rather than reusing the snapshot for future guests.

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

## Remaining acceptance checks

- [ ] Finish installing Ubuntu with the preserved VDO root.
- [ ] Confirm installed `update-grub` succeeds and the root argument matches.
- [ ] Confirm the installed initrd contains LVM and `dm_vdo`.
- [ ] Boot from the guest disk with the ISO detached and run `verify.sh`.
- [ ] Shut down cleanly and confirm a cold boot.
- [ ] Exercise a representative project/install/worktree workload.
- [ ] Run the reusable bootstrap through another fresh VM installation.
- [ ] Validate the documented expansion sequence before adding exact commands.

Until these are complete, the runbook remains a draft recipe. Do not prepare a
golden image or migrate important data based only on the observations above.
