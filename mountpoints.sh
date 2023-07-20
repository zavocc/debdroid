### Mountpoints for DebDroid
##########################################################
# To mount your custom mounts, the syntax should follows:
# prootargs+=" --bind source:destination"
# or
# prootargs+=" --bind source"
#
# Android Partitions should not be disabled if interoperability is enabled
# You can disable it by typing
# echo 0 > /var/debdroid/binfmt/corrosive-session
##########################################################

##########################################################
# Android Mountpoints (Needed for executing host programs)
# Check each Android directories if present
for android_core_dirs in /apex /data /linkerconfig/ld.config.txt /odm /oem \
	/product /system /system_ext /vendor /property_contexts /plat_property_contexts /storage; do
		if [ -e "${android_core_dirs}" ]; then
			prootargs+=" --bind=${android_core_partitions}"
		fi
done

prootargs+=" --bind=/storage/emulated/0:/sdcard"
##########################################################

##########################################################
# Mountpoints for faking /proc entries (Comment it if you have permissive mode)
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/var/debdroid/binds/fstat:/proc/stat"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/var/debdroid/binds/fversion:/proc/version"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/var/debdroid/binds/floadavg:/proc/loadavg"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/var/debdroid/binds/fuptime:/proc/uptime"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/var/debdroid/binds/fvmstat:/proc/vmstat"
prootargs+=" --bind=${DEBDROID__DEBIAN_FS}/var/debdroid/binds/fcap_last_cap:/proc/sys/kernel/cap_last_cap"
##########################################################

##########################################################
# Needed for some programs to utilize file descriptors (/dev/std*)
prootargs+=" --bind=/proc/self/fd/0:/dev/stdin"
prootargs+=" --bind=/proc/self/fd/1:/dev/stdout"
prootargs+=" --bind=/proc/self/fd/2:/dev/stderr"
##########################################################

##########################################################
# Miscellanious Mountpoints
prootargs+=" --bind=/dev/urandom:/dev/random"
prootargs+=" --bind=${PREFIX:-/data/data/com.termux/files/usr}/tmp:/tmp"
prootargs+=" --bind=${HOME:-/data/data/com.termux/files/home}:/home/termux_home"
##########################################################