#!/bin/sh
# combustion: network

## utils
zypper --non-interactive install man

## PAM
zypper --non-interactive remove sudo

## swapfile

truncate -s 0 /swapfile
chattr +C /swapfile
fallocate -l 2G /swapfile
chmod 0600 /swapfile
mkswap -U clear /swapfile
swapon /swapfile
sed -i '$a/swapfile	none	swap	sw' /etc/fstab

## dracut fido2

echo "add_dracutmodules+=\" fido2 \"" | sudo tee /etc/dracut.conf.d/fido2.conf
add_dracutmodules+=" fido2 "

sed -i '/cr_root/ s/$/,fido2-device=auto/' /etc/crypttab

## hardened malloc
zypper --non-interactive install git glibc clang make
git clone https://github.com/GrapheneOS/hardened_malloc
export CC=clang
export CXX=clang++
cd hardened_malloc/
make
mv out/libhardened_malloc.so /usr/lib/libhardened_malloc.so
cat << EOF > /etc/ld.so.preload
/usr/lib/libhardened_malloc.so
EOF

## sysctl
cat << EOF > /etc/sysctl.d/hardening.conf
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
kernel.sysrq = 4
kernel.unprivileged_userns_clone = 0
kernel.perf_event_paranoid = 3
kernel.kexec_load_disabled = 1
kernel.randomize_va_space = 2
kernel.yama.ptrace_scope = 3
user.max_user_namespaces = 0
dev.tty.ldisc_autoload = 0
dev.tty.legacy_tiocsti = 0
vm.unprivileged_userfaultfd = 0
vm.mmap_rnd_bits = 32
vm.mmap_rnd_compat_bits = 16
vm.max_map_count = 1048576
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0
net.core.bpf_jit_harden = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_sack = 0
net.ipv4.tcp_dsack = 0
net.ipv4.tcp_fack = 0
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_syncookies = 1
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
EOF

## kernel cmdline 

sed -i '/options/ s/$/ security=selinux selinux=1 enforcing=1 hardened_usercopy=1 init_on_alloc=1 init_on_free=1 randomize_kstack_offset=on page_alloc.shuffle=1 slab_nomerge pti=on iommu.passthrough=0 iommu.strict=1/' /boot/efi/loader/entries/*

dracut -f