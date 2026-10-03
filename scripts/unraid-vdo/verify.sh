#!/usr/bin/env bash
# Read-only checks in the installed VM. Success does not replace a cold boot.
set -euo pipefail
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ $EUID == 0 ]] || fail "Run with sudo in the installed VM"
[[ ! -f /cdrom/casper/install-sources.yaml ]] || fail "Still running the installer ISO"
[[ $(findmnt -n -o FSTYPE /) == xfs ]] || fail "Root filesystem is not XFS"
[[ $(readlink -f "$(findmnt -n -o SOURCE /)") == $(readlink -f /dev/vg0/root) ]] || fail "Root is not vg0/root"
[[ $(lvs --noheadings -o segtype vg0/root | xargs) == vdo ]] || fail "Root LV is not VDO"
[[ $(findmnt -n -o FSTYPE /boot) == ext4 ]] || fail "Missing separate ext4 /boot"
[[ $(findmnt -n -o FSTYPE /boot/efi) == vfat ]] || fail "Missing EFI filesystem"
xfs_info / | grep -q 'reflink=1' || fail "XFS reflinks are disabled"
modinfo dm_vdo >/dev/null
initrd="/boot/initrd.img-$(uname -r)"
[[ -f $initrd ]] || fail "Missing initrd for running kernel"
listing=$(lsinitrd "$initrd")
grep -Eq 'dm[-_]vdo\.ko' <<< "$listing" || fail "Initrd lacks the VDO driver"
grep -Eq '(usr/)?sbin/lvm([[:space:]]|$)' <<< "$listing" || fail "Initrd lacks LVM"
root_uuid=$(blkid -s UUID -o value /dev/vg0/root)
grep -Eq "^[[:space:]]*linux[[:space:]].*root=(/dev/mapper/vg0-root|/dev/vg0/root|UUID=${root_uuid})([[:space:]]|$)" /boot/grub/grub.cfg || fail "Missing matching GRUB root argument"
systemctl is-enabled fstrim.timer >/dev/null || fail "Periodic trim is disabled"
lvs -a -o lv_name,segtype,lv_size,pool_lv,data_percent
vdostats --human-readable
df -h / /boot /boot/efi
echo "Installed-system checks passed. Confirm a cold boot with the ISO detached before migrating workloads."
