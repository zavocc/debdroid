#!/data/data/com.termux/files/usr/bin/bash
# A Sourcefile to launch debian container within DebDroid
# This is not a launch command, this is required by the debdroid launch script
DEBIAN_FS="/data/data/com.termux/files/debian"
DEBIAN_HOSTNAME="/data/data/com.termux/files/debian/etc/hostname"
DEBIAN_USER_INFO="$(cat /data/data/com.termux/files/debian/var/debdroid/userinfo.rc)"
DEBIAN_MOUNTPOINTS_INFO="/data/data/com.termux/files/debian/var/debdroid/mountpoints.conf"

# Generate procfiles
gen_proc_files(){
# /proc/stat
cat > "${DEBIAN_FS}/var/debdroid/binds/fstat" <<- EOM
cpu  4058 0 3089 2779550 170 0 480 0 0 0
intr 283344 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 844257
btime 1613040871
processes 1002
procs_running 1
procs_blocked 0
softirq 405867 0 111579 0 72119 7205 0 14982 113430 0 86552
EOM
# /proc/version
cat > "${DEBIAN_FS}/var/debdroid/binds/fversion" <<- EOM
Linux version 5.4.0-debdroid (termux@android) (gcc version 8.6.4 (GCC)) #1 SMP Tue Jun 23 12:58:10 UTC 2020
EOM
# /proc/vmstat
cat > "${DEBIAN_FS}/var/debdroid/binds/fvmstat" <<- EOM
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
cat > "${DEBIAN_FS}/var/debdroid/binds/floadavg" <<- EOM
0.02 0.03 0.00 1/107 281
EOM
cat > "${DEBIAN_FS}/var/debdroid/binds/fuptume" <<- EOM
9694.45 28998.24
EOM
}