#!/data/data/com.termux/files/usr/bin/bash
#############################################
# DebDroid (Improved, debdroid-ng)
# All rights reserved (2020, 2021)
# 
# This script will automate the process of the installation of debian in the palm of your hand
# It will do an Debian install to your Android Device without needing to root your device!
#############################################
# Used to generate random number, this is used for cache dirs and custom installs
RN_STRING="$RANDOM"

# Used for Default Install Directory
DEFAULT_DIR="$HOME/.local/share/debian"

# Used to Store Cache
CACHE_DIR="$PREFIX/tmp/.debdroid-cache-$RN_STRING"

# Versioning Environment Variable (Used to echo the version and check if this version is the latest one)
DEBDROID_VERSION="3.10"

# Install 'ncurses-utils' if possible (The color output will be limited, used for clarity of the text)
if [ ! -e "$PREFIX/bin/tput" ]; then
    echo "The command 'tput' not found... Installing it"
    pkg update -yy
    pkg install ncurses-utils -yy
fi

# Colored Environment Variables
RED="$(tput setaf 1)$(tput bold)"
GREEN="$(tput setaf 2)$(tput bold)"
YELLOW="$(tput setaf 3)$(tput bold)"
NOATTR="$(tput sgr0)"

# Handle Signal
sigtrap(){
    echo "${RED}Signal Recieved! Exiting as Requested...${NOATTR}"
    exit 2
}

trap 'sigtrap' HUP INT KILL QUIT TERM

# Don't run as root
if [ "$(whoami)" == "root" ]; then
    echo "${RED}Please don't run me as root, it is currently not supported yet${NOATTR}"
    exit 2
fi

# Do an update check of the script
if [ ! "$(curl https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/version.txt)" == "$DEBDROID_VERSION" ]; then
    echo "${GREEN}I: a new version of this script is available!${NOATTR}"
    sleep .4
fi

# Process arguments
show_help(){
    echo "${GREEN}DebDroid: Debian installer for the Android OS!!!"
    echo ""
    echo "This utility allows you to install debian with a keystroke on your Android Device"
    echo "You can install/configure debian with this script by typing"
    echo "${YELLOW}debdroid setup ${GREEN}without arguments"
    echo ""
    echo "${GREEN}It will launch a dialog-based installer, just like a Debian CLI installer"
    echo "See ${YELLOW}https://www.debian.org/releases/stable/mips/install.pdf${GREEN} for reference"
    echo ""
    echo "${GREEN}If you want to customize your debian system, the command ${YELLOW}debdroid-configure${GREEN} allows you to configure your debian system after install"
    echo "it will allow you to easily setup your desired Desktop Environment or your necessary tools you need to operate debian system, optimized for Android devices"
    echo ""
    echo "If you have debian installed, you can call the command ${YELLOW}run-debian${GREEN} launches your debian environment"
    echo ""
    echo "The default installation path of your debian install is in ${YELLOW}$HOME/.local/share/debian${GREEN}. if you want to install it in an alternate directory"
    echo "Run ${YELLOW}debdroid setup${GREEN} and you should select ${YELLOW}install${GREEN} and select ${YELLOW}install in alternate directory"
    echo ""
    echo "${GREEN}This script only takes 2 arguments, setup and help so this is a dialog-based setup, to help users interact with the installer and the configuration of debian system"
    echo ""
    echo "This script also checks updates every time you run this script, so to update, simply install a fresh copy of this script and you're done in just a few taps"
    echo ""
    echo "If you have issues, PR's, Contributions are welcome, feel free to file a bug report in"
    echo "https://github.com/WMCB-Tech/debdroid-ng/issues${NOATTR}"
    exit 0
}

# Check for dependencies
if [ ! -e "$PREFIX/bin/proot" ] && [ ! -e "$PREFIX/bin/dialog" ] && [ ! -e "$PREFIX/bin/curl" ]; then
    echo "${YELLOW}I: Installing Dependencies needed for DebDroid${NOATTR}"
    sleep .2
    pkg update
    pkg install proot dialog curl -yy
fi

# Function to run proot
enter-chroot(){
    proot --link2symlink --kill-on-exit -0 \
        -L -p --kernel-release="5.1.0-debdroid" \
        -r "$DESIRED_LOCATION" \
        --bind="/dev" \
        --bind="/proc" \
        --bind="/sys" \
        --bind="$DESIRED_LOCATION/run/shm:/dev/shm" \
        --bind="/dev/urandom:/dev/random" \
        -w /root \
        /usr/bin/env -i \
            TERM="$TERM" \
            PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:/opt"
            HOME="/root"
            USER="root"
            LANG="C.UTF-8"
            "$@"
}
propagate_spec(){
    if [ -n "$CHROOT_NAME" ]; then
        LAUNCH_CMD="run-debian-$CHROOT_NAME"
        CONFIGURE_CMD="debdroid-configure-$CHROOT_NAME"
    else
        LAUNCH_CMD="run-debian"
        CONFIGURE_CMD="debdroid-configure"
    fi
}
# Function to Setup Groups
group_setup(){
    echo "aid_$(id -un):x:$(id -u):$(id -g):Android Groups:/:/usr/sbin/nologin" >> "$DESIRED_LOCATION/etc/passwd"
	echo "aid_$(id -un):*:18446:0:99999:7:::" >> "$DESIRED_LOCATION/etc/shadow"
	local g
		for g in $(id -G); do
			echo "aid_$(id -gn "$g"):x:${g}:root,aid_$(id -un)" >> "$DESIRED_LOCATION/etc/group"
			if [ -f "$DESIRED_LOCATION/etc/gshadow" ]; then
				echo "aid_$(id -gn "$g"):*::root,aid_$(id -un)" >> "$DESIRED_LOCATION/etc/gshadow"
			fi
		done
}

write-necessary-envvars(){
cat > "$DESIRED_LOCATION/etc/profile.d/debdroid-env.sh" <<- EOM
#!/bin/bash
export PULSE_SERVER=127.0.0.1
export MOZ_FAKE_NO_SANDBOX=1
export MOZ_DISABLE_GMP_SANDBOX=1
export MOZ_DISABLE_CONTENT_SANDBOX=1
export PATH=\$PATH:/usr/local/games:/usr/games
export LANG=C.UTF-8
export TMPDIR=/tmp
EOM
}

# Function to Configure Debian
config_debian(){
    if [ ! -e "$DESIRED_LOCATION/usr/bin/apt" ]; then
        echo "${RED}WARNING: Cannot Configure the Container: Invalid type${NOATTR}"
        sleep 3
        docker_setup_dialog
    fi
    # Add Android Groups if needed
    if [ ! -e "$DESIRED_LOCATION/var/debdroid/.setup-groups-done" ]; then
        mkdir -p "$DESIRED_LOCATION/var/debdroid"
        group_setup
    fi
    # Add /run/shm binding for proper programs needed to access /dev/shm
    if [ ! -e "$DESIRED_LOCATION/run/shm" ]; then
        mkdir "$DESIRED_LOCATION/run/shm"
    fi
    # Setup Environment
    # Add contrib, non-free components
    enter-chroot sed -i 's/main/main contrib non-free/' /etc/apt/sources.list
    # Delete Docker Files, issue with termux/proot https://github.com/termux/proot/issues/135
    enter-chroot rm -rf /etc/apt/apt.conf.d/docker-*
    echo "${GREEN}I: Updating the Debian System if Necessary"
    enter-chroot apt update
    enter-chroot apt upgrade -yy ||:
    echo "${GREEN}I: Installing Packages if Necessary${NOATTR}"
    enter-chroot apt install dbus-x11 tzdata dialog sudo nano procps -yy
    echo "${GREEN}I: Doing Pending Configuration: ${YELLOW}apt install -f${NOATTR}"
    enter-chroot apt install -f -yy ||:
    echo "${GREEN}I: Doing Pending Configuration: ${YELLOW}install -m 755 /dev/null /usr/local/bin/dpkg-statoverride${NOATTR}"
    enter-chroot install -m 755 /dev/null /usr/local/bin/dpkg-statoverride
    echo "${GREEN}I: Doing Pending Configuration: ${YELLOW}install -m 755 /dev/null /usr/local/bin/dpkg-udevadm${NOATTR}"
    enter-chroot install -m 755 /dev/null /usr/local/bin/dpkg-statoverride
    echo "${GREEN}I: Doing Pending Configuration: ${YELLOW}dpkg --configure -a${NOATTR}"
    enter-chroot dpkg --configure -a
    echo "${GREEN}I: Writing Environment variables if necessary${NOATTR}"
    write-necessary-envvars
    echo "${GREEN}I: Almost Finishing Setup${NOATTR}"
    enter-chroot dpkg-reconfigure tzdata ||:
    if [ ! -e "$DESIRED_LOCATION/var/debdroid/userinfo.db" ]; then
        username=$(dialog --title "Finish Debian Setup" --backtitle "Debian GNU/Linux Configuration" --nocancel --inputbox "Enter your desired username for your default user account" 9 40 3>&1 1>&2 2>&3 3>&- )
        enter-chroot useradd -m "$username" -s /bin/bash
        password=$(dialog --title "Finish Debian Setup" --backtitle "Debian GNU/Linux Configuration" --nocancel --insecure --passwordbox "Enter your password for your default user account" 9 40 3>&1 1>&2 2>&3 3>&- )
        enter-chroot sh -c "echo $username:$password | chpasswd"
        enter-chroot sh -c "echo '$username ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/$username"
        echo "$username" > "$DESIRED_LOCATION/var/debdroid/userinfo.db"
    fi
    echo "$SUITE" > "$DESIRED_LOCATION/etc/debian_chroot"
    if [ ! "$DESIRED_LOCATION" == "$DEFAULT_DIR" ]; then
        echo "$DESIRED_LOCATION" > "$DESIRED_LOCATION/var/debdroid/custom_rootfs_info"
    fi
    echo "${GREEN}I: Downloading Necessary Scripts${NOATTR}"
    curl --output "$PREFIX/bin/$LAUNCH_CMD" --fail https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/run-debian
    curl --output "$PREFIX/bin/$CONFIGURE_CMD" --fail https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/debdroid-configure
    chmod 755 "$LAUNCH_CMD"
    chmod 755 "$CONFIGURE_CMD"
    sed -i 's|ROOTFS_DIR=placeholder|ROOTFS_DIR=$DESIRED_LOCATION|g' "$LAUNCH_CMD"
    sed -i 's|ROOTFS_DIR=placeholder|ROOTFS_DIR=$DESIRED_LOCATION|g' "$CONFIGURE_CMD"
}
# Function to Install Debian
install_debian(){
        if [ -e "$DESIRED_LOCATION" ]; then
            echo "${RED}W: The Container is already installed!${NOATTR}"
            sleep 3
            docker_setup_dialog
        fi
        case "$SUITE" in
            sid)
                curl https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/suite/dlmirrors/sid --silent --fail --output "$CACHE_DIR/source_suite"
                source "$CACHE_DIR/source_suite"
                ;;
            testing)
                curl https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/suite/dlmirrors/testing --silent --fail --output "$CACHE_DIR/source_suite"
                source "$CACHE_DIR/source_suite"
                ;;
            bullseye)
                curl https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/suite/dlmirrors/bullseye --silent --fail --output "$CACHE_DIR/source_suite"
                source "$CACHE_DIR/source_suite"
                ;;
            buster)
                curl https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/suite/dlmirrors/buster --silent --fail --output "$CACHE_DIR/source_suite"
                source "$CACHE_DIR/source_suite"
                ;;
            stretch)
                curl https://raw.githubusercontent.com/WMCB-Tech/debdroid-ng/master/suite/dlmirrors/stretch --silent --fail --output "$CACHE_DIR/source_suite"
                source "$CACHE_DIR/source_suite"
                ;;
            *)
                echo "${RED}E: Unknown Distribution was requested${NOATTR}"
                dialog_install_debian
                ;;
            esac
        echo "${GREEN}I: The Following Distribution was requested: ${YELLOW}$SUITE${NOATTR}"
        sleep .2
        echo "${GREEN}I: Downloading the Image file: ${YELLOW}$DEBIAN_NAME${NOATTR}"
        curl --output "$CACHE_DIR/$DEBIAN_NAME-$RN_STRING.tar.xz.part" --fail ${CURL_DOWNLOAD_LINK}
            if [ -e "$CACHE_DIR/$DEBIAN_NAME-$RN_STRING.tar.xz.part" ]; then
                mv "$CACHE_DIR/$DEBIAN_NAME-$RN_STRING.tar.xz.part" "$CACHE_DIR/$DEBIAN_NAME-$RN_STRING.tar.xz"
            else
                echo "${RED}E: An Error Has occurred: no such file or directory${NOATTR}"
                dialog_install_debian
            fi
        echo "${GREEN}I: Extracting the Image file. This may take some time${NOATTR}"
        proot --link2symlink -0 tar --delay-directory-restore --preserve-permissions -xf "$CACHE_DIR/$DEBIAN_NAME-$RN_STRING.tar.xz" -C "$DESIRED_LOCATION" --exclude dev ||:
        # Add an indication if it's installed under custom directory 
            if [ ! -z "$CHROOT_NAME" ]; then
                echo "$CHROOT_NAME" > "$DESIRED_LOCATION/.customdir_spec"
            fi
        propagate_spec
        echo "${GREEN}I: Configuring the Base System (TIP: If the reconfiguration is interrupted, you may reconfigure it with ${YELLOW}debdroid setup${GREEN})${NOATTR}"
        if config_debian; then
            dialog --title "Information" --backtitle "Debian GNU/Linux Configuration" --msgbox "Successfully installed Debian $DEBIAN_NAME you can start it by typing '$LAUNCH_CMD'. \
            You may also configure your setup easily and automates the install of your Desktop Environment or Window Manager Setup by typing '$CONFIGURE_CMD'" 16 46
            exit 0
        else
            dialog --title "Information" --backtitle "Debian GNU/Linux Configuration" --msgbox "An Error has occured during the installation of the Debian System \
            Should this happen? you can run 'debdroid setup' then select reconfigure, it will ask you to choose what container you want to configure" 20 50
            docker_setup_dialog
        fi
}
# Function to Delete Debian
delete_debian(){
    if [ ! -e "$DESIRED_LOCATION/usr/bin/apt" ]; then
        echo "${RED}W: Cannot Delete the Container: Invalid type${NOATTR}"
        sleep 3
        docker_setup_dialog
    fi
    propagate_spec
    echo "${YELLOW}I: Deleting the container $DESIRED_LOCATION${NOATTR}"
    chmod 777 "$DESIRED_LOCATION" -R ||:
    rm -rf "$DESIRED_LOCATION"
    rm -rf "$LAUNCH_CMD"
    rm -rf "$CONFIGURE_CMD"
    echo "${GREEN}I: The Container successfully deleted!!!${NOATTR}"
    sleep 3
    docker_setup_dialog
}
# Dialog Functions
# Function to Select Suite
check_suite(){
    suite_choice="$(
        dialog --title "DebDroid Setup" --backtitle "Debian GNU/Linux Configuration" \
        --menu "Select the Desired Flavor of your choice, you may either sid if you want" 25 50 \
        "1" "Debian Sid (A rolling-version of Debian: Bookworm 12)" \
        "2" "Debian Testing (A rolling-version of Debian)" \
        "3" "Debian Bullseye (The Upcoming Debian Version)" \
        "4" "Debian Buster (Current Debian Stable Version)" \
        "5" "Debian Stretch (Oldstable Debian Version; Still Supported by Debian Foundation)" \
        3>&1 1>&2 2>&3 3>&-
        )"
    
    case "$suite_choice" in
        0|"")
            dialog_install_debian
            ;;
        1)
            SUITE="sid"
            ;;
        2)
            SUITE="testing"
            ;;
        3)
            SUITE="bullseye"
            ;;
        4)
            SUITE="buster"
            ;;
        5)
            SUITE="stretch"
            ;;
    esac
}
# Function to ask a user if they really want to delete debian
prompt_delete_confirm(){
    redpill_bluepull=$(
        dialog --title "DebDroid Setup" --backtitle "Debian GNU/Linux Configuration" \
        --yesno "Do you want to delete the container '$DESIRED_LOCATION'" 7 50 \
        3>&1 1>&2 2>&3 3>&-
    )

    case "$redpill_bluepill" in
        0)
            delete_debian
            ;;
        1)
            dialog_delete_debian
            ;;
        255)
            dialog_delete_debian
            ;;
    esac
}
# Function to Install Debian
dialog_install_debian(){
    prompt_whatdefaults=$(
        dialog --title "DebDroid Setup" --backtitle "Debian GNU/Linux Configuration" \
        --menu "What Install Directory you want to use for installation" 12 50 \
        "1" "Default Directory (\$HOME/.local/share/debian)" \
        "2" "Specify Custom Directory (Beta)" \
        "0" "Go Back" \
        3>&1 1>&2 2>&3 3>&-
    )
    
    case "$prompt_whatdefaults" in 
        0|"")
            docker_setup_dialog
            ;;
        1)
            DESIRED_LOCATION="$DEFAULT_DIR"
            CHROOT_NAME=""
            check_suite
            install_debian
            ;;
        2)
            DESIRED_LOCATION=$(
                dialog --title "DebDroid Setup" \
                    --backtitle "Debian GNU/Linux Configuration" \
                    --inputbox "Enter the location where to store your installation (NOTE: This is still beta)" \
                    10 40 \
                    3>&1 1>&2 2>&3 3>&-
                    )
            CHROOT_NAME=$(
                dialog --title "DebDroid Setup" \
                    --backtitle "Debian GNU/Linux Configuration" \
                    --inputbox "Enter the name to specify your custom Debian installation" \
                    9 40 \
                    3>&1 1>&2 2>&3 3>&-
                    )
            check_suite
            install_debian
            ;;
    esac
}
# Function to Reconfigure Debian
dialog_config_debian(){
    prompt_whatconfigs=$(
        dialog --title "DebDroid Setup" --backtitle "Debian GNU/Linux Configuration" \
        --menu "What Install Directory you want to use for reconfiguration" 12 50 \
        "1" "Default Directory (\$HOME/.local/share/debian)" \
        "2" "Specify Custom Directory (Beta)" \
        "0" "Go Back" \
        3>&1 1>&2 2>&3 3>&-
    )

    case "$prompt_whatconfigs" in
        0|"")
            docker_setup_dialog
            ;;
        1)
            DESIRED_LOCATION="$DEFAULT_DIR"
            config_debian
            ;;
        2)
            DESIRED_LOCATION=$(
                dialog --title "DebDroid Setup" \
                    --backtitle "Debian GNU/Linux Configuration" \
                    --inputbox "Enter the location where to reconfigure your installation (NOTE: This is still beta)" \
                    10 40 \
                    3>&1 1>&2 2>&3 3>&-
                    )
            config_debian
            ;;
    esac
            
}
# Function to Delete Debian
dialog_delete_debian(){
    prompt_whatconfigs=$(
        dialog --title "DebDroid Setup" --backtitle "Debian GNU/Linux Configuration" \
        --menu "What Install Directory you want to use for removal" 12 50 \
        "1" "Default Directory (\$HOME/.local/share/debian)" \
        "2" "Specify Custom Directory (Beta)" \
        "0" "Go Back" \
        3>&1 1>&2 2>&3 3>&-
    )

    case "$prompt_whatconfigs" in
        0|"")
            docker_setup_dialog
            ;;
        1)
            DESIRED_LOCATION="$DEFAULT_DIR"
            prompt_delete_confirm
            ;;
        2)
            DESIRED_LOCATION=$(
                dialog --title "DebDroid Setup" \
                    --backtitle "Debian GNU/Linux Configuration" \
                    --inputbox "Enter the location where to delete your Debian installation (NOTE: This is still beta)" \
                    10 40 \
                    3>&1 1>&2 2>&3 3>&-
                    )
            prompt_delete_confirm
            ;;
    esac
            
}
# Function to prompt a user
docker_setup_dialog(){
    prompt_setup=$(
        dialog --title "DebDroid Setup" --backtitle "Debian GNU/Linux Configuration" \
            --menu "Please Choose a Selection to configure Debian Linux on your Device" 14 45 \
            "1" "Install Debian Linux onto your device" \
            "2" "Reconfigure Debian Installation (Performs Refresh/Update)" \
            "3" "Uninstall Debian Linux (Uninstalls Debian on your device)" \
            "0" "Exit (Close this Dialog and leave changes intact)" \
            3>&1 1>&2 2>&3 3>&-
        )

    case "$prompt_setup" in
        0|"")
            echo "${YELLOW}I: Syncing Changes${NOATTR}";
            exit 0
            ;;
        1)
            dialog_install_debian
            ;;
        2)
            dialog_config_debian
            ;;
        3)
            dialog_delete_debian
            ;;
    esac
    ## END OF DIALOG MESSAGE
}

ARG="$1"
shift 1

case "$ARG" in
    setup|install|delete|remove|uninstall|reconfigure)
        docker_setup_dialog
        ;;
    help|--help|-h|h)
        show_help
        ;;
    *)
        show_help
        exit 2
        ;;
esac
# End of message EOM
# All rights reserved (2020 2021)