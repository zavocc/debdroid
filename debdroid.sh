#!/data/data/com.termux/files/usr/bin/env bash
#############################################
# DebDroid 4.0 2020, 2021-2022, 2023
# This script will allow you to install Debian on your device with just a few taps
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# All Rights Reserved (2020, 2021-2022, 2023) made by @zavocc (also known as marcusz/WMCB Tech)
#############################################
set -e -u

# Unset LD_PRELOAD which causes to redirect Termux paths to standard FHS locations
unset LD_PRELOAD

# Default Debian Location
# This will be placed outside the 'usr' directory when 'termux-reset' is invoked, then all the preferences will be saved
DEBDROID__DEBIAN_FS="/data/data/com.termux/files/debian"

# URL Link
# Used for branch testing. To test, run a webserver with webserver directory root pointing to root of this directory
# Or curl file:/// URI
DEBDROID__URL_REPO="https://raw.githubusercontent.com/zavocc/debdroid/master"

# Tempdir
# Used to place temporary files and all downloaded cache will be stored and will be updated once it flushed
DEBDROID__TEMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.debdroid-cachedir"

# Script Version
DEBDROID__SCRIPT_VER="4.0"

# Colored Environment Variables
if [ -x "$(command -v tput)" ]; then
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

# Function to handle signal trap
sigtrap(){
	echo "${RED}E: The script encountered an unexpected error, quitting as requested!${NOATTR}" >&2
	exit 127
}

trap 'sigtrap' HUP INT KILL QUIT TERM

# Check if dependencies are installed
for deps in chmod curl head id ls mkdir mv paste proot rm tar tr; do
	if [ ! -x "$(command -v $deps)" ]; then
		echo "${RED}E: Command ${YELLOW}${deps}${RED} doesn't exist, please install it${NOATTR}." >&2
		exit 2
	fi
done

# Don't run as root
if [ "$(id -u)" == 0 ]; then
	echo "${RED}E: running this script is discouraged and therefore not being used by root user${NOATTR}" >&2
	exit 1
fi

# Create temporary directory (don't use mktemp as to be used for update delay caching)
mkdir -p "${DEBDROID__TEMPDIR}"

check_update(){
	if curl https://google.com --fail --silent --insecure >/dev/null; then
		if [ ! "$(curl --silent --fail --location --insecure ${DEBDROID__URL_REPO}/version.txt | head -n 1)" == "${DEBDROID__SCRIPT_VER}" ]; then
			echo "${YELLOW}I: A new version of this script is available, you may install a new version over this script${NOATTR}"
			: > "${DEBDROID__TEMPDIR}/.update-cache-lock"
		fi
	else
		echo "${YELLOW}N: Cannot perform update checking: Network is down. Skipping....."
	fi
}

# Check for Updates but check if network connection is present
if [ ! -e "${DEBDROID__TEMPDIR}/.update-cache-lock" ]; then
	check_update
fi


# Function to show help
show_help(){
	echo "${GREEN}DebDroid: Debian Installer for Android OS"
	echo ""
	echo "This script will allow you to install Debian on your Device like Chromebooks, Phones, Tablets and TV with Termux in just a few keystrokes"
	echo ""
	echo "Here are the commands to operate within the Debian container:"
	echo "${YELLOW} install [--suite] [--32]"
	echo " purge"
	echo " reconfigure | configure"
	echo " launch [--asroot] [--] [command]"
	echo " backup | export [filename]"
	echo " restore | import [filename]"
	echo ""
	echo "${GREEN}You can install Debian stable by typing ${YELLOW}debdroid install${GREEN} or testing one with ${YELLOW}debdroid install --suite testing${GREEN}"
	echo "You can list the recognized releases with ${YELLOW}debdroid install list${GREEN} command"
	echo ""
	echo "To perform reconfiguration (Interrupted Install, Updating the container) you may enter ${YELLOW}debdroid reconfigure${GREEN}"
	echo ""
	echo "To launch your Debian container, you may type ${YELLOW}debdroid launch${GREEN} or ${YELLOW}debdroid launch --asroot${GREEN}"
	echo "See ${YELLOW}debdroid launch --help${GREEN} for details"
	echo ""
	echo "To learn more about operating Debian system, see the Debian Wiki ${YELLOW}https://wiki.debian.org${GREEN} and ${YELLOW}https://wiki.debian.org/DontBreakDebian${NOATTR}"
}

# Function to enter rootfs
run_proot_cmd(){
	proot --link2symlink --kill-on-exit \
		-0 -p -L -H --kernel-release="6.2.0-debdroid" \
		--rootfs="${DEBDROID__DEBIAN_FS}" \
		--bind="/dev" \
		--bind="/proc" \
		--bind="/sys" \
		--bind="${DEBDROID__DEBIAN_FS}/run/shm:/dev/shm" \
		--cwd=/root \
		/usr/bin/env -i \
			HOME=/root \
			LANG=C.UTF-8 \
			PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
			TERM="${TERM:-xterm-256color}" \
			USER=root \
			"$@"
}

# Function to reconfigure Debian
perform_configuration(){
	if [ ! -e "${DEBDROID__DEBIAN_FS}/usr/bin/apt" ]; then
		echo "${RED}E: The Debian container is invalid or wasn't installed. Aborting!!!${NOATTR}" >&2
		exit 1
	fi

	# Create runtime directory
	mkdir "${DEBDROID__DEBIAN_FS}/.proot.debdroid/binds" -p

	curl --silent --fail --location --output "${DEBDROID__DEBIAN_FS}/.proot.debdroid/debian_config.sh" "${DEBDROID__URL_REPO}/debian_config.sh"
	chmod 755 "${DEBDROID__DEBIAN_FS}/.proot.debdroid/debian_config.sh"

	# Add proper /run/shm binding
	mkdir -p "${DEBDROID__DEBIAN_FS}/run/shm"

	# Setup Android groups if necessary
	if [ ! -e "${DEBDROID__DEBIAN_FS}/.proot.debdroid/.group-setupdone" ]; then

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
		: > "${DEBDROID__DEBIAN_FS}/.proot.debdroid/.group-setupdone"
	fi

	# Run configuration step
	run_proot_cmd "/.proot.debdroid/debian_config.sh"
}

# Function to install Debian
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
					shift 1
				fi
				;;
			--32)
				thirtytwobit=true
				;;
			--list)
				echo "${GREEN}Recognized Debian Releases:${YELLOW}"
				echo "oldoldstable/buster *, oldstable/bullseye, stable/bookworm, trixie, testing, unstable/sid"
				echo ""
				echo "${GREEN}If the releases marked with * then it is EOL'd by the official Debian support lifecycle, yet still supported under DebDroid${NOATTR}"
				return 0
				;;
			-h|--help)
				echo "${GREEN}Installs Debian container"
				echo ""
				echo "The basic syntax follows as:"
				echo "${YELLOW} debdroid install${GREEN}"
				echo ""
				echo "To install Debian other than stable, specify a suite (use ${YELLOW}--list${GREEN} argument to list possible suites)"
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
		shift
	done

	# Check if the rootfs exists
	if [ ! -z "$(ls -A "${DEBDROID__DEBIAN_FS}" 2>/dev/null)" ]; then
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

	echo "${GREEN}I: The following distribution was requested: ${YELLOW}${debian_name}${NOATTR}"

	echo "${GREEN}I: Downloading the image file${NOATTR}"
	curl --output "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz.part" --location --fail "${curl_download_link}"
	if [ -e "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz.part" ]; then
		mv "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz.part" "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz"
	else
		echo "${RED}E: An error has occured during the installation: No such file or directory, please try again${NOATTR}" >&2
		return 1
	fi

	echo "${GREEN}I: Extracting the image file${NOATTR}"
	mkdir -p "${DEBDROID__DEBIAN_FS}"
	proot --link2symlink -0 tar --preserve-permissions --delay-directory-restore --warning=no-unknown-keyword -xf "${DEBDROID__TEMPDIR}/${debian_name}-rootfs.tar.xz" --exclude dev -C "${DEBDROID__DEBIAN_FS}" ||:

	echo "${GREEN}I: Configuring the base system, this may take some time${NOATTR}"
	echo "${debian_name}" > "${DEBDROID__DEBIAN_FS}/etc/debian_chroot"
	if perform_configuration; then
		echo "${GREEN}I: The Debian container installed Successfully, you can run it by typing ${YELLOW}debdroid launch${NOATTR}"
		return 0
	else
		echo "${RED}E: The Debian container isn't successfully installed, should this happen? You can run the command ${YELLOW}debdroid reconfigure${GREEN} if necessary${NOATTR}"
		return 1
	fi
}

# Function to delete Debian
uninstall_debian(){
	local no_chmod
	local userinput

	read -p "${RED}N: Do you want to delete the Debian container? [y/N] ${NOATTR}" userinput

	if [ ! -e "${DEBDROID__DEBIAN_FS}" ]; then
		echo "${YELLOW}I: Debian container isn't installed, continuing anyway...${NOATTR}"
		no_chmod=y
	fi

	case "${userinput}" in
		Y*|y*)
			echo "${YELLOW}I: Deleting the container${NOATTR}"
			if [ ! "${no_chmod:-}" == "y" ]; then
				chmod 777 "${DEBDROID__DEBIAN_FS}" -R
			fi

			if rm -rf "${DEBDROID__DEBIAN_FS}" >/dev/null 2>&1; then
				echo "${GREEN}I: The Debian container successfully deleted${NOATTR}"
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

# Function to run Debian container
launch_debian(){
	local -a extcmd
	local kompat_source
	local mount
	local prootargs
	local DEBDROID__DEBIAN_HOSTNAME
	local DEBDROID__DEBIAN_MOUNTPOINTS_INFO
	local DEBDROID__DEBIAN_USER_INFO

	if [ ! -e "${DEBDROID__DEBIAN_FS}/.proot.debdroid/run_debian" ]; then
		echo "${RED}E: The Debian container isn't installed, if you already installed it but seeing this message, try running ${YELLOW}debdroid reconfigure${NOATTR}" >&2
		exit 1
	fi

	 while [ $# -ge 1 ]; do
		case "$1" in
			--)
				shift 1
				break
				;;
			--asroot)
				rootmode=true
				;;
			-h|--help)
				echo "${GREEN}This command will launch Debian system"
				echo ""
				echo "The basic syntax follows as:"
				echo "${YELLOW} debdroid launch${GREEN}"
				echo ""
				echo "To run commands other than shell, you can specify external command by doing:"
				echo "${YELLOW} debdroid launch -- [command]${GREEN}"
				echo ""
				echo "To enter root shell, pass the ${YELLOW}--asroot${GREEN} argument"
				echo "${YELLOW} debdroid launch --asroot${GREEN}"
				echo "${YELLOW} debdroid launch --asroot -- [command]${GREEN}"
				echo "To learn more about operating Debian system, see the Debian Wiki ${YELLOW}https://wiki.debian.org${GREEN} and ${YELLOW}https://wiki.debian.org/DontBreakDebian${NOATTR}"
				return 0
				;;
			*)
				echo "${RED}E: Invalid option $1, run ${YELLOW}debdroid launch --help${RED} to show supported options, or run without arguments${NOATTR}" >&2
				return 1
				;;
		esac
		shift
	done

	# Check for an ongoing setup
	if [ -e "${DEBDROID__DEBIAN_FS}/.setup_has_not_done" ]; then
		echo "${RED}N: An ongoing setup is running, please finish the configuration first before continuing${NOATTR}" >&2
		exit 1
	fi

	# Launch PRoot
	# Source the file
	source "${DEBDROID__DEBIAN_FS}/.proot.debdroid/run_debian"

	exec proot "$@"
}


# Function to backup the container
backup_debian_container(){
	local args

	if [ ! -e "${DEBDROID__DEBIAN_FS}/.proot.debdroid/run_debian" ]; then
		echo "${RED}E: Cannot backup the Debian container: The Debian container isn't installed${NOATTR}" >&2
		exit 1
	fi

	args="$@"

	if [ -z "${args}" ]; then
		echo "${RED}E: Please specify a filename to output the tarball${NOATTR}" >&2
		exit 1
	fi

	echo "${GREEN}I: The backup file will be saved in $(realpath -m "${args}")${NOATTR}"
	echo "${YELLOW}I: Backing up the container... this may take some time${NOATTR}"
	if tar --preserve-permissions -zcf "${args}" -C "${DEBDROID__DEBIAN_FS}" ./; then
		echo "${GREEN}I: The container successfully exported${NOATTR}"
		exit 0
	else
		echo "${RED}I: The container isn't successfully exported${NOATTR}" >&2
		exit 1
	fi
}

# Function to restore the container
restore_debian_container(){
	local args
	local userinput

	args="$@"

	if [ -z "${args}" ]; then
		echo "${RED}E: Please specify a backup file for restoring the container${NOATTR}" >&2
		exit 1
	fi

	# Check if the tarball exists
	if [ ! -e "$(realpath -m "${args}")" ]; then
		echo "${RED}E: The backup file that you're trying to import dosen't exist${NOATTR}" >&2
		exit 1
	fi

	# User Input
	read -p "${GREEN}I: Do you want to restore the container? All of the existing state will be lost [y/N]? ${NOATTR}" userinput
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
	mkdir -p "${DEBDROID__DEBIAN_FS}"
	if tar --recursive-unlink --delay-directory-restore --preserve-permissions -zxf "$(realpath -m "${args}")" -C "${DEBDROID__DEBIAN_FS}"; then
		echo "${GREEN}I: The container successfully imported${NOATTR}"
		exit 0
	else
		echo "${RED}I: The container isn't successfully imported${NOATTR}" >&2
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
			shift 1; uninstall_debian
			;;
		reconfigure|configure)
			shift 1;
			if perform_configuration; then
				echo "${GREEN}I: Done configuring the Debian container${NOATTR}"
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
			show_help; exit 1
			;;
	esac
else
	show_help
fi
