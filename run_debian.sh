# A sourcefile to launch Debian container within DebDroid
# This is not a launch command, this is required by the debdroid launch script
[ -f "${DEBDROID__DEBIAN_FS}/etc/hostname" ] && DEBDROID__DEBIAN_HOSTNAME="$(head -n 1 ${DEBDROID__DEBIAN_FS}/etc/hostname)" || DEBDROID__DEBIAN_HOSTNAME="termux_debian"
[ -f "${DEBDROID__DEBIAN_FS}/.proot.debdroid/userinfo.rc" ] && DEBDROID__DEBIAN_USER_INFO="$(head -n 1 ${DEBDROID__DEBIAN_FS}/.proot.debdroid/userinfo.rc)" || DEBDROID__DEBIAN_USER_INFO="root"

# Generate procfiles
gen_proc_files(){
# /proc/stat
cat > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fstat" <<- EOM
cpu  4058 0 3089 2779550 170 0 480 0 0 0
cpu0  4058 0 3089 2779550 170 0 480 0 0 0
intr 283344 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 844257
btime 1613040871
processes 1002
procs_running 1
procs_blocked 0
softirq 405867 0 111579 0 72119 7205 0 14982 113430 0 86552
EOM

# /proc/version
cat > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fversion" <<- EOM
Linux version 6.2.0-debdroid (termux@android) (gcc version 8.6.4 (GCC)) #1 SMP Tue Jan 01 12:00:00 UTC 2023
EOM

# /proc/vmstat
cat > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fvmstat" <<- EOM
nr_free_pages 713737
nr_zone_inactive_anon 2
nr_zone_active_anon 17697
nr_zone_inactive_file 2434
nr_zone_active_file 14878
nr_zone_unevictable 0
nr_zone_write_pending 17
nr_mlock 0
nr_page_table_pages 536
nr_kernel_stack 1748
nr_bounce 0
nr_free_cma 0
nr_inactive_anon 2
nr_active_anon 17697
nr_inactive_file 2434
nr_active_file 14878
nr_unevictable 0
nr_slab_reclaimable 3344
nr_slab_unreclaimable 2726
nr_isolated_anon 0
nr_isolated_file 0
workingset_refault 0
workingset_activate 0
workingset_nodereclaim 0
nr_anon_pages 17689
nr_mapped 8697
nr_file_pages 17325
nr_dirty 17
nr_writeback 0
nr_writeback_temp 0
nr_shmem 17
nr_shmem_hugepages 0
nr_shmem_pmdmapped 0
nr_anon_transparent_hugepages 7
nr_unstable 0
nr_vmscan_write 0
nr_vmscan_immediate_reclaim 0
nr_dirtied 914
nr_written 863
nr_dirty_threshold 142202
nr_dirty_background_threshold 71014
pgpgin 167360
pgpgout 4203156
pswpin 0
pswpout 0
pgalloc_dma 0
pgalloc_dma32 1308767
pgalloc_normal 0
pgalloc_movable 0
allocstall_dma 0
allocstall_dma32 0
allocstall_normal 0
allocstall_movable 0
pgskip_dma 0
pgskip_dma32 0
pgskip_normal 0
pgskip_movable 0
pgfree 2093445
pgactivate 30038
pgdeactivate 2
pglazyfree 0
pgfault 799732
pgmajfault 1198
pglazyfreed 0
pgrefill 0
pgsteal_kswapd 0
pgsteal_direct 0
pgscan_kswapd 0
pgscan_direct 0
pgscan_direct_throttle 0
pginodesteal 0
slabs_scanned 0
kswapd_inodesteal 0
kswapd_low_wmark_hit_quickly 0
kswapd_high_wmark_hit_quickly 0
pageoutrun 0
pgrotated 2
drop_pagecache 0
drop_slab 0
oom_kill 0
pgmigrate_success 66207
pgmigrate_fail 4061
compact_migrate_scanned 1452684
compact_free_scanned 54719159
compact_isolated 140803
compact_stall 0
compact_fail 0
compact_success 0
compact_daemon_wake 0
compact_daemon_migrate_scanned 0
compact_daemon_free_scanned 0
htlb_buddy_alloc_success 0
htlb_buddy_alloc_fail 0
unevictable_pgs_culled 0
unevictable_pgs_scanned 0
unevictable_pgs_rescued 0
unevictable_pgs_mlocked 0
unevictable_pgs_munlocked 0
unevictable_pgs_cleared 0
unevictable_pgs_stranded 0
thp_fault_alloc 383
thp_fault_fallback 0
thp_collapse_alloc 922
thp_collapse_alloc_failed 0
thp_file_alloc 0
thp_file_mapped 0
thp_split_page 0
thp_split_page_failed 0
thp_deferred_split_page 400
thp_split_pmd 21
thp_split_pud 0
thp_zero_page_alloc 0
thp_zero_page_alloc_failed 0
thp_swpout 0
thp_swpout_fallback 0
balloon_inflate 0
balloon_deflate 0
swap_ra 0
swap_ra_hit 0
EOM

# /proc/loadavg
cat > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/floadavg" <<- EOM
0.02 0.03 0.00 1/107 281
EOM

# /proc/uptime
cat > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fuptime" <<- EOM
9694.45 28998.24
EOM

# /proc/sys/kernel/cap_last_cap (needed for dbus)
echo 0 > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds/fcap_last_cap"
}

# Load procfiles
gen_proc_files

# Synchronize host environment (needed for executing programs)
mkdir "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binfmt" -p
cat > "${DEBDROID__DEBIAN_FS}/etc/profile.d/debdroid-corrosive.sh" <<- EOM
#!/usr/bin/env bash
# This file is regenerated everytime you launch the session
# To disable launching Termux commands to the Debian OS, echo the value 0 in /.proot.debdroid/binfmt/corrosive-session

if [ ! -e "/.proot.debdroid/.hushlogin" ]; then
echo "${GREEN}Welcome to Debian!"
echo ""
echo "To get started, grab apt-get and install your packages with ${YELLOW}apt install${GREEN} command"
echo ""
echo "You can add one or more users with the command ${YELLOW}addusers${GREEN} this command will setup not only the user account but also it sets up sudo access for second account"
echo "You can switch users by using ${YELLOW}su${GREEN} command"
echo ""
echo "To update/reconfigure your Debian system, a simple ${YELLOW}debdroid reconfigure${GREEN} to ensure your container isn't outdated"
echo ""
echo "All of your files are living outside the Termux's prefix directory, so a simple ${YELLOW}termux-reset${GREEN} command will not erase your Debian container${NOATTR}"
touch /.proot.debdroid/.hushlogin
fi

export GALLIUM_DRIVER=${GALLIUM_DRIVER:-llvmpipe}
export MOZ_FAKE_NO_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_CONTENT_SANDBOX=1
export PULSE_SERVER=${PULSE_SERVER:-127.0.0.1}

if [ "\$(head -n 1 /.proot.debdroid/binfmt/corrosive-session 2>/dev/null)" == "1" ]; then
export PATH=\${PATH}:/data/data/com.termux/files/usr/bin
export ANDROID_ART_ROOT=${ANDROID_ART_ROOT:-}
export ANDROID_DATA=${ANDROID_DATA:-}
export ANDROID_I18N_ROOT=${ANDROID_I18N_ROOT:-}
export ANDROID_ROOT=${ANDROID_ROOT:-}
export ANDROID_RUNTIME_ROOT=${ANDROID_RUNTIME_ROOT:-}
export ANDROID_TZDATA_ROOT=${ANDROID_TZDATA_ROOT:-}
export BOOTCLASSPATH=${BOOTCLASSPATH:-}
export DEX2OATBOOTCLASSPATH=${DEX2OATBOOTCLASSPATH:-}
export COLORTERM=${COLORTERM:-truecolor}
export EXTERNAL_STORAGE=${EXTERNAL_STORAGE:-}
export PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
export TMPDIR=/tmp
fi
EOM

# Fill /etc/hosts file if necessary and sync it with user-defined hostname
cat > "${DEBDROID__DEBIAN_FS}/etc/hosts" <<- EOM
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${DEBDROID__DEBIAN_HOSTNAME}.localdomain  ${DEBDROID__DEBIAN_HOSTNAME}
EOM

# Define kompat_source for overriding uname and compatibility with applications
kompat_source="\\$(uname -s)\\${DEBDROID__DEBIAN_HOSTNAME}\\6.2.0-debdroid\\#1 SMP Tue Jan 01 12:00:00 UTC 2023\\$(uname -m)\\localdomain\\-1\\"

############################################
# PRoot arguments
############################################

# Default entrypoint to launch Debian shell
# PRoot arguments are arranged right-to-left down-to-up order because of "set" positional argument placement accumulating arguments with "$@" reference which resets when set command is ran again without it
# The use of set to assign positional arguments and later use it has benefits, it can properly handle strings and word splitting without the use of eval
#
# If using variable concatenation, it doesn't properly handle quotes and word splitting.
# This was used in PRoot-Distro. Big help to properly re-write mountpoints configuration file to bind any files with spaces. Thank you @sylirre and Termux developers!
set -- "USER=root"
set -- "TERM=${TERM:-xterm-256color}" "$@"
set -- "PATH=/usr/local/bin:/usr/local/sbin:/usr/local/games:/usr/bin:/usr/sbin:/usr/games:/bin:/sbin" "$@"
set -- "LANG=C.UTF-8" "$@"
set -- "HOME=/root" "$@"
set -- "/usr/bin/env" "-i" "$@"

# Mounts file
source "${DEBDROID__DEBIAN_FS}/.proot.debdroid/mountpoints.sh"
for m in "${mount[@]}"; do
	set -- "--bind=${m}" "$@"
done

# Check for Android Version
case "$(getprop ro.build.version.release)" in
	5*|6*) ;;
	*)
	set -- "--sysvipc" "$@"
	set -- "--ashmem-memfd" "$@"
	;;
esac

set -- "--link2symlink" "$@"
set -- "--kill-on-exit" "$@"
set -- "--root-id" "$@"
set -- "-L" "$@"
set -- "-H" "$@"
set -- "-p" "$@"
set -- "-k" "${kompat_source}" "$@"
set -- "--cwd=/root" "$@"
set -- "--rootfs=${DEBDROID__DEBIAN_FS}" "$@"
