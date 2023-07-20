#!/data/data/com.termux/files/usr/bin/env bash
#############################################
# DebDroid 4.0 2020, 2021-2022, 2023
# This script will allow you to install Debian on your Device with just a few taps
# This script is also portable, all links, repos will be read on a single file
# So to make it easier to fork and to create debdroid-based projects
#
# Also you will need to comply the GPLv3 license as some components use that
# All Rights Reserved (2020, 2021-2022, 2023) made by @zavocc
#############################################
set -e -u
# Default Debian Location
# This will be placed outside the 'usr' directory when 'termux-reset' is invoked, then all the preferences will be saved
DEBDROID__DEBIAN_FS="/data/data/com.termux/files/debian"

# URL Link
# Used for portability and can be used for branch testing
DEBDROID__URL_REPO="https://raw.githubusercontent.com/zavocc/debdroid/2.0"

# Tempdir
# Used to place temporary files and all downloaded cache will be stored and will be updated once it flushed
DEBDROID__TEMPDIR="${TMPDIR}/.debdroid-cachedir"

# Script Version
DEBDROID__SCRIPT_VER="4.0"

# Colored Environment Variables
if [ -e "$(command -v tput)" ]; then
	RED="$(tput setaf 1)$(tput bold)"
	GREEN="$(tput setaf 2)$(tput bold)"
	YELLOW="$(tput setaf 3)$(tput bold)"
	NOATTR="$(tput sgr0)"
else
	RED=""
	GREEN=""
	YELLOW=""
	NOATTR=""
fi


# Don't run as root
if [ "$(id -u)" == 0 ]; then
	echo "${RED}E: running this script is discouraged and therefore not being used by root user${NOATTR}"
	exit 1
fi

# Create Temporary Directory (We don't use mktemp as to be used for update delay caching)
mkdir -p "${DEBDROID__TEMPDIR}"

check_update(){
	if curl https://google.com --fail --silent --insecure >/dev/null; then
		if [ ! "$(curl --silent --fail --location ${DEBDROID__URL_REPO}/version.txt)" == "${DEBDROID__SCRIPT_VER}" ]; then
			echo "${YELLOW}I: A New Version of this script is available, you may install a new version over this script${NOATTR}"
			touch "${DEBDROID__TEMPDIR}/update-cache-lock"
		fi
	else
		echo "${YELLOW}N: Cannot Perform Update: Network is down. Skipping....."
	fi
}

# Check for Updates but check if network connection is present
if [ ! -e "${DEBDROID__TEMPDIR}/update-cache-lock" ]; then
	check_update
fi

# Function to handle signal trap
sigtrap(){
	echo "${RED}W: The Script generated error code 127, Quitting as requested!${NOATTR}"
	exit 127
}

trap 'sigtrap' HUP INT KILL QUIT TERM

# Check if dependencies are installed
if ! [ -e "$(command -v proot)" ] && [ -e "$(command -v curl)" ]; then
	echo "${GREEN}I: Installing ${YELLOW}proot, curl${GREEN} if necessary${NOATTR}"
	pkg update
	pkg install proot curl -yy
fi

# Function to show help
show_help(){
	echo "${GREEN}DebDroid: Debian Installer for Android OS"
	echo ""
	echo "This Script will allow you to install Debian on your Device like Chromebooks, Phone, Tablets and TV with Termux in just a few keystrokes"
	echo ""
	echo "Here are the commands to operate within the debian container:"
	echo "${YELLOW} install"
	echo " purge"
	echo " reconfigure"
	echo " launch"
	echo " backup | export"
	echo " restore | import"
	echo ""
	echo "${GREEN}You can install Debian Stable by typing ${YELLOW}debdroid install${GREEN} or ${YELLOW}debdroid install stable${GREEN}"
	echo "You can list the recognized releases with ${YELLOW}debdroid install list${GREEN} command"
	echo ""
	echo "To perform reconfiguration (Interrupted Install, Updating the container) you may enter ${YELLOW}debdroid reconfigure${GREEN}"
	echo ""
	echo "To launch your debian container, you may type ${YELLOW}debdroid launch${GREEN} or ${YELLOW}debdroid launch-asroot${GREEN}"
	echo "See ${YELLOW}debdroid launch --help${GREEN} for details"
	echo ""
	echo "You can customize your Debian Needs with command ${YELLOW}debianize${GREEN}. This will allow you to install your desired workstation packages automatically in just a few keystrokes"
	echo ""
	echo "To learn more about operating Debian system, see the Debian Wiki ${YELLOW}https://wiki.debian.org${GREEN} and ${YELLOW}https://wiki.debian.org/DontBreakDebian${NOATTR}"
}

# Function to enter rootfs
run_proot_cmd(){
	unset LD_PRELOAD
	proot --link2symlink --kill-on-exit \
		-0 -p -L -H --kernel-release="6.2.0-debdroid" \
		--rootfs="${DEBDROID__DEBIAN_FS}" \
		--bind="/dev" \
		--bind="/proc" \
		--bind="/sys" \
		--bind="${DEBDROID__DEBIAN_FS}/run/shm:/dev/shm" \
		--cwd=/root \
		/usr/bin/env -i \
			PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin \
			TERM=${TERM:-xterm-256color} \
			HOME=/root \
			USER=root \
			LANG=C.UTF-8 \
			"$@"
}

# Function to reconfigure debian
perform_configuration(){
	if [ ! -e "${DEBDROID__DEBIAN_FS}/usr/bin/apt" ]; then
		echo "${RED}E: The Debian container is invalid, Aborting!!!${NOATTR}" >&2
		exit 1
	fi
	printf "\e]2;DebDroid - Configuring the Debian container...\a"
	curl --silent --fail --location --output "${DEBDROID__DEBIAN_FS}/var/debdroid/debian_config.sh" "${DEBDROID__URL_REPO}/debian_config.sh"
	chmod 755 "${DEBDROID__DEBIAN_FS}/var/debdroid/debian_config.sh"
	# Add Proper /run/shm binding
	mkdir -p "${DEBDROID__DEBIAN_FS}/run/shm"

	# Setup Android Groups if necessary
	if [ ! -e "${DEBDROID__DEBIAN_FS}/var/debdroid/.group-setupdone" ]; then
	
		# Imported code from proot-distro
		chmod u+rw "${DEBDROID__DEBIAN_FS}/etc/passwd" \
			"${DEBDROID__DEBIAN_FS}/etc/shadow" \
			"${DEBDROID__DEBIAN_FS}/etc/group" \
			"${DEBDROID__DEBIAN_FS}/etc/gshadow" >/dev/null 2>&1 || true
		echo "aid_$(id -un):x:$(id -u):$(id -g):Termux:/:/sbin/nologin" >> \
			"${DEBDROID__DEBIAN_FS}/etc/passwd"
		echo "aid_$(id -un):*:18446:0:99999:7:::" >> \
			"${DEBDROID__DEBIAN_FS}/etc/shadow"
		local group_name group_id
		while read -r group_name group_id; do
			echo "aid_${group_name}:x:${group_id}:root,aid_$(id -un)" \
				>> "${DEBDROID__DEBIAN_FS}/etc/group"
			if [ -f "${DEBDROID__DEBIAN_FS}/etc/gshadow" ]; then
				echo "aid_${group_name}:*::root,aid_$(id -un)" \
					>> "${DEBDROID__DEBIAN_FS}/etc/gshadow"
			fi
		done < <(paste <(id -Gn | tr ' ' '\n') <(id -G | tr ' ' '\n'))

		# Finish adding groups
		touch "${DEBDROID__DEBIAN_FS}/var/debdroid/.group-setupdone"
	fi

	# Run Configuration Step
	run_proot_cmd "/var/debdroid/debian_config.sh"
}

# Function to install debian
install_debian(){
	local curl_download_link
	local debian_name
	local debian_suite
	local thirtytwobit

	while [ $# -ge 1 ]; do
		case "$1" in
			--suite)
				if [ $# -ge 2 ]; then
					debian_suite="$2"
					shift 2
				else
					shift 1
				fi
				;;
			--32)
				thirtytwobit=true
				shift 1
				;;
			--list)
				echo "${GREEN}Recognized Debian Releases:${YELLOW}"
				echo "oldoldstable/buster *, oldstable/bullseye, stable/bookworm, trixie, testing, unstable/sid"
				echo ""
				echo "${GREEN}If the releases marked with * then it is EOL'd by the official Debian support lifecycle, yet still supported under DebDroid${NOATTR}"
				return 0
				;;
			-h|--help)
				echo "${GREEN}Installs debian"
				echo ""
				echo "The basic syntax follows as:"
				echo "${YELLOW} debdroid install${GREEN}"
				echo ""
				echo "To install Debian other than stable, specify a suite (use --list argument to list possible suites)"
				echo "${YELLOW} debdroid install --suite [suite]${GREEN}"
				echo ""
				echo "To install Debian on 32-bit mode, add --32 argument"
				echo "${YELLOW} debdroid install --32${GREEN}"
				echo "${YELLOW} debdroid install --32 --suite [suite]${GREEN}"
				echo ""
				echo "To learn more about Debian, see the Debian Wiki ${YELLOW}https://wiki.debian.org${GREEN} and ${YELLOW}https://wiki.debian.org/DontBreakDebian${NOATTR}"
				return 0
				;;
			*)
				echo "${RED}E: Invalid option $1, run ${YELLOW}debdroid install --help${RED} to show supported options, or run without arguments${NOATTR}" >&2
				return 1
				;;
		esac
	done

	# Check if the rootfs exists
	if [ -e "${DEBDROID__DEBIAN_FS}/usr/bin/apt" ]; then
		echo "${RED}E: The Debian container is installed, perhaps you should be using ${YELLOW}debdroid reconfigure${RED}?${NOATTR}" >&2
		exit 1
	fi

	echo "${GREEN}I: Retrieving download Links needed for installation${NOATTR}"
	case "${debian_suite:-stable}" in
		sid|unstable|debian-sid|debian-unstable)
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/sid)
			;;
		testing|debian-testing)
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/testing)
			;;
		trixie|debian-trixie)
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/trixie)
			;;
		bookworm|debian-bookworm|stable|debian-stable)
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/bookworm)
			;;
		bullseye|debian-bullseye|oldstable|debian-oldstable)
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/bullseye)
			;;
		buster|debian-buster|oldoldstable|debian-oldoldstable)
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/buster)
			;;
		*)
			echo "${YELLOW}I: Unknown suite was requested, choosing stable${NOATTR}"
			source <(curl -sSL ${DEBDROID__URL_REPO}/suite/dlmirrors/bookworm)
			;;
	esac

	printf "\e]2;DebDroid - Installing the Debian container...\a"
	echo "${GREEN}I: The following distribution was requested: ${YELLOW}${debian_name}${NOATTR}"

	echo "${GREEN}I: Downloading the image file${NOATTR}"
	curl --output "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz.part" --location --fail "${curl_download_link}"
	if [ -e "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz.part" ]; then
		mv "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz.part" "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz"
	else
		echo "${RED}E: An Error has occured during the installation: no such file or directory, please try again${NOATTR}" >&2
		return 1
	fi

	echo "${GREEN}I: Extracting the image file${NOATTR}"
	printf "\e]2;DebDroid - Extracting the Image file...\a"
	mkdir -p "${DEBDROID__DEBIAN_FS}"
	proot --link2symlink -0 tar --preserve-permissions --delay-directory-restore --warning=no-unknown-keyword -xf "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz" --exclude dev -C "${DEBDROID__DEBIAN_FS}" ||:

	echo "${GREEN}I: Configuring the base system, this may take some time${NOATTR}"
	mkdir "${DEBDROID__DEBIAN_FS}/var/debdroid/binds" -p
	echo "${debian_name}" > "${DEBDROID__DEBIAN_FS}/etc/debian_chroot"
	if perform_configuration; then
		echo "${GREEN}I: The Debian container Installed Successfully, you can run it by typing ${YELLOW}debdroid launch${NOATTR}"
		return 0
	else
		echo "${RED}W: The Debian container isn't successfully installed, should this happen? you can run the command ${YELLOW}debdroid reconfigure${GREEN} if necessary${NOATTR}"
		return 1
	fi
}

# Function to Delete Debian
uninstall_debian(){
	local userinput
	local no_chmod

	read -p "${RED}N: Do you want to delete the Debian container? [y/N] ${NOATTR}" userinput

	if [ ! -e "${DEBDROID__DEBIAN_FS}" ]; then
		echo "${YELLOW}I: Debian container isn't installed, Continuing Anyway...${NOATTR}"
		no_chmod=y
	fi
	
	case "${userinput}" in
		Y*|y*)
			printf "\e]2;DebDroid - Uninstalling the Debian container...\a"
			echo "${YELLOW}I: Deleting the container (debian)${NOATTR}"
			if [ ! "${no_chmod:-}" == "y" ]; then
				chmod 777 "${DEBDROID__DEBIAN_FS}" -R
			fi
			
			rm -rf "${DEBDROID__DEBIAN_FS}"
			if [ ! -e "${DEBDROID__DEBIAN_FS}" ]; then
				echo "${GREEN}I: The Debian container Successfully Deleted${NOATTR}"
				exit 0
			else
				echo "${RED}E: The Debian container wasn't deleted successfully${NOATTR}" >&2
				exit 1
			fi
			;;
		N*|n*)
			echo "${GREEN}N: Aborting....${NOATTR}"
			exit 0
			;;
		*)
			echo "${GREEN}N: Aborting....${NOATTR}"
			exit 0
			;;
	esac
}

# Function to run Debian container (Actually, this is just a wrapper to make it portable)
launch_debian(){
	local extcmd
	local prootargs
	local kompat_source
	local DEBDROID__DEBIAN_HOSTNAME
	local DEBDROID__DEBIAN_USER_INFO
	local DEBDROID__DEBIAN_MOUNTPOINTS_INFO

	if [ ! -e "${DEBDROID__DEBIAN_FS}/var/debdroid/run_debian" ]; then
		echo "${RED}E: The Debian container isn't Installed, if you already installed it but seeing this message, try running ${YELLOW}debdroid reconfigure${NOATTR}" >&2
		exit 1
	fi

	 while [ $# -ge 1 ]; do
		case "$1" in
			--)
				shift 1;
				break;
				;;
			--asroot)
				rootmode=true;
				shift 1;
				;;
			-h|--help)
				echo "${GREEN}This command will launch Debian System as regular user"
				echo ""
				echo "The basic syntax follows as:"
				echo "${YELLOW} debdroid launch${GREEN}"
				echo ""
				echo "To run commands other than shell, you can specify external command by doing:"
				echo "${YELLOW} debdroid launch -- [command]${GREEN}"
				echo ""
				echo "To learn more about operating Debian system, see the Debian Wiki ${YELLOW}https://wiki.debian.org${GREEN} and ${YELLOW}https://wiki.debian.org/DontBreakDebian${NOATTR}"
				exit;
				;;
			*)
				echo "${RED}E: Invalid option... quitting${NOATTR}" >&2
				return 1;
				;;
		esac
	done

	# Check for an ongoing setup
	if [ -e "${DEBDROID__DEBIAN_FS}/.setup_has_not_done" ]; then
		echo "${RED}N: An ongoing setup is running, please finish the configuration first before continuing${NOATTR}"
		exit 1
	fi

	# Source the file
	source "${DEBDROID__DEBIAN_FS}/var/debdroid/run_debian"

	# Define External Command
	extcmd="$@"

	# Launch PRoot
	if [ "${rootmode:-}" == true ]; then
		DEBDROID__DEBIAN_USER_INFO="root"
	fi

	if [ ! -z "${extcmd}" ]; then
		proot -k "${kompat_source}" ${prootargs} su -l "${DEBDROID__DEBIAN_USER_INFO}" -c "${extcmd}"
	else
		proot -k "${kompat_source}" ${prootargs} su -l "${DEBDROID__DEBIAN_USER_INFO}"
	fi
}


# Function to Backup the container
backup_debian_container(){
	local args

	if [ ! -e "${DEBDROID__DEBIAN_FS}/var/debdroid/run_debian" ]; then
		echo "${RED}E: Cannot Backup the Debian container: The Debian container isn't Installed${NOATTR}" >&2
		exit 1
	fi

	args="$@"

	if [ -z "${args}" ]; then
		echo "${RED}E: Please specify a filename to output the tarball${NOATTR}" >&2
		exit 1
	fi

	echo "${GREEN}I: The Tarball will be saved in $(realpath -m ${args})${NOATTR}"
	echo "${YELLOW}I: Backing up the container... this may take some time${NOATTR}"
	printf "\e]2;DebDroid - Backing up Debian container...\a"
	if tar --preserve-permissions -zcf "${args}" -C "${DEBDROID__DEBIAN_FS}" ./; then
		echo "${GREEN}I: The container successfully exported${NOATTR}"
		exit 0
	else
		echo "${RED}I: The container isn't successfully exported${NOATTR}"
		exit 1
	fi
}

# Function to Restore the container
restore_debian_container(){
	local args
	local userinput

	args="$@"

	if [ -z "${args}" ]; then
		echo "${RED}E: Please specify a tarball for restoring the container${NOATTR}" >&2
		exit 1
	fi
	
	# Check if the tarball exists
	if [ ! -e "$(realpath -m ${args})" ]; then
		echo "${RED}E: The Tarball that you're trying to import dosen't exist${NOATTR}" >&2
		exit 1
	fi
	
	# User Input
		read -p "${GREEN}I: Do you want to restore the container? all of the existing state will be lost [y/N]? ${NOATTR}" userinput
			case "${userinput}" in
				Y*|y*) ;;
				N*|n*)
					echo "${RED}I: Aborting...${NOATTR}"
					exit 1
					;;
				*)
					echo "${RED}I: Aborting...${NOATTR}"
					exit 1
					;;
			esac
	
	echo "${YELLOW}I: Restoring the container...${NOATTR}"
	printf "\e]2;DebDroid - Restoring Debian container...\a"
	mkdir -p "${DEBDRROID__DEBIAN_FS}"
	if tar --recursive-unlink --delay-directory-restore --preserve-permissions -zxf "$(realpath -m ${args})" -C "${DEBDRROID__DEBIAN_FS}"; then
		echo "${GREEN}I: The container successfully imported${NOATTR}"
		exit 0
	else
		echo "${RED}I: The container isn't successfully imported${NOATTR}"
		exit 1
	fi
}

# shift chops off first arguments
if [ $# -ge 1 ]; then
	case "$1" in
		install)
			shift 1; install_debian "$@"
			;;
		uninstall|purge)
			shift 1; uninstall_debian "$@"
			;;
		reconfigure|configure)
			shift 1;
			if perform_configuration; then
				echo "${GREEN}I: Done Configuring the Debian container${NOATTR}"
				exit 0
			else
				echo "${RED}W: An error has occured during the reconfiguration${NOATTR}"
				exit 1
			fi
			;;
		launch|login)
			shift 1; launch_debian "$@"
			;;
		backup|export)
			shift 1; backup_debian_container "$@"
			;;
		restore|import)
			shift 1; restore_debian_container "$@"
			;;
		help|show-help|h)
			shift 1; show_help
			;;
		*)
			echo "${RED}Unknown Option: $1${NOATTR}"
			show_help
			;;
	esac
else
	show_help
	exit
fi
