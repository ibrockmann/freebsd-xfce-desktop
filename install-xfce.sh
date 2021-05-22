#!/bin/sh

#============================================================================
# Install Xfce 4.16 Desktop on FreeBSD 12.2, 13.0
# by ibrockmann, Version: 1.0
# 
# Notes: Installation of Xfce 4.16 Desktop Environment with Matcha and 
#  Arc GTK Themes on FreeBSD 13.0
#
# Display driver: Script supports onyl current nvidia (440.xx series) and VMware
#  display driver
# When using VMware, Screen size variable muste be set to your needs.
# Default: 2560x1440
#
# Applications: Audacious, Catfish, doas, Glances, GNOME Archive manager,
# Firefox, Gimp, htop, KeePassXC, LibreOffice, lynis, mpv, neofetch, OctoPkg,
# Ristretto, rkhunter, Shotweel, sysinfo, Thunderbird, VIM, VLC.
#
# Language and country code is set to German. It can be changed to your need in
# User defined variables section.
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

#ipfw  Firewall
FIREWALL_MYSERVICES='22/tcp'				# list of services, separated by spaces, that should be accessible on your pc  
FIREWALL_ALLOWSERVICE='192.168.178.0/24'	# List of IPs which has access to clients that should be allowed to access the provided services. Use keyword "any" instead of IP range when any clients should access these services

# Delay in seconds before autobooting FreeBSD
AUTOBOOTDELAY='5'				


# ---------------------------------- utilities -------------------------------
# ---- 1 - utility will be installed ---- 0 - utility will NOT be installed --

INSTALL_CATFISH=1				# Catfish is a GTK based search utility
INSTALL_DOAS=1					# Simple sudo alternative to run commands as another user
INSTALL_GLANCES=1				# Glances is a cross-platform monitoring tool
INSTALL_HTOP=1					# Better top - interactive process viewer
INSTALL_FILE_ROLLER=1			# GNOME Archive manager (file-roller) for zip files, tar, etc
INSTALL_LYNIS=1					# Security auditing and hardening tool, for UNIX-based systems
INSTALL_NEOFETCH=1				# Fast, highly customizable system info script
INSTALL_OCTOPKG=1				# Graphical front-end to the FreeBSD pkg-ng package manager
INSTALL_RKHUNTER=1				# Rootkit detection tool
INSTALL_SYSINFO=1				# Utility used to gather system configuration information

INSTALL_CPU_MICROCODE_UPDATES=0	# Install Intel and AMD CPUs microcode updates and load updates automatically on a FreeBSD system startup
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


# ------------------------------------ greeting -------------------------------
install_xfce_greeter () {
clear
printf "${COLOR_CYAN}Installation of Xfce Desktop Environment for FreeBSD 13.0${COLOR_NC}\n\n"
printf "This script will install pkg, X11 and the Xfce Desktop Environment with Matcha and\n"
printf "Arc GTK Themes.\n" 
printf "Additionally some basic applications will be installed: Audacious, Catfish, doas,\n"
printf "Firefox, Glances, GNOME Archive manager, Gimp, htop, KeePassXC, LibreOffice, lynis,\n"
printf "mpv, neofetch, OctoPkg, Ristretto, rkhunter, Shotweel, Sysinfo, Thunderbird\n"
printf "Vim, VLC.\n" 
printf "Install script supports current nvidia FreeBSD (X64) and VMware display drivers.\n"
printf "When using VMware, Screen size variable muste be set to your needs. Default: 2560x1440\n"
printf "Language and country code is set to German.\n"
printf "It can be changed to your need in the 'User defined environment variables' section.\n"
printf "\nIf you made a mistake answering the questions, you can quit out of the installer\n"
printf "by pressing ${COLOR_CYAN}CTRL+C${COLOR_NC} and then start again.\n\n"
}


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


# ------------------------------------ set umask ----------------------------
set_umask () {
	FILE="/etc/login.conf"
	if [ -f $FILE ]; then # login.conf exists?
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set ${COLOR_CYAN}umask=027${COLOR_NC} as default umask\n"
			
		# sed script to change ":umask=022:" to ":umask=027:" only on the first occurrence
		sed -i .bak -e '1{x;s/^/first/;x;}' \
			-e '1,/:umask=022:/{x;/first/s///;x;s/:umask=022:/:umask=027:/;}'  $FILE
		
		cap_mkdb $FILE
		rm ${FILE}.bak # Delete backup file
	else
        printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
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


# ------------------------------------ yes or no question ---------------------
yes_no () {
    # if the expression is true, test or [...] returns the exit-status 0 (true or successful) 
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


# ------------------------------------ switch  repository branch and update pkg ----------------------------
switch_to_latest_repository () {	
	mkdir -p /usr/local/etc/pkg/repos
	cp /etc/pkg/FreeBSD.conf /usr/local/etc/pkg/repos/FreeBSD.conf

	sed -i .bak 's/quarterly/latest/' /usr/local/etc/pkg/repos/FreeBSD.conf
	rm /usr/local/etc/pkg/repos/FreeBSD.conf.bak

	if pkg update -f ; then
		# pkg update successfully completeted
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Switched from {COLOR_CYAN}quarterly{COLOR_NC} to the {COLOR_CYAN}latest${COLOR_NC} pkg repository branch"
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  PKG update failed\n"
		exit 1
	fi
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
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Added ${COLOR_CYAN}${ACCOUNT}${COLOR_NC} language settings to ${COLOR_CYAN}/etc/login.conf${COLOR_NC}"
	fi
}


# ------------------------------------ set login class for ALL users ----
set_login_class_all () {
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  The default language (language code, country code, and encoding) is currently set to ${COLOR_CYAN}US${COLOR_NC} (US English).\n\n"
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


# ------------------------------------ install a package from the reposity catalogues ----
install_packages() {
for PACKAGENAME in $*
do
		if pkg search -L name $PACKAGENAME | cut -w -f1 | grep -x -q $PACKAGENAME; then #Check if FreeBSd package vorhanden
			pkg install -y $PACKAGENAME
			#pkg install $PACKAGENAME
		else
			printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] pkg: No packages available to install matching ${COLOR_CYAN}"$PACKAGENAME"${COLOR_NC}!\n"
	fi
done
}


# ------------------------------------ x11-fonts-------------------------------
install_fonts () {
local FONTS
# ------------------------------------ basic fonts ----------------------------
#x11-fonts/bitstream-vera			#Supports fully hinting, which improves the display on computer monitors.
#x11-fonts/cantarell-fonts			#Cantarell, a Humanist sans-serif font family
#x11-fonts/croscorefonts-fonts-ttf	#Google font for ChromeOS to replace MS TTF
#x11-fonts/dejavu					#will be installed with xorg
#x11-fonts/noto-basic				#Google Noto Fonts family (Basic)
#x11-fonts/noto-emoji				#Google Noto Fonts family (Emoji)
#x11-fonts/urwfonts					#URW font collection for X
#x11-fonts/webfonts					#TrueType core fonts for the Web
#x11-fonts/liberation-fonts-ttf 	#Liberation fonts from Red Hat to replace MS TTF fonts


# ------------------------------------ terminal & editor fonts-----------------
#x11-fonts/anonymous-pro			#Fixed width sans designed especially for coders
#x11-fonts/firacode					#Monospaced font with programming ligatures derived from Fira
#x11-hack/hack-font					#Monospaced font designed to be a workhorse typeface for code
#x11-fonts/inconsolata-ttf			#Attractive font for programming
#x11-fonts/sourcecodepro-ttf		#Set of fonts by Adobe designed for coders

FONTS="anonymous-pro bitstream-vera cantarell-fonts croscorefonts firacode hack-font inconsolata-ttf liberation-fonts-ttf noto-basic noto-emoji sourcecodepro-ttf urwfonts webfonts"
for font in  $FONTS; do
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing font: ${COLOR_CYAN}$font${COLOR_NC}\n"
	install_packages $font
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
					vendor=`echo $line | grep '^vendor' | cut -d'=' -f2`
					i=$(( $i - 1 ))
					case $vendor in
						"'VMware'") return 1;; # X11 VMWARE video driver
						"'NVIDIA Corporation'") return 2;; # X11 NVIDEA video-driver
						'') ;;	 
						*) return 5 ;;	# This video card is not supportet 
					esac
			fi
        done
}



# ------------------------------------ install X11 video driver ---------------
# --------------------- only nvidea and VMWare video drivers are supportet ----
install_video_driver () {

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
		sysrc kld_list+="nvidia-modeset"
		
		# --- nvidia drivers has been build with Linux compatibility support --------
		# therefore the linux.ko module is needed and can be loaded via 
		# /boot/loader.conf, or later in the boot process if you add linux_enable="YES" to your /etc/rc.conf.
		sysrc linux_enable="YES";;
			 
	*) printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] Only NVIDEA graphics cards or installation on VMWare is supportet!\n"
	exit 1;;
	  
esac
}


# ---------- fetch wallpaper wallpaper for Xfce --------------- 
fetch_wallpaper () {
	
	# Variables
	local DIR="/usr/local/share/backgrounds/"				# Xfce background folder
	if [ -d $DIR ]; then
		cd /usr/local/share/backgrounds/
			
		# --------------------- fetch favorite wallpaper ----------------------
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/Mountain_1920x1080.jpg${COLOR_NC} from gitgub...\n"
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/Mount_Fitz_Roy_1920x1080.jpg
			
	else
		printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$DIR"${COLOR_NC} does not exist!\n"
	fi	
}


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


# ---------- patch Matcha-sea theme used for lightdm lockscreen --------------- 
patch_lockscreen_theme () {
	
	# Variables
	local FILE="/usr/local/share/themes/Matcha-sea/gtk-3.0/gtk.css"
	
	if [ -f $FILE ]; then   # gtk.css exists?
        # patch background color in #buttonbox_frame rule set

		## {
		#  padding-top: 20px;
		#  padding-bottom: 0px;
		#  border-style: none;
		#  background-color: rgba(27, 34, 36, 0.95); --> rgba(0, 35, 44, 0.95);
		#  border-bottom-left-radius: 3px;
		#  border-bottom-right-radius: 3px;
		#  border: solid rgba(0, 0, 0, 0.1);
		#  border-width: 0 1px 1px 1px;
		#  box-shadow: inset 0 1px rgba(37, 45, 48, 0.95);
		#}		
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Patching ${COLOR_CYAN}${FILE}${COLOR_NC}...\n"
       
	    # sed '/Beginn/,/Ende/ s/alt/NEU/' inputfile
		sed -i .bak '/#buttonbox_frame {/,/}/ s/background-color:.*/background-color: rgba(0, 35, 44, 0.95);/' $FILE
	   
	   
	    ##buttonbox_frame button {
		#color: #c6cdcb;
		#border-color: rgba(0, 0, 0, 0.95);
		#background-color: rgba(34, 42, 45, 0.95); --> rgba(198, 208,203, 0.1);
		#}
		sed -i .bak '/buttonbox_frame button {/,/}/ s/background-color:.*/background-color: rgba(198, 208,203, 0.1);/' $FILE
		

		##buttonbox_frame button:hover {
		#color: #c6cdcb;
		#border-color: rgba(0, 0, 0, 0.95);
		#background-color: rgba(198, 205, 203, 0.1); --> background-color: rgba(86, 106, 111, 0.42);
		#}
	   	sed -i .bak '/buttonbox_frame button:hover {/,/}/ s/background-color:.*/background-color: rgba(86, 106, 111, 0.42);/' $FILE
    
    else
        printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
   fi
}


# ----------------------- Config and tweaks for lightdm ---------------------------
set_lightdm_greeter () {

    # Variables
	local FILE
	local XFILE
	local BACKGROUND="/usr/local/share/backgrounds/FreeBSD-lockscreen_v2-blue.png"
	local USER_DEFAULT_IMAGE="/usr/local/share/icons/hicolor/128x128/apps/xfce4-logo.png"
	local USER_BACKGROUND="false"
	local THEME="Matcha-sea"
	local FONT="Cantarell Bold 12"
	local INDICATORS="~host;~spacer;~clock;~spacer;~session;~a11y;~language;~power"
	local CLOCK="%A, %d. %B %Y     %H:%M"
	local POSITION="25%,center 45%,center"
	local USER_DEFAULT_IMAGE="/usr/local/share/icons/hicolor/128x128/apps/xfce4-logo.png"
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
	XFILE=`basename $FILE .conf`
	
	if [ -f $FILE ]; then   # lightdm-gtk-greeter.conf exists?
        # tweak lightdm-gtk-greeter configuration
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Updating LightDM GTK+ Greeter configuration...\n"
        
		# if #default-user-image= does not exists, insert default-user-image parameter before line with #screensaver-timeout=
		if ! grep -q 'default-user-image=' $FILE; then
			awk '{if (match($0, "#screensaver-timeout=")>0){print "#default-user-image=\n"$0}else{print $0}}' $FILE > $XFILE.bak
			mv $XFILE.bak $FILE
		fi
		
		
		# use delimiter ':' instead of '/'
        sed -i .bak -e "s:#background=.*:background=$BACKGROUND:"                       	\
                    -e "s:#user-background=.*:user-background=$USER_BACKGROUND:"        	\
                    -e "s:#theme-name=.*:theme-name=$THEME:"                            	\
                    -e "s:#font-name=.*:font-name=$FONT:"                               	\
                    -e "s:#indicators=.*:indicators=$INDICATORS:"                       	\
                    -e "s/#clock-format=.*/clock-format=$CLOCK/"                        	\
                    -e "s:#position=.*:position=$POSITION:"                             	\
					-e "s:#default-user-image=.*:default-user-image=$USER_DEFAULT_IMAGE:"	\
                    -e "s:#screensaver-timeout=.*:#screensaver-timeout=$SCREENSAVER:" $FILE
							
        sed -n '/\[greeter\]/,$p' $FILE                 # Print [greeter] section
		rm ${FILE}.bak # Delete backup file
    else
        printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
    fi

   
   # ---------- patch Matcha-sea theme used in lockscreen --------------- 
   patch_lockscreen_theme
   
   # fetch FreeBSD locksceens for lightdm
   DIR="/usr/local/share/backgrounds/"				# Xfce background folder
   
	if [ -d $DIR ]; then
		cd /usr/local/share/backgrounds/
		
		
		# ------------------- fetch lock screen wallpapers --------------------
		
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v1-blue.png
		chmod 644 FreeBSD-lockscreen_v1-blue.png
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v1-red.png
		chmod 644 FreeBSD-lockscreen_v1-red.png
		
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v2-blue.png
		chmod 644 FreeBSD-lockscreen_v2-blue.png
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v2-red.png
		chmod 644 FreeBSD-lockscreen_v2-red.png
		
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v3-blue.png
		chmod 644 FreeBSD-lockscreen_v3-blue.png
		fetch --no-verify-peer https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/main/wallpaper/FreeBSD-lockscreen_v3-red.png
		chmod 644 FreeBSD-lockscreen_v3-red.png
		
				
	
		
	else
		printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$DIR"${COLOR_NC} does not exist!\n"
	fi	
}


# ----------------------- Post installation functions ----------------------------
# --------------------------------------------------------------------------------

# --------------------------- FreeBSD update ----------------------------------
daily_check_for_updates () {
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Add crontab file to check for updates daily...\n"
	echo "# /etc/cron.d/system_update - crontab file to automatically check for updates daily
#
#
SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
## Daily check for FreeBSd updates and packages
## minute (0-59) or interval,
# |     hour (0-23),
# |     |       day of the month (1-31),
# |     |       |       month of the year (1-12),
# |     |       |       |       day of the week (0-6 with 0=Sunday).
# |     |       |       |       |    who   commands
#

@daily	root	freebsd-update cron
@daily 	root	pkg update -f > /dev/null && pkg version -vURL="  > /etc/cron.d/system_update

chmod 640 /etc/cron.d/system_update
}


# -------------------------------------- Firewall -----------------------------
enable_ipfw_firewall () {
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Enable the predefined ipfw firewall...\n"
# Enable the predefined ipfw firewall: 
sysrc firewall_enable="YES" 
sysrc firewall_quiet="YES" 				# suppress rule display
sysrc firewall_type="workstation"		# protects only this machine using stateful rules
sysrc firewall_myservices="$FIREWALL_MYSERVICES"
sysrc firewall_allowservices="$FIREWALL_ALLOWSERVICE"

# log denied packets to /var/log/security
sysrc firewall_logdeny="YES"
}



# -------------------------- FreeBSD security settings (not entirely!) --------
# --------------- (some options already offers during installation)  ----------
system_hardening () {

    FILE="/etc/sysctl.conf"

	if [ -f $FILE ]; then   # /etc/sysctl.conf exists?
        # System security hardening options
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set system security hardening options in ${COLOR_CYAN}${FILE}${COLOR_NC}...\n"
            
		# use delimiter ':' instead of '/'
        sed -i .bak -e "s:^security.bsd.see_other_gids=.*:security.bsd.see_other_gids=0:" 									\
					-e "s:^security.bsd.see_other_uids=.*:security.bsd.see_other_uids=0:" 									\
					-e "s:^security.bsd.see_jail_proc=.*:security.bsd.see_jail_proc=0:"   									\
					-e "s:^security.bsd.unprivileged_read_msgbuf=.*:security.bsd.unprivileged_read_msgbuf=0:" 				\
					-e "s:^security.bsd.unprivileged_proc_debug=.*:security.bsd.unprivileged_proc_debug=0:" 				\
					-e "s:^security.bsd.stack_guard_page=.*:security.bsd.stack_guard_page=1:" 								\
					-e "s:^security.bsd.hardlink_check_uid=.*:security.bsd.hardlink_check_uid=1:" 							\
					-e "s:^security.bsd.hardlink_check_gid=.*:security.bsd.hardlink_check_gid=1:" 							\
					-e "s:^kern.randompid=.*:kern.randompid=1:"																\
					-e "s:^kern.ipc.shm_use_phys=.*:kern.ipc.shm_use_phys=1:" 												\
					-e "s:^kern.msgbuf_show_timestamp=.*:kern.msgbuf_show_timestamp=1:" 									\
					-e "s:^hw.kbd.keymap_restrict_change=.*:hw.kbd.keymap_restrict_change=4:" 								\
					-e "s:^net.inet.icmp.drop_redirect=.*:net.inet.icmp.drop_redirect=1:" 									\
					-e "s:^net.inet6.icmp6.rediraccept=.*:net.inet6.icmp6.rediraccept=0:" 									\
					-e "s:^net.inet.ip.check_interface=.*:net.inet.ip.check_interface=1:" 									\
					-e "s:^net.inet.ip.random_id=.*:net.inet.ip.random_id=1:" 												\
					-e "s:^net.inet.ip.redirect=.*:net.inet.ip.redirect=0:" 												\
					-e "s:^net.inet6.ip6.redirect=.*:net.inet6.ip6.redirect=0:" 											\
					-e "s:^net.inet.tcp.drop_synfin=.*:net.inet.tcp.drop_synfin=1:" 										\
					-e "s:^net.inet.tcp.blackhole=.*:net.inet.tcp.blackhole=2:" 											\
					-e "s:^net.inet.udp.blackhole=.*:net.inet.udp.blackhole=1:" 											\
					-e "s:^net.inet6.ip6.use_tempaddr=.*:net.inet6.ip6.use_tempaddr=1:" 									\
					-e "s:^net.inet6.ip6.prefer_tempaddr=.*:net.inet6.ip6.prefer_tempaddr=1:" $FILE
											
											
		# append system hardening parameter at EOF, if parameter not exists 
		grep -q '^security.bsd.see_other_gids=' $FILE 			|| echo 'security.bsd.see_other_gids=0' 			>> $FILE 			# Hide processes running as other users
		grep -q '^security.bsd.see_other_uids=' $FILE 			|| echo 'security.bsd.see_other_uids=0' 			>> $FILE 			# Hide processes running as other groups 
		grep -q '^security.bsd.see_jail_proc=' $FILE 			|| echo 'security.bsd.see_jail_proc=0' 				>> $FILE 			# Hide processes running in jails
		grep -q '^security.bsd.unprivileged_read_msgbuf=' $FILE	|| echo 'security.bsd.unprivileged_read_msgbuf=0' 	>> $FILE 			# Disable reading kernel message buffer for unprivileged users
		grep -q '^security.bsd.unprivileged_proc_debug=' $FILE 	|| echo 'security.bsd.unprivileged_proc_debug=0'	>> $FILE 			# Disable process debugging facilities for unprivileged users
		grep -q '^security.bsd.stack_guard_page=' $FILE 		|| echo 'security.bsd.stack_guard_page=1'			>> $FILE 			# Additional stack protection, specifies the number of guard pages for a stack that grows
		grep -q '^security.bsd.hardlink_check_uid=' $FILE 		|| echo 'security.bsd.hardlink_check_uid=1'			>> $FILE 			# Unprivileged users are not permitted to create hard links to files not owned by them	
		grep -q '^security.bsd.hardlink_check_gid=' $FILE 		|| echo 'security.bsd.hardlink_check_gid=1'			>> $FILE 			# Unprivileged users are not permitted to create hard links to files if they are not member of file's group.
		grep -q '^kern.randompid=' $FILE 						|| echo 'kern.randompid=1' 							>> $FILE 			# Randomize the PID of newly created processes
		grep -q '^kern.ipc.shm_use_phys=' $FILE 				|| echo 'kern.ipc.shm_use_phys=1'					>> $FILE 			# Lock shared memory into RAM and prevent it from being paged out to swap (default 0, disabled)
		grep -q '^kern.msgbuf_show_timestamp=' $FILE 			|| echo 'kern.msgbuf_show_timestamp=1'				>> $FILE 			# Display timestamp in msgbuf (default 0)
		#grep -q '^hw.kbd.keymap_restrict_change=' $FILE 		|| echo 'hw.kbd.keymap_restrict_change=4'			>> $FILE 			# Disallow keymap changes for non-privileged users
		grep -q '^net.inet.icmp.drop_redirect=1' $FILE   		|| echo 'net.inet.icmp.drop_redirect=1'  			>> $FILE 			# Ignore ICMP redirects (default 0)
		grep -q '^net.inet6.icmp6.rediraccept=0' $FILE   		|| echo 'net.inet6.icmp6.rediraccept=0'  			>> $FILE 			# Ignore ICMPv6 redirect messages (default 1), 1=accept
		grep -q '^net.inet.ip.check_interface=1' $FILE   		|| echo 'net.inet.ip.check_interface=1'  			>> $FILE 			# Verify packet arrives on correct interface (default 0)
		grep -q '^net.inet.ip.random_id=1' $FILE   				|| echo 'net.inet.ip.random_id=1'        			>> $FILE 			# Assign a random IP id to each packet leaving the system (default 0)
		grep -q '^net.inet.ip.redirect=0'  $FILE   				|| echo 'net.inet.ip.redirect=0'         			>> $FILE 			# Do not send IP redirects (default 1)
		grep -q '^net.inet6.ip6.redirect=0' $FILE   			|| echo 'net.inet6.ip6.redirect=0' 	     			>> $FILE 			# Do not send IPv6 redirects (default 1)
		grep -q '^net.inet.tcp.drop_synfin=1' $FILE   			|| echo 'net.inet.tcp.drop_synfin=1'	 			>> $FILE 			# Drop TCP packets with SYN+FIN set (default 0)
		grep -q '^net.inet.tcp.blackhole=2' $FILE   			|| echo 'net.inet.tcp.blackhole=2'		 			>> $FILE 			# Don't answer on closed TCP ports(default 0)
		grep -q '^net.inet.udp.blackhole=1'	$FILE   			|| echo 'net.inet.udp.blackhole=1'		 			>> $FILE 			# Don't answer on closed UDP ports (default 0)
		grep -q '^net.inet6.ip6.use_tempaddr=1'	$FILE   		|| echo 'net.inet6.ip6.use_tempaddr=1'	 			>> $FILE 			# Enable privacy settings for IPv6 (RFC 3041)
		grep -q '^net.inet6.ip6.prefer_tempaddr=1' $FILE   		|| echo 'net.inet6.ip6.prefer_tempaddr=1'			>> $FILE 			# Prefer privacy addresses and use them over the normal addresses

	else
        printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
    fi

	rm ${FILE}.bak # delete backup file
   
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Clean the ${COLOR_CYAN}/tmp ${COLOR_NC}filesystem on system startup...\n"
	sysrc clear_tmp_enable="YES"	# Clean the /tmp filesystem on system startup
	
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Disable opening Syslogd network socket (disables remote logging)...\n"
	sysrc syslogd_flags="-ss"		# Disable opening Syslogd network socket (disables remote logging)
	
	
	# Disable sendmail service
	#printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Disable sendmail service...\n"
	#sysrc sendmail_enable="NONE"
}


install_rkhunter () {
	install_packages rkhunter
	
	FILE="/etc/periodic.conf"	# this file contains local overrides for the default periodic configuration
	
	if [ ! -f $FILE ]; then   # /etc/periodic.conf exists?
		touch $FILE
	fi
	cat <<- EOF >> $FILE
		# Keep your rkhunter database up-to-date
		daily_rkhunter_update_enable="YES"
		daily_rkhunter_update_flags="--update --nocolors"

		# Daily security check
		daily_rkhunter_check_enable="YES"
		daily_rkhunter_check_flags="--checkall --nocolors --skip-keypress"
	EOF
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ] ${COLOR_CYAN}$FILE:${COLOR_NC}\n"
	cat $FILE
}


# ------------------------------------ utilities ------------------------------
install_utilities () {
	if [ "$INSTALL_CATFISH" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Catfish${COLOR_NC}...\n"
		install_packages catfish
	fi
	
	if [ "$INSTALL_DOAS" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}doas${COLOR_NC}...\n"
		install_packages doas
	fi
	
	if [ "$INSTALL_FILE_ROLLER" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Archive manager for zip files, tar, etc${COLOR_NC}...\n"
		install_packages file-roller
	fi
	
	if [ "$INSTALL_GLANCES" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}cross-platform monitoring tool glances${COLOR_NC}...\n"
		install_packages py37-glances
	fi
		
	if [ "$INSTALL_HTOP" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Htop${COLOR_NC}...\n"
		install_packages htop
	fi
	
	if [ "$INSTALL_LYNIS" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}lynis${COLOR_NC}...\n"
		install_packages lynis
	fi
	
	if [ "$INSTALL_NEOFETCH" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Neofetch${COLOR_NC}...\n"
		install_packages neofetch
	fi
	
	if [ "$INSTALL_OCTOPKG" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}OctpPkg${COLOR_NC}...\n"
		install_packages octopkg
	fi
	
	if [ "$INSTALL_RKHUNTER" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}rkhunter${COLOR_NC}...\n"
		install_rkhunter
	fi
	
	if [ "$INSTALL_SYSINFO" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Sysinfo${COLOR_NC}...\n"
		install_packages sysinfo
	fi

}


# ------------------------ Intel and AMD CPUs microcode updates ---------------
install_cpu_microcode_updates () {
	if [ "$INSTALL_CPU_MICROCODE_UPDATES" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}devcpu-data${COLOR_NC} will allow host startup to update the CPU microcode on a FreeBSD system automatically...\n"
		install_packages devcpu-data # pkg install devcpu-data
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/boot/loader.conf${COLOR_NC} to update the CPU microcode automatically on on a FreeBSD system startup...\n"
		#loads and applies the update before the kernel begins booting
		sysrc -f /boot/loader.conf cpu_microcode_load="YES"
		sysrc -f /boot/loader.conf cpu_microcode_name="/boot/firmware/intel-ucode.bin"
	fi
}


# --------------------------- silence the boot messages -----------------------
silent_boot_messages () {
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set FreeBSD ${COLOR_CYAN}boot delay${COLOR_NC} to 5 seconds\n"
sysrc -f /boot/loader.conf autoboot_delay="$AUTOBOOTDELAY" 		# Delay in seconds before autobooting
#sysrc -f /boot/loader.conf boot_mute="YES"						# Mute the content

													# rc_startmsgs
#sysrc rc_startmsgs="NO"							# for troubleshooting issues, most boot messages can be found under:
													# dmesg 
													# (cat|tail|grep|less|more..) /var/log/messages
}


## ----------------------------------------------------------------------------
## ----------------------------------- Main -----------------------------------
## ----------------------------------------------------------------------------
install_xfce_greeter
check_if_root
display_system_info
check_network
check_pkg_activation
set_umask
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

# ----------------------------------- user interaction -----------------------
# ----------------------------------------------------------------------------

printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Select applications you would like to install:\n"
#  ----------------------------------- editor ---------------------------------
yes_no "\nInstall Vim (Improved version of the vi editor)?"
INSTALL_EDITOR=$?


#  ----------------------------------- grafik ---------------------------------
yes_no "Install Gimp (Free & Open Source Image Editor)?"
INSTALL_GIMP=$?


#  ----------------------------------- internet & cloud -----------------------
yes_no "Install Firefox (Mozilla's web browser)?"
INSTALL_BROWSER=$?


#  ----------------------------------- mulitmedia -----------------------------
## ----------------------------------- software to be installed ---------------
yes_no "Install Audio, Graphics & Video Applications (Audacious, mpv, VLC, Ristretto, Shotweel)?"
INSTALL_AUDIOPLAYER=$?
INSTALL_MPV=$?
INSTALL_VLC=$?
INSTALL_IMAGEVIEWER=$? 
INSTALL_SHOTWELL=$?


#  ----------------------------------- office & mail --------------------------
yes_no "Install LibreOffice and Thunderbird (LibreOffice, Thunderbird, CUPS)?"
INSTALL_OFFICE=$?
INSTALL_MAIL=$?
# -------------------------------- printing -----------------------------------
INSTALL_CUPS=$?				# CUPS is a standards-based, open source printing system


#  ----------------------------------- security -------------------------------
yes_no "Install KeePassXC (easy-to-use password manager)?"
INSTALL_KEEPASS=$?

#  ----------------------------------- utilities -------------------------------
yes_no "Install utilities, e.g catfish, doas, htop, file archiver lynis, etc. ?"
INSTALL_UTILITIES=$?

# ----------------------------- abort installation  ---------------------------
printf "\n[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Last change to cancel the installation!\n"    
if !(yes_no "Is everything above correct? Start installation now?" NO); then
	printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Aborting installation!\n"
	exit 3
fi

# -------------------------------- start installation -------------------------
# -----------------------------------------------------------------------------

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
install_video_driver


# ------------------------- install xfce4, lightdm, xdg-user-dirs -------------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XFCE Desktop Environment with LightDM GTK+ Gretter.${COLOR_NC}...\n"
# pkg install -y xfce lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
install_packages xfce lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

# ------------------------------------ update rc.conf -------------------------
# ------------------------------------ start lightdm --------------------------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n" 
sysrc lightdm_enable="YES"

printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing  ${COLOR_CYAN}XDG user directories${COLOR_NC}...\n"
#pkg install xdg-user-dirs
install_packages xdg-user-dirs

# ------------------------------------ install xfce panel plugins -------------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Whiskermenu${COLOR_NC} for Xfce Desktop Environment...\n"
# pkg install -y xfce4-whiskermenu-plugin
install_packages xfce4-whiskermenu-plugin
		
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Thunar Archive Plugin${COLOR_NC}...\n"
install_packages thunar-archive-plugin

printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Weather plugin for the Xfce panel${COLOR_NC}...\n"
install_packages xfce4-weather-plugin

# --------------- xfce4-mixer not supported therefore install DSNMixer --------
install_packages dsbmixer

# ------------------------------------ install Matcha and Arc themes ---------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XFCE GTK themes: Matcha and Arc${COLOR_NC}...\n"
# pkg install -y matcha-gtk-themes gtk-arc-themes
install_packages matcha-gtk-themes gtk-arc-themes


# ------------------------------------- update rc.conf, enable dbus -----------
printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC}\n" 
# xfce uses D-Bus for a message bus and must ve enable it in /etc/rc.conf so it will be started when the system boots
sysrc dbus_enable="YES"

# ---------- fetch wallpaper wallpaper for Xfce --------------- 
fetch_wallpaper


# ----------------------- Setup Users and Desktop Environment -----------------
# -----------------------------------------------------------------------------
set_skel_template
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


install_browser () {
	if [ "$INSTALL_BROWSER" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Firefox${COLOR_NC}...\n"
		install_packages firefox
	fi
}
install_browser


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


install_mail () {
	if [ "$INSTALL_MAIL" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Thunderbird${COLOR_NC}...\n"
		install_packages thunderbird
	fi
}
install_mail


# -------------------------------- printing, only network printer -----------------------------------
	if [ "$INSTALL_CUPS" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}Common UNIX Printing System (CUPS)${COLOR_NC}...\n"
		install_packages cups
		sysrc cupsd_enable="YES"
		pw usermod root -G cups
	fi


install_keepass () {
	if [ "$INSTALL_KEEPASS" -eq 0 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}KeePassXC${COLOR_NC}...\n"
		install_packages keepassxc
	fi
}
install_keepass


# ------------------------------------ utilities ------------------------------
if [ "$INSTALL_UTILITIES" -eq 0 ]; then
	install_utilities
fi



# -----------------------------------------------------------------------------
# ----------------------- Post installation tasks -----------------------------

# Daily check for FreeBSD and package updates
daily_check_for_updates

# Enable the predefined ipfw firewall
enable_ipfw_firewall

#Some FreeBSD security settings (not entirely!)
system_hardening

# ------------------------ Intel and AMD CPUs microcode updates ---------------
install_cpu_microcode_updates

# --------------------------- silence the boot messages -----------------------
silent_boot_messages 


# -------------- Specify the maximum desired resolution for the EFI	console ---
/boot/loader.conf
sysrc -f /boot/loader.conf efi_max_resolution=$SCREEN_SIZE


# ------------------------------------ reboot FreeBSD --------------------------
# -----------------------------------------------------------------------------
printf "\n[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  ${COLOR_CYAN}Update is completed. Please reboot FreeBSD!${COLOR_NC}\n"
if !(yes_no "Reboot FreeBSD now?" NO); then
	printf "\n[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Installation is completed - System must be rebooted!\n"
else
	 shutdown -r +10s "FreeBSD will reboot!"
fi

# ----------------------------------End of file--------------------------------
# -----------------------------------------------------------------------------