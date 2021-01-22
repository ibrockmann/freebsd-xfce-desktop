#!/bin/sh

#============================================================================
# Install Xfce 4.16 Desktop on FreeBSD 12.2
# by ibrockmann, Version: 2021-01-22
# 
# Notes: Installation of Xfce 4.16 Desktop Environment with Matcha and 
#  Arc GTK Themes on FreeBSD 12.2
#
# Display driver: Script supports onyl current nvidia (440.xx series) and VMware
#  display driver
# When using VMware, Screen size variable muste be set to your needs.
# Default: 1280x1024
#
# Applications: Audacious, Catfish, Chromium, Gimp, htop, KeePass, LibreOffice,
# mpv, neofetch, OctoPkg, Ristretto, Shotweel, sysinfo, Thunderbird, VIM, VLC
#
#
# Language and country code is set to German. It can be changed to your need in
# User defined variables section.
#
#  
#============================================================================


# ---------------------------------- declaration of variables -----------------
# -----------------------------------------------------------------------------

# ---------------------- User defined environment variables -------------------
# ---------------------- adapt variables to your needs -------------------------

# Language and Country Code, Keyboard layout, Charset
LOCALE='de_DE.UTF-8' 		     # LanguageCode_CountryCode.Encoding, a complete list can be found by typing: % locale -a  | more
ACCOUNT_TYPE='german|German'     # Language name|Account Type Description, environment variables login.conf
KEYBOARD_LAYOUT='de'			 # Keyboard layouts and other adjustable parameters are listed in man page xkeyboard-config(7).
SCREEN_SIZE='2560x1440'			 # Only required if VMWare is used.	

# ---------------------------------- utilities -------------------------------
# ---- 0 - utility will be installed ---- 1 - utility will NOT be installed --

INSTALL_CATFISH=0				# Catfish is a GTK based search utility
INSTALL_OCTOPKG=0				# Graphical front-end to the FreeBSD pkg-ng package manager
INSTALL_NEOFETCH=0				# Fast, highly customizable system info script
INSTALL_SYSINFO=0				# Utility used to gather system configuration information
INSTALL_HTOP=0					# Better top - interactive process viewer


# -----------------------------------------------------------------------------
# --------------------- Do not change anything from here on -------------------
# -----------------------------------------------------------------------------

# environment variables
PAGER=cat #used by freebsd-update, instead of PAGER=less
export PAGER

# define colors
COLOR_NC='\033[0m' #No Color
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[1;34m'
COLOR_CYAN='\033[0;36m'


# --------------- initialization: account type, charset and country code ------
ACCOUNT=`echo $ACCOUNT_TYPE | cut -d '|' -f2`				# e.g. German
CHARSET=`echo $LOCALE | cut -d . -f2` 						# Charset
COUNTRY_CODE=`echo $LOCALE | cut -d . -f1 | cut -d _ -f2`	# Country_Code



## ----------------------------------- user interaction -----------------------
## ----------------------------------------------------------------------------

# ------------------------------------ greeting -------------------------------

clear
printf "${COLOR_CYAN}Installation of Xfce Desktop Environment for FreeBSD 12.2${COLOR_NC}\n\n"
printf "This script will install pkg, X11 and the Xfce Desktop with Matcha and Arc GTK Themes.\n"
printf "Additionally some basic applications will be installed: Audacious, Catfish, Chromium,\n"
printf "Gimp, htop, KeePass, LibreOffice, mpv, neofetch, OctoPkg, Shotweel, Sysinfo, Thunderbird,\n"
printf "Vim, VLC.\n" 
printf "Install script supports current nvidia FreeBSD (X64) and VMware display drivers.\n"
printf "When using VMware, Screen size variable muste be set to your needs. Default: 1280x1024\n"
printf "Language and country code is set to German.\n"
printf "It can be changed to your need in the 'User defined environment variables' section.\n"
printf "\nIf you made a mistake answering the questions, you can quit out of the installer\n"
printf "by pressing ${COLOR_CYAN}CTRL+C${COLOR_NC} and then start again.\n\n"


# ------------------------------------ preconditions ----------------------------
check_if_root () {
	if [ "$(id -u)" -ne 0 ]; then
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  This script must run as ${COLOR_CYAN}root${COLOR_NC}!\n\n"
		exit 1
	fi
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Running script ${COLOR_CYAN}$0${COLOR_NC} as root\n"
}


display_system_info () {
printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  OS: $(uname -mrs)\n"
}


check_network () {
	if nc -zw1 8.8.8.8 443 > /dev/null 2>&1 ; then # Google DNS
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Internet connection detected\n"
	else
		printf "[ ${COLOR_YELLOW}WARNING${COLOR_NC} ]  Could not verify internet connection!\n"
		printf "[ ${COLOR_YELLOW}WARNING${COLOR_NC} ]  You must be online for this script to work!\n"
		printf "[ ${COLOR_YELLOW}WARNING${COLOR_NC} ]  Proceed with caution ...\n\n"
	fi
}


# ------------------------------------ freebsd update ----------------------------
freebsd_update () {
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  FreeBSD Update: Applying latest FreeBSD security patches\n\n"
	freebsd-update fetch
	freebsd-update install
	# disable reboot check, because system reboot is required anyway 
	# INSTALL_UPDATES=$?
	# if [ `freebsd-version -k` != `uname -r` ]; then
	#	printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  A reboot of FreeBSD is required! Execute ${COLOR_CYAN}$0${COLOR_NC} again after system has been rebooted.\n"
	#	printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Aborting installation!\n"
	#	exit 1
	# elif [ $INSTALL_UPDATES -ne 2 ]; then # freebsd-update install return value = 2 when system is up-to-date
	#	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  FreeBSD has been successfully updated to ${COLOR_CYAN}"`freebsd-version -k`"${COLOR_NC}\n"
	# else
	#	printf "\n"
	# fi
}


# ------------------------------------ pkg activation status check ----------------------------
check_pkg_activation () {
	if pkg -N >/dev/null  2>&1; then
		printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  pkg is installed and activated\n"
		INSTALL_PKG=0
	else
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  pkg will be installed\n"
		INSTALL_PKG=1
	fi
}


# ------------------------------------ pkg installation ----------------------------
install_pkg () {
	if [ "$INSTALL_PKG" -eq 1 ] ; then
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Bootstrapping pkg\n\n"
		env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg
		echo ""
	else
		printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Skipping pkg bootstrap\n"
	fi
}


# ------------------------------------ switch to latest repository branch and update pkg ----------------------------
switch_to_latest_repository () {	
	mkdir -p /usr/local/etc/pkg/repos
	cp /etc/pkg/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf

	sed -i .bak 's/quarterly/latest/' /usr/local/etc/pkg/repos/FreeBSD.conf
	rm /usr/local/etc/pkg/repos/FreeBSD.conf.bak

	if pkg update -f ; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Switched to the latest pkg repository branch" # pkg update successfully completeted
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  PKG update failed\n"
		exit 1
	fi
}


# ------------------------------------ yes or no question ---------------------
yes_no () {
    if [ -z $2 ]; then str="yes"; else str="no"; fi #preselection = no, if $2 not empty
	while true; do
	    printf "$1 (yes/no) [$str]: " #$1 question
		read REPLY
		case $(echo $REPLY | tr "[:upper:]" "[:lower:]") in
			y|yes) return 0;;
			n|no) return 1;;	
			'') if [ -z $2 ]; then return 0; else return 1; fi ;; #Return / Enter key, always true if $2 is missing			
			*) printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Please answer with yes or no.\n";;
		esac
	done
}



# ------------------------------------- add login class user accounts ---
add_login_class () {
	local rc=0
	DATE=`date "+%Y%m%d_%H%M%S"`
	awk "/lang=$LOCALE/{rc=1}/{exit}/ END{exit !rc}" /etc/login.conf #Login_class for $LOCALE exists?
	
	if [ $? -eq 1 ]; then  # add login class for all users if NOT exists!
		cp /etc/login.conf /etc/login.conf.$DATE #backup
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create backup of ${COLOR_CYAN}/etc/login.conf${COLOR_NC}. File: ${COLOR_CYAN}/etc/login.conf.$DATE${COLOR_NC}\n"
		COMMENT="#\n# ${ACCOUNT} Users Accounts. Setup proper environment variables.\n#\n"
		LOGIN_CLASS="${ACCOUNT_TYPE} Users Accounts:\\\\\n\t:charset=${CHARSET}:\\\\\n\t\:lang=${LOCALE}:\\\\\n\t:tc=default:\n"
		awk -v text="$COMMENT" -v lc="$LOGIN_CLASS" '{print};/:lang=ru_RU.UTF-8:/{c=4}c&&!--c { print text lc }' /etc/login.conf > /etc/login.tmp
		mv /etc/login.tmp /etc/login.conf
		cap_mkdb /etc/login.conf
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Added ${COLOR_CYAN}${ACCOUNT}${COLOR_NC} language settings to ${COLOR_CYAN}/etc/login.conf${COLOR_NC}\n"
	fi
}

# ------------------------------------ set login class  ----
set_login_class () {
	if yes_no "Change language settings (language code, country code, and encoding) for ${COLOR_CYAN}SOME${COLOR_NC} users to ${COLOR_CYAN}${COUNTRY_CODE}${COLOR_NC} (${ACCOUNT})?"; then
		awk -v green=$COLOR_GREEN -v nc=$COLOR_NC -v cyan=$COLOR_CYAN -F: 'BEGIN {printf "\n[ "green"INFO"nc" ]  List of FreeBSD users: "} \
		   ($3 >= 1001) && ($3 != 65534) {printf cyan $1 nc " "}' /etc/passwd
		printf "\n\n"
		read -p "Enter the user names who should use $ACCOUNT language settings [ ]:" USERNAME
		echo
		for i in $USERNAME
		do
		    # set locale and error handling when a user does not exist		
			pw usermod -n $i -L `echo ${ACCOUNT} | tr "[:upper:]" "[:lower:]"` 2>&1 | awk -v yellow=$COLOR_YELLOW -v nc=$COLOR_NC '{print "[ "yellow "WARNING" nc" ]  "$0} {exit 1}'
			if [ $? -eq 0 ] ; then 
				pw usershow $i | awk -v nc=$COLOR_NC -v cyan=$COLOR_CYAN  -v green=$COLOR_GREEN -F: '{printf "[ "green "INFO" nc " ]  Login Name: "$1"\tHome: "$9"\t"cyan"Class: "$5 nc"\tShell: "$10"\n"}'
			fi
		done
    else
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  No user added to German language class!\n" 
	fi
}


# ------------------------------------ set login class for ALL users ----
set_login_class_all () {
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  The default language (language code, country code, and encoding) is currently set to ${COLOR_CYAN}US${COLOR_NC} (US English).\n\n"
	if yes_no "Change language settings (language code, country code and encoding) for ${COLOR_CYAN}ALL${COLOR_NC} users to ${COLOR_CYAN}${COUNTRY_CODE}${COLOR_NC} (${ACCOUNT})?"; then
		for i in `awk -F: '($3 >= 1001) && ($3 != 65534) { print $1 }' /etc/passwd`; 
		do 
			pw usermod -n $i -L `echo $ACCOUNT |tr "[:upper:]" "[:lower:]"` 2>&1 | awk -v yellow=$COLOR_YELLOW -v nc=$COLOR_NC '{print "[ "yellow "WARNING" nc" ]  "$0}'
			pw usershow $i | awk -v nc=$COLOR_NC -v cyan=$COLOR_CYAN  -v green=$COLOR_GREEN -F: '{printf "[ "green "INFO" nc " ]  Login Name: "$1"\tHome: "$9"\t"cyan"Class: "$5 nc"\tShell: "$10"\n"}'  
		done
		return 0
	else
	 return 1
	fi
}



# ------------------------------------ install a package from the reposity catalogues ----
install_packages() {
for PACKAGENAME in $*
do
		if pkg search -L name $PACKAGENAME | cut -w -f1 | grep -x -q $PACKAGENAME; then #Check if FreeBSd package vorhanden
		pkg install -y $PACKAGENAME	
		else
			printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] pkg: No packages available to install matching ${COLOR_CYAN}"$PACKAGENAME"${COLOR_NC}!\n"
	fi
done
}


# ------------------------------------ x11-fonts-------------------------------
install_fonts () {
local FONTS
# ------------------------------------ basic fonts ----------------------------
#x11-fonts/bitstream-vera		#Supports fully hinting, which improves the display on computer monitors.
#x11-fonts/cantarell-fonts   	#Cantarell, a Humanist sans-serif font family
##x11-fonts/dejavu		  		#will be installed with xorg
#x11-fonts/droid-fonts-ttf 		#System fonts for Android platform
#x11-fonts/noto					#Google Noto Fonts family (meta port)
#x11-fonts/urwfonts				#URW font collection for X
#x11-fonts/ubuntu-font			#Ubuntu font family
#x11-fonts/webfonts				#TrueType core fonts for the Web
#x11-fonts/liberation-fonts-ttf #Liberation fonts from Red Hat to replace MS TTF fonts


# ------------------------------------ terminal & editor fonts-----------------
#x11-fonts/anonymous-pro		#Fixed width sans designed especially for coders
#x11-hack/hack-font				#Monospaced font designed to be a workhorse typeface for code
#x11-fonts/sourcecodepro-ttf 	#Set of fonts by Adobe designed for coders
#x11-fonts/terminus-font		#Terminus Font is designed for long (8 and more hours per day) work with computers
#x11-fonts/Inconsolata-LGC		#Attractive font for programming

FONTS="anonymous-pro bitstream-vera cantarell-fonts droid-fonts-ttf hack-font noto sourcecodepro-ttf terminus-font urwfonts ubuntu-font webfonts liberation-fonts-ttf Inconsolata-LGC"
for font in  $FONTS; do
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing font: ${COLOR_CYAN}$font${COLOR_NC}\n"
	install_packages $font
done
}


# --------------------------- check if nvidia or vmware ----------------------- 
# ---------------------------- display driver required ------------------------

check_vga_card() {
    local vendor i
	i=5
	pciconf -lv | sed 's/ *= /=/' | while read line # read stdout line by line
		do
			if echo $line | grep -q "^vgapci"; then #find section with vga device
				i=$(( $i - 1 ))
			fi	
			
			#each device has 4 lines of data
			if [ $i -ge 0 ] && [ $i -lt 5 ]; then
					vendor=`echo $line | grep -w "vendor" | cut -d'=' -f2`
					i=$(( $i - 1 ))
					case $vendor in
						"'VMware'") return 1;; # X11 VMWARE video driver
						"'nvidea'") return 2;; # X11 NVIDEA video-driver
						'') ;;	 
						*) return 5 ;;	# This video card is not supportet 
					esac
			fi
        done
}


# --------------------------- set keyboard for X11 ---------------------------- 
set_xkeyboard () {
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  The default keymap for XFCE and the login is '${COLOR_CYAN}us${COLOR_NC}' (English).\n"
	if [ "$KEYBOARD_LAYOUT" != "us"  ] ; then
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Keyboard layout will be changed to '${COLOR_CYAN}$KEYBOARD_LAYOUT${COLOR_NC}' (${ACCOUNT}).\n"
	fi

	mkdir -p /usr/local/etc/X11/xorg.conf.d
	chmod 755 /usr/local/etc/X11/xorg.conf.d
	echo "Section \"InputClass\"
	  Identifier 		\"KeyboardDefaults\"
	  MatchIsKeyboard 	\"on\"
	  Option 		\"XkbLayout\" \"${KEYBOARD_LAYOUT}\"
	  EndSection" > /usr/local/etc/X11/xorg.conf.d/keyboard-${KEYBOARD_LAYOUT}.conf
	  
	chmod 644 /usr/local/etc/X11/xorg.conf.d/keyboard-${KEYBOARD_LAYOUT}.conf
}


# ---------- patch Matcha-sea theme used for lightdm lockscreen --------------- 
patch_lockscreen_theme () {
	
	# Variables
	local FILE="/usr/local/share/themes/Matcha-sea/gtk-3.0/gtk.css"
	
	if [ -f $FILE ]; then   # gtk.css exists?
        # patch background color in #buttonbox_frame rule set

		##buttonbox_frame {
		#  padding-top: 20px;
		#  padding-bottom: 0px;
		#  border-style: none;
		#  background-color: rgba(37, 45, 48, 0.95);
		#  border-bottom-left-radius: 3px;
		#  border-bottom-right-radius: 3px;
		#  border: solid rgba(0, 0, 0, 0.1);
		#  border-width: 0 1px 1px 1px;
		#  box-shadow: inset 0 1px rgba(37, 45, 48, 0.95);
		#}		
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Patching ${COLOR_CYAN}${FILE}${COLOR_NC}...\n"
        sed -i .bak "s/background-color: rgba(37, 45, 48, 0.95);/background-color: rgba(0, 35, 44, 0.95);/" $FILE
    else
        printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
   fi
}


## ----------------------------------------------------------------------------
## ----------------------------------- Main -----------------------------------
## ----------------------------------------------------------------------------

check_if_root
display_system_info
check_network
check_pkg_activation
freebsd_update
install_pkg
# -------------------------------- Switching from quarterly to latest?  ------   
if (yes_no "\nSwitch from ${COLOR_CYAN}quarterly${COLOR_NC} to the ${COLOR_CYAN}latest${COLOR_NC} repository (use latest versions of FreeBSD packages)? " NO); then
	switch_to_latest_repository
fi

add_login_class
# Set login class
if !(set_login_class_all); then  # for all users
   set_login_class				 # selection of users
fi


# -----------------------------------------------------------------------------
# ------------------ Installation of software packages ------------------------
# -----------------------------------------------------------------------------


printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Select applications you would like to install:\n"
#  ----------------------------------- editor ---------------------------------
yes_no "\nInstall Vim (Improved version of the vi editor)?"
INSTALL_EDITOR=$?


#  ----------------------------------- grafik ---------------------------------
yes_no "Install Gimp (Free & Open Source Image Editor)?"
INSTALL_GIMP=$?


#  ----------------------------------- internet & cloud -----------------------
yes_no "Install Chromium (Chrome web browser)?"
INSTALL_CHROMIUM=$?


#  ----------------------------------- mulitmedia -----------------------------
## ----------------------------------- software to be installed ---------------
yes_no "Install Video & Audio players (Audacious, mpv, VLC, Ristretto, Shotweel)?"
INSTALL_AUDIOPLAYER=$?
INSTALL_MPV=$?
INSTALL_VLC=$?
INSTALL_IMAGEVIEWER=$? 
INSTALL_SHOTWELL=$?


#  ----------------------------------- office & mail --------------------------
yes_no "Install LibreOffice and Mailsprint (LibreOffice, Thunderbird, CUPS, SANE)?"
INSTALL_OFFICE=$?
INSTALL_MAIL=$?
INSTALL_CUPS=$?
INSTALL_SANE=$?


#  ----------------------------------- security -------------------------------
yes_no "Install KeePass (easy-to-use password manager)?"
INSTALL_KEEPASS=$?

# ------------------------------------ start installation ---------------------
printf "\n[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Last change to cancel the installation!\n"    
if !(yes_no "Is everything above correct? Start installation now?" NO); then
	printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Aborting installation!\n"
	exit 3
fi


## ------------------------------- install xorg, x11-fonts, set keyboard ------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XORG${COLOR_NC}...\n"
install_packages xorg
install_fonts
set_xkeyboard


# ------------------------- add users to group video for accelerated video ---- 
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Add users to the ${COLOR_CYAN}video${COLOR_NC} group\n"
for i in `awk -F: '($3 >= 1001) && ($3 != 65534) { print $1 }' /etc/passwd`; 
		do 
			pw groupmod video -m $i  2>&1
		done
pw groupshow video | awk -v nc=$COLOR_NC -v cyan=$COLOR_CYAN  -v green=$COLOR_GREEN -F: '{printf "[ "green "INFO" nc " ]  Group: "cyan $1 nc"\tGID: " cyan $3 nc "\tMembers: " cyan $4 nc"\n"}'


# --------------------------- update rc.conf ----------------------------------
# --------------- start moused daemon to support mouse operation in X11 -------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n" 
sysrc moused_enable="YES"

# ------------------------------------ install X11 video driver ---------------
# --------------------- only nvidea and VMWare video drivers are supportet ----
check_vga_card # check which video driver required
VGA_CARD=$?

# ------------------------------------ install X11 video driver ---------------
case $VGA_CARD in
	1) 
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}VMWare display driver${COLOR_NC} and ${COLOR_CYAN}Open VMWare tools${COLOR_NC} ...\n"
		# pkg install -y xf86-video-vmware open-vm-tools
		install_packages xf86-video-vmware open-vm-tools
		

		# --------------------------- update rc.conf, add VMWare tools --------
		# vmemctl is driver for memory ballooning
		# vmxnet is paravirtualized network driver
		# vmhgfs is the driver that allows the shared files feature of VMware Workstation and other products that use it
		# vmblock is block filesystem driver to provide drag-and-drop functionality from the remote console
		# VMware Guest Daemon (guestd) is the daemon for controlling communication between the guest and the host including time synchronization		
		
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n"
		sysrc vmware_guest_vmblock_enable="YES" vmware_guest_vmhgfs_enable="YES" vmware_guest_vmmemctl_enable="YES" vmware_guest_vmxnet_enable="YES" vmware_guestd_enable="YES";;
				
	2) 	
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}nvidia display driver (X64)${COLOR_NC} ...\n"
		# pkg install -y nvidia-driver
		# pkg install -y nvidia-settings
		# pkg install -y nvidia-xconfig
		install_packages nvidia-driver nvidia-settings nvidia-xconfig
		
		
		# run nvidia autoconfig
		nvidia-xconfig
		
		# ---- update rc.conf,nvidia drivers - to load the kernel modules at boot ---
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n"
		#sysrc linux_enable="YES"			
		sysrc kld_list+="nvidia-modeset linux"
		
		# --- nvidia drivers has been build with Linux compatibility support --------
		# therefore the linux.ko module is needed and can be loaded via 
		# /boot/loader.conf, or later in the boot process if you add linux_enable="YES" to your /etc/rc.conf.
		sysrc linux_enable="YES";;
			 
	*) printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] Only NVIDEA graphics cards or installation on VMWare is supportet!\n";;
	  
esac

# ------------------------- install xfce4, lightdm, xdg-user-dirs -------------
# -----------------------------------------------------------------------------

printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XFCE Desktop Environment with LightDM GTK+ Gretter.${COLOR_NC}...\n"
# pkg install -y xfce lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
install_packages xfce lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings


# ------------------------------------ update rc.conf -------------------------
# ------------------------------------ start lightdm --------------------------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n" 
#
sysrc lightdm_enable="YES"

printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing  ${COLOR_CYAN}XDG user directories${COLOR_NC}...\n"
#pkg install xdg-user-dirs
install_packages xdg-user-dirs


# ------------------------------------ install xfce panel plugins -------------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Whiskermenu${COLOR_NC} for Xfce Desktop Environment.\n"
# pkg install -y xfce4-whiskermenu-plugin
install_packages xfce4-whiskermenu-plugin


# ------------------------------------ install Matcha and Arc themes ---------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XFCE GTK themes: Matcha and Arc${COLOR_NC}...\n"
# pkg install -y matcha-gtk-themes gtk-arc-themes
install_packages matcha-gtk-themes gtk-arc-themes


# ------------------------------------ install Papirus icons -------------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Papirus icons${COLOR_NC}...\n"
# pkg install -y papirus-icon-theme
install_packages papirus-icon-theme


# ------------------------------------- update rc.conf, enable dbus -----------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n" 
# xfce uses D-Bus for a message bus and must ve enable it in /etc/rc.conf so it will be started when the system boots
sysrc dbus_enable="YES"


# ----------------------- Setup Users and Desktop Environment -----------------
# -----------------------------------------------------------------------------
# ---------------------------- create skel templates - /usr/share/skel  -------

set_skel_template () {
	# Start Xfce from the command line by typing startx 
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create default configuration files in ${COLOR_CYAN}/usr/share/skel/dot.xinitrc${COLOR_NC} in order to start Xfce from the command line\n"
		echo ". /usr/local/etc/xdg/xfce4/xinitrc" > /usr/share/skel/dot.xinitrc
	
	# populate	users with the content of the skeleton directory - /usr/share/skel/dot.xinitrc
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create ${COLOR_CYAN}~/.xinitrc${COLOR_NC} in users home directory in order to start Xfce from the command line by typing startx.\n"
	for i in `awk -F: '($3 >= 1001) && ($3 != 65534) { print $1 }' /etc/passwd`; 
		do 
			pw usermod -m -n $i  2>&1
			ls -laFo /home/$i | grep .xinitrc
		done
}
set_skel_template

# ----------------------- Config and tweaks for lightdm ---------------------------
set_lightdm_greeter () {

    # Variables
	local FILE
	local BACKGROUND="/usr/local/share/backgrounds/FreeBSD-lockscreen_v2-blue.png"
	local USER_BACKGROUND="false"
	local THEME="Matcha-sea"
	local FONT="Ubuntu Bold 11"
	local INDICATORS="~host;~spacer;~clock;~spacer;~session;~a11y;~language;~power"
	local CLOCK="%A, %d. %B %Y     %H:%M"
	local POSITION="25%,center 45%,center"
	local SCREENSAVER="60"
	local XRANDR
	
	
	# lightdm-gtk-greeter.desktop
	FILE="/usr/local/share/xgreeters/lightdm-gtk-greeter.desktop"
	
	if [ -f $FILE ]; then	# lightdm-gtk-greeter.desktop exists?
	    # Change language for lightdm's login screen 
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  lightdm-gtk-greeter.desktop: Set language to ${COLOR_CYAN}${LOCALE}${COLOR_NC}\n"
		sed -i .bak "s/Exec=lightdm-gtk-greeter/Exec=env LANG=$LOCALE lightdm-gtk-greeter/" $FILE
		cat $FILE; echo""
	else
		printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$FILE"${COLOR_NC} does not exist!\n"
	fi	
	rm ${FILE}.bak # Delete backup file
	
	
	# ----------------------------- lightdm.conf ------------------------------
	
	# Set Screen size for lightdm when using VMware
	# Syntax: e.g. display-setup-script=xrandr --output default --primary --mode 2560x1440 --rate 60
	case $VGA_CARD in
		1) 	XRANDR="display-setup-script=xrandr --output default --mode $SCREEN_SIZE";;
		2) 	XRANDR="xdisplay-setup-script=";;
		*) 	printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] Only NVIDEA graphics cards or installation on VMWare is supportet!\n"
			exit 1;;
	esac

	FILE="/usr/local/etc/lightdm/lightdm.conf"
	if [ -f $FILE ]; then	# lightdm.conf exists?
	    # Set greeter-setup-script=setxkbmap  -layout de to start xfce session in German
		# Set display-setup-script=xrandr --output default --mode 2560x1440
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  lightdm.conf: Set ${COLOR_CYAN}greeter-setup-script=setxkbmap  -layout ${KEYBOARD_LAYOUT}${COLOR_NC}\n"
		if [ "$VGA_CARD" -eq 1 ]; then
			printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  lightdm.conf: Set ${COLOR_CYAN}${XRANDR}${COLOR_NC}\n"
		fi
		echo""
		sed -i .bak -e "s/#greeter-setup-script=.*/greeter-setup-script=setxkbmap  -layout $KEYBOARD_LAYOUT/" \
					-e "s/#display-setup-script=.*/$XRANDR/" $FILE
		
		sed -n "/^\[Seat/,/#exit-on-failure/p" $FILE               # Print [Seat:*] section
	else
		printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$FILE"${COLOR_NC} does not exist!\n"
	fi	
	rm ${FILE}.bak # Delete backup file
	
	
    # ligtdm-gtk-greeter.conf
    FILE="/usr/local/etc/lightdm/lightdm-gtk-greeter.conf"

	if [ -f $FILE ]; then   # lightdm-gtk-greeter.conf exists?
        # tweak lightdm-gtk-greeter configuration
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Updating LightDM GTK+ Greeter configuration...\n"
            
		# use delimiter ':' instead of '/'
        sed -i .bak -e "s:#background=.*:background=$BACKGROUND:"                       \
                    -e "s:#user-background=.*:user-background=$USER_BACKGROUND:"        \
                    -e "s:#theme-name=.*:theme-name=$THEME:"                            \
                    -e "s:#font-name=.*:font-name=$FONT:"                               \
                    -e "s:#indicators=.*:indicators=$INDICATORS:"                       \
                    -e "s/#clock-format=.*/clock-format=$CLOCK/"                        \
                    -e "s:#position=.*:position=$POSITION:"                             \
                    -e "s:#screensaver-timeout=.*:#screensaver-timeout=$SCREENSAVER:" $FILE

        sed -n '/\[greeter\]/,$p' $FILE                 # Print [greeter] section
    else
        printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
    fi

   rm ${FILE}.bak # Delete backup file
   
   # ---------- patch Matcha-sea theme used in lockscreen --------------- 
   patch_lockscreen_theme
   
   # fetch FreeBSD locksceens for lightdm
   DIR="/usr/local/share/backgrounds/"				# Xfce background folder
   
	if [ -d $DIR ]; then
		cd /usr/local/share/backgrounds/
		
		
		# ------------ fetch does not work in privat github repository -------- 
		
		#fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v1-blue.png
		#chmod 644 FreeBSD-lockscreen_v1-blue.png
		#fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v1-red.png
		#chmod 644 FreeBSD-lockscreen_v1-red.png
		
		#fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v2-blue.png
		#chmod 644 FreeBSD-lockscreen_v2-blue.png
		#fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v2-red.png
		#chmod 644 FreeBSD-lockscreen_v2-red.png
		
		#fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v3-blue.png
		#chmod 644 FreeBSD-lockscreen_v3-blue.png
		#fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v3-red.png
		#chmod 644 FreeBSD-lockscreen_v3-red.png
		
				
		# ----------- user curl instead of fetch ------------------------------
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/FreeBSD-lockscreen_v1-blue.png${COLOR_NC} from gitgub...\n"
		curl -s -O https://ca49b3326d738856a8bbbfbe11b93f30675f6071@raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v1-blue.png
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/FreeBSD-lockscreen_v1-red.png${COLOR_NC} from gitgub...\n"
		curl -s -O https://ca49b3326d738856a8bbbfbe11b93f30675f6071@raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v1-red.png
		
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/FreeBSD-lockscreen_v2-blue.png${COLOR_NC} from gitgub...\n"
		curl -s -O https://ca49b3326d738856a8bbbfbe11b93f30675f6071@raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v2-blue.png
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/FreeBSD-lockscreen_v2-red.png${COLOR_NC} from gitgub...\n"
		curl -s -O https://ca49b3326d738856a8bbbfbe11b93f30675f6071@raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v2-red.png
		
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/FreeBSD-lockscreen_v3-blue.png${COLOR_NC} from gitgub...\n"
		curl -s -O https://ca49b3326d738856a8bbbfbe11b93f30675f6071@raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v3-blue.png
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/FreeBSD-lockscreen_v3-red.png${COLOR_NC} from gitgub...\n"
		curl -s -O https://ca49b3326d738856a8bbbfbe11b93f30675f6071@raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v3-red.png	
		
	else
		printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$DIR"${COLOR_NC} does not exist!\n"
	fi	
}
set_lightdm_greeter


# ------------------------------ install applications--------------------------
# -----------------------------------------------------------------------------

install_editors () {
	if [ "$INSTALL_EDITOR" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Vim${COLOR_NC}...\n"
		install_packages vim
	fi
}
install_editors


install_gimp () {
	if [ "$INSTALL_GIMP" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Gimp${COLOR_NC}...\n"
		install_packages gimp
	fi
}
install_gimp


install_chromium () {
	if [ "$INSTALL_CHROMIUM" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Chromium${COLOR_NC}...\n"
		install_packages chromium
	fi
}
install_chromium


install_multimedia () {
	if [ "$INSTALL_AUDIOPLAYER" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Audacious${COLOR_NC}...\n"
		install_packages audacious
	fi
	
	if [ "$INSTALL_MPV" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}mvp${COLOR_NC}...\n"
		install_packages mpv
	fi

	if [ "$INSTALL_IMAGEVIEWER" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Ristretto${COLOR_NC}...\n"
		install_packages ristretto 
	fi


	if [ "$INSTALL_SHOTWELL" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Shotwell${COLOR_NC}...\n"
		install_packages shotwell
	fi

	if [ "$INSTALL_VLC" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}VLC${COLOR_NC}...\n"
		install_packages vlc
	fi
}
install_multimedia


install_office () {
	if [ "$INSTALL_OFFICE" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Libre Office${COLOR_NC}...\n"
		install_packages libreoffice
	fi
}
install_office

#INSTALL_CUPS=$?
#INSTALL_SANE$?


install_mail () {
	if [ "$INSTALL_MAIL" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Thunderbird${COLOR_NC}...\n"
		install_packages thunderbird
	fi
}
install_mail


install_keepass () {
	if [ "$INSTALL_KEEPASS" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Keepass${COLOR_NC}...\n"
		install_packages keepass
	fi
}
install_keepass


# ------------------------------------ utilities ------------------------------
install_utilities () {
	if [ "$INSTALL_CATFISH" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Catfish${COLOR_NC}...\n"
		install_packages catfish
	fi
	if [ "$INSTALL_OCTOPKG" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}OctpPkg${COLOR_NC}...\n"
		install_packages octopkg
	fi
	
	if [ "$INSTALL_NEOFETCH" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Neofetch${COLOR_NC}...\n"
		install_packages neofetch
	fi

	if [ "$INSTALL_SYSINFO" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Sysinfo${COLOR_NC}...\n"
		install_packages sysinfo
	fi

	if [ "$INSTALL_HTOP" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Htop${COLOR_NC}...\n"
		install_packages htop
	fi

}
install_utilities


# ------------------------------------ Reboot FreeBSD --------------------------
## -----------------------------------------------------------------------------

printf "\n[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  ${COLOR_CYAN}Update is completed. Please reboot FreeBSD!${COLOR_NC}\n"
if !(yes_no "Reboot FreeBSD now?" NO); then
	printf "\n[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Installation is completed - System must be rebooted!\n"
else
	 shutdown -r +10s "FreeBSD will reboot!"
fi

# ----------------------------------End of file--------------------------------
# -----------------------------------------------------------------------------
