#!/bin/sh

#============================================================================
# Installation of a Xfce 4.20 Desktop Environment for FreeBSD 15.x
# by ibrockmann, Version: 2.1
# 
# Notes: Installation of an Xfce 4.20 Desktop Environment with Matcha and 
#  Arc GTK Themes on FreeBSD 15.x
#
# Display driver: Script supports current nvidia FreeBSD (X64) and VMware
#  display driver only
# When using VMware, Screen size variable muste be set to your needs.
# Default: 2560x1440
#
# Applications: Audacious, Catfish, Chromium, doas, Firefox, Gimp, Glances,
# GNOME Archive manager with 7-Zip, htop, KeePassXC, LibreOffice, lynis, 
# mpv, neofetch, OctoPkg, Ristretto, rkhunter, Shotweel, Syncthing, sysinfo,
# Thunderbird, VIM, VLC. 
#
# Script should be run on a fresh installed FreeBSD system.
#
#==============================================================================


# ---------------------------------- declaration of variables -----------------
# -----------------------------------------------------------------------------

# ---------------------- User defined environment variables -------------------

# Logfile  
LOGFILE=$(pwd)"/"$(basename $0 sh)"log" 

SCREEN_SIZE='2560x1440'	# Required for VMWare and used for the EFI console		

# Delay in seconds before autobooting FreeBSD
AUTOBOOTDELAY='5'	# Delay in seconds before FreeBSD will automatically boot


# Initialize values for language and country code, keyboard layout, Charset
LOCALE='de_DE.UTF-8'	# LanguageCode_CountryCode.Encoding;set default to German, Germany, UTF-8
			# A complete list can be found by typing: % locale -a  | more
			# default-item in function menubox_language	

INSTALL_CPU_MICROCODE_UPDATES=0	# Install Intel and AMD CPUs microcode updates and load updates automatically on a FreeBSD system startup
				# 0 - do not install, 1 -  install Intel and AMD  CPUs microcode updates

# -----------------------------------------------------------------------------
# --------------------- Do not change anything from here on -------------------
# -----------------------------------------------------------------------------

# environment variables

# Github Repository
GITHUB_REPOSITORY=https://raw.githubusercontent.com/ibrockmann/freebsd-xfce-desktop/bsddialog

# Default items for diaog boxes
BACKTITLE="Installation of a Xfce Desktop Environment for FreeBSD 15.x"

LANGUAGE_NAME=''			# System localization in /etc/login.conf: language_name|Account Type Description
CHARSET=''		 


KEYBOARD_LAYOUT=''			# Initialize keyboard layout, is set in function menubox_xkeyboard  
					# Keyboard layouts and other adjustable parameters are listed in man page xkeyboard-config(7).
KEYBOARD_VARIANT='default'		# Initialize keyboard variant, e.g. Dvorak, Macintosh, No dead keys		

PAGER=cat				# used by freebsd-update, instead of PAGER=less
export PAGER

# define colors
COLOR_NC='\033[0m' 			# No Color
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[1;34m'
COLOR_CYAN='\033[0;36m'


# --------------------- Define the dialog exit status codes -------------------

: "${DIALOG=bsddialog}"

: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_TIMEOUT=4}"
: "${DIALOG_ESC=5}"

: "${SIG_NONE=0}"
: "${SIG_HUP=1}"
: "${SIG_INT=2}"
: "${SIG_QUIT=3}"
: "${SIG_KILL=9}"
: "${SIG_TERM=15}"


# --------------------- IPFW firewall -------------------
FIREWALL_ENABLE="" # Not enabled by default 

# ---------------------------------- setup-tempfiles --------------------
tempfile=`(tempfile) 2>/dev/null` || tempfile=/tmp/temp.$$
input=`tempfile 2>/dev/null` || input=/tmp/input.$$
trap "rm -f $input $tempfile" 0 $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM


# ------------------------------------ Display date ---------------------------
display_date () {
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  `date` \n"
}


# ------------------------------------ preconditions --------------------------
check_if_root () {
	if [ "$(id -u)" -ne 0 ]; then
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  This script must run as ${COLOR_CYAN}root${COLOR_NC}!\n"
		printf "Installation aborted.\n"
		exit 1
	fi
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Running script ${COLOR_CYAN}$0${COLOR_NC} as root.\n"
}


check_network () {
	if nc -zw1 8.8.8.8 443 > /dev/null 2>&1 ; then # Google DNS
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Internet connection detected.\n"
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  The system is not connected to the internet!\n"
		printf "You must be online for this script to work!\n"
		exit 1
	fi
}


# ---------------------- Display system information ---------------------------
display_system_info () {
printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  OS: $(uname -mrs)\n"
}


# -------------------------- return values dialog buttons ---------------------
msg_button () {
# Report button-only, no $returntext

	case ${returncode:-0} in
		$DIALOG_OK)
		  echo "OK";;
		$DIALOG_CANCEL)
		  printf "Installation aborted!\n"
		  exit ;;
		$DIALOG_HELP)
		  echo "Help pressed.";;
		$DIALOG_EXTRA)
		  echo "Extra button pressed.";;
		$DIALOG_TIMEOUT)
		  echo "Timeout expired.";;
		$DIALOG_ERROR)
		  echo "ERROR!";;
		$DIALOG_ESC)
		  printf "Installation aborted!\n"
		  exit ;;
		*)
		  echo "Return code was $returncode";;
esac
}


yesno () {

	case ${returncode:-0} in
  		$DIALOG_OK)
    		  echo "YES";;
  	  	$DIALOG_CANCEL)
    		  echo "NO";;
  	  	$DIALOG_HELP)
    		  echo "Help pressed.";;
  	  	$DIALOG_EXTRA)
    		  echo "Extra button pressed.";;
  		$DIALOG_TIMEOUT)
    		  echo "Timeout expired.";;
  		$DIALOG_ERROR)
    		  echo "ERROR!";;
  		$DIALOG_ESC)
    		  printf "Installation aborted!\n";;
  		*)
    		echo "Return code was $returncode";;
esac
}

# ------------------------------------ Welcome message ------------------------
msgbox_welcome () {

	$DIALOG --colors --backtitle "$BACKTITLE" \
			--title "Welcome to the Xfce Desktop installer for FreeBSD" \
			--msgbox "\nThis script will install pkg, X11 and the Xfce Desktop \
Environment with Matcha and Arc GTK Themes. Additionally you have the \
choise to install some basic applications:\n  \Z4Audacious, Catfish, \
Chromium, doas, Firefox, Glances, GNOME Archive manager with 7-Zip, Gimp, \
htop, KeePassXC, LibreOffice, lynis, mpv, neofetch, OctoPkg, Ristretto, \
rkhunter, Shotweel, Syncthing, Sysinfo, Thunderbird, Vim, VLC.\Z0\n\n\
This script supports the current nvidia FreeBSD (X64) and VMware display drivers. \
When using VMware, Screen size variable muste be set to your needs.\n
Default: 2560x1440" 18 70
	
	returncode=$?
	msg_button
}


# ----------------------------------- user interaction -----------------------
# ----------------------------------------------------------------------------

menubox_language () {

	# ----- fetch a list of UTF-8 language- and country codes for FreeBSD -----
	cd /tmp
	if fetch --no-verify-peer ${GITHUB_REPOSITORY}/config/LanguageCode_CountryCode; then
		
		# NR>3: Skip first 3 lines from file
		#awk -F ';' 'NR>3 {printf "%s %s %s %s\n", "\""$1"\"", "\""$2, "|("$3")" "\"", "\"""lang="$1"\""}' /tmp/LanguageCode_CountryCode > $tempfile
		awk -F ';' 'NR>3 {printf "%s %s %s %s\n", "\""$1"\"", "\""$2, "|("$3")" "\"", "\"""lang="$1"\""}' /tmp/LanguageCode_CountryCode > $tempfile
		
		sort -k 2 $tempfile | uniq > $input # remove duplicates
		
		#$DIALOG --no-tags --item-help --backtitle "$BACKTITLE"\
		#--default-item "$LOCALE" \
		#--title "Common Language and Country Codes" \
		#--menu "
		#Please select the language you want to use with Xfce:" 20 70 15 \
		#--file $input 2> $tempfile


	    $DIALOG --backtitle "$BACKTITLE"\
		--title "Common Language and Country Codes" \
		--menu "
		Please select the language you want to use with Xfce:" 20 70 15 \
		--file $input 2> $tempfile

		returncode=$?
		msg_button
		LOCALE=`cat $tempfile`
		
		# awk search needs regular expression, you can't put /var/. Instead, use tilde: awk -v var="$var" '$0 ~ var'
		LANGUAGE_NAME=`awk -v locale="$LOCALE" -F ';' '$1~locale {print $2}' /tmp/LanguageCode_CountryCode`
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]   Unable to fetch the list of UTF-8 language- and country codes from github!\n"
		printf "Installation aborted.\n"
		exit 1
	fi
}

halt
menubox_xkeyboard () {
	
	# ---------------------------------- local variables ----------------------
	local country_code 
	
	# ----------------- fetch a list of  XKB data description files -----------

	cd /tmp
	if fetch --no-verify-peer ${GITHUB_REPOSITORY}/config/xkeyboard_layout; then
		
		# ----------------------- Keyboard layout -----------------------------
		# Select ! layout paragraph from xkeyboard_layout file
		# RS=''(Input record separator) has a special meaning to awk,
		# it splits records on blank lines; Used to print paragraph 
		
		awk -v RS='' '/! layout/ {print}'  /tmp/xkeyboard_layout > $tempfile
		awk  'NR>1 {out=$2; for(i=3;i<=NF;i++){out=out" "$i}; print $1, "\""out"\""}' $tempfile \
			| sort -d -k 2 > $input


		# Set default-item, based on Country_Code
		country_code=`echo $LOCALE | cut -d . -f1 | cut -d _ -f2`	# Country_Code
		KEYBOARD_LAYOUT=`echo $country_code | tr "[:upper:]" "[:lower:]"`

		$DIALOG --clear --backtitle "$BACKTITLE" \
		--default-item "$KEYBOARD_LAYOUT" \
		--title "Keyboard Setup" \
		--menu "
		Please select your keyboard layout:" 20 70 15 \
		--file $input 2> $tempfile
		
		returncode=$?
		msg_button 
		
		KEYBOARD_LAYOUT=`cat $tempfile`

		# ----------------------- Keyboard variant ----------------------------

		# Select keyboard variants from xkeyboard_layout file
		awk -v RS='' '/! variant/ {print}'  /tmp/xkeyboard_layout > $tempfile
		
		# Display only variants that match to keyboard layout
		grep "${KEYBOARD_LAYOUT}:" $tempfile > $input

		# Are there any keyboard variants?
		if [ -s $input ]; then
			$DIALOG --clear --defaultno --backtitle "$BACKTITLE" \
					--title "Keyboard Setup" \
        			--yesno "Use a special variant for the keyboard layout?\n\
(e.g. Dvorak, Macintosh, No dead keys, ...)" 7 50
			
			returncode=$?
			yesno
			if [ $returncode -eq $DIALOG_OK ]; then
				awk  '{out=$2; for(i=3;i<=NF;i++){out=out" "$i}; print $1, "\""out"\""}' $input > $tempfile
				
				$DIALOG --clear --backtitle "$BACKTITLE" \
					--title "Keyboard Setup" \
					--menu "
					Please select your keyboard variant:" 20 70 15 \
					--file $tempfile 2> $input
				
				returncode=$?
				if [ $returncode -eq $DIALOG_CANCEL ]; then
					menubox_xkeyboard
				fi
				msg_button
				
				KEYBOARD_VARIANT=`cat $input`
			fi
		fi
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]   Unable to fetch the list of UTF-8 language- and country codes from github!\n"
		exit 1
	fi
}


# -----------------------------------------------------------------------------
# ------------- Selection of application & utlilitie packages -----------------
# -----------------------------------------------------------------------------

checklist_applications () {

	APP_LIST=`$DIALOG --backtitle "$BACKTITLE" \
		--title "Application selection"	\
		--checklist "
Please select the packages to be installed:" 20 70 15 \
		"Audacious"	"An advanced audio player"			off \
		"Chromium" 	"Browser built by Google"                     	off \
		"Firefox" 	"Mozilla's web browser"                     	on  \
		"Gimp"     	"Free & open source image editor"           	off \
		"LibreOffice" 	"Free Office Suite"                     	on  \
		"mpv"    	"Free media player for the command line" 	off \
		"KeePassXC"	"Cross-platform password manager"		on  \
		"Ristretto"     "Image-viewer for the Xfce desktop environment" on  \
		"Shotwell"    	"Personal photo manager" 			off \
		"Syncthing"	"continuous file synchronization program"	on  \
		"Thunderbird"	"Mozilla's free email client"  	         	on  \
		"Vim"		"Improved version of the vi editor"		on  \
		"VLC"    	"Free & open source multimedia player" 		off 3>&1 1>&2 2>&3`

	returncode=$?
	msg_button
	
	# Package names are in lower cases
	APP_LIST=`echo $APP_LIST | tr "[:upper:]" "[:lower:]"`
	exec 3>&- # close file descriptor 3 
}


checklist_utilities () {

	UTILITY_LIST=`$DIALOG --clear --backtitle "$BACKTITLE" \
			--title "Utility selection"	\
			--checklist "
Please select the packages to be installed:" 20 70 15 \
			"Catfish"	"GTK based search utility"					on  \
			"doas" 		"Simple sudo alternative to run commands as another user" 	on  \
			"py311-glances" 	"Glances is a cross-platform monitoring tool"           	on  \
			"htop"     	"Better top - interactive process viewer"           		on  \
			"File-roller"	"GNOME Archive manager + 7-Zip file archiver"			on  \
			"Lynis"    	"Security auditing and hardening tool"			 	off \
			"Neofetch"     	"Fast, highly customizable system info script"			on  \
			"Octopkg"     	"Graphical front-end to the FreeBSD package manager" 		on  \
			"rkhunter"    	"Rootkit detection tool" 					off \
			"Sysinfo"   	"Utility used to gather system configuration information"  	on  3>&1 1>&2 2>&3`

	returncode=$?
	msg_button
	# Add 7-Zip package if file-roller is selected; Package names are in lower cases
	UTILITY_LIST=`echo ${UTILITY_LIST} | sed 's/File-roller/File-roller 7-zip/' | tr "[:upper:]" "[:lower:]"`
	exec 3>&- # close file descriptor 3
}


radiolist_repository_branch () {

	REPOSITORY=`$DIALOG --clear --item-help --backtitle "$BACKTITLE" \
	--title "Quarterly or latest package branches" \
	--default-item "latest" \
	--radiolist "
Would you like to use the quarterly or latest version of FreeBSD packages?" 15 50 5 \
	quarterly		""  off "More predictable and stable experience" \
	latest			""  on "Current version of FreeBSD packages" 	\
        3>&1 1>&2 2>&3`

	returncode=$?
	msg_button
	exec 3>&- # close file descriptor 3
}


# ----------------------- Summary & abort installation ------------------------
yesno_summary () {

	$DIALOG --clear --colors --backtitle "$BACKTITLE" \
	--title "Installation summary" \
	--no-label "Cancel" \
	--yesno "\nIs everything below correct? Would you like to start the installation now?\n\
Last change to cancel the installation!\n\n\
Language:   \Z4$LANGUAGE_NAME\Z0\n\
Keyboard:   \Z4$KEYBOARD_LAYOUT ($KEYBOARD_VARIANT)\Z0\n\
LANG:       \Z4$LOCALE\Z0\n\
Repository: \Z4$REPOSITORY\Z0\n\n\
Applications: \Z4$APP_LIST\Z0\n\
Utilities: \Z4$UTILITY_LIST\Z0\n\n\
Installation Logfile: \Z4$LOGFILE\Z0\n\n" 20 80
             
	returncode=$?
	msg_button
}


# -----------------------------------------------------------------------------
# ------------------------- System hardening options --------------------------
# -----------------------------------------------------------------------------

checklist_system_hardening () {

	local grep_return
	
	# read current hardening settings
	# /etc/sysctl.conf - no hardening variables set in /etc/sysctl.conf by default
	if [ `sysctl -n security.bsd.see_other_uids` -eq 1 ]; then hide_uids='off'; else hide_uids='on'; fi
	if [ `sysctl -n security.bsd.see_other_gids` -eq 1 ]; then hide_gids='off'; else hide_gids='on'; fi
	if [ `sysctl -n security.bsd.see_jail_proc` -eq 1 ]; then hide_jail='off'; else hide_jail='on'; fi
	if [ `sysctl -n security.bsd.unprivileged_read_msgbuf` -eq 1 ]; then read_msgbuf='off'; else read_msgbuf='on'; fi
	if [ `sysctl -n security.bsd.unprivileged_proc_debug` -eq 1 ]; then proc_debug='off'; else proc_debug='on'; fi
	if [ `sysctl -n security.bsd.hardlink_check_uid` -eq 0 ]; then hardlink_uid='off'; else hardlink_uid='on'; fi
	if [ `sysctl -n security.bsd.hardlink_check_gid` -eq 0 ]; then hardlink_gid='off'; else hardlink_gid='on'; fi
	if [ `sysctl -n kern.randompid` -eq 0 ]; then random_pid='off'; else random_pid='on'; fi
	if [ `sysctl -n kern.ipc.shm_use_phys` -eq 0 ]; then lock_shm='off'; else lock_shm='on'; fi
	if [ `sysctl -n kern.msgbuf_show_timestamp` -eq 0 ]; then msgbuf_timestamp='off'; else msgbuf_timestamp='on'; fi
	if [ `sysctl -n hw.kbd.keymap_restrict_change` -eq 0 ]; then keymap_restricted='off'; else keymap_restricted='on'; fi
	
	# Network
	if [ `sysctl -n net.inet.icmp.drop_redirect` -eq 0 ]; then icmp_redirects='off'; else icmp_redirects='on'; fi
	if [ `sysctl -n net.inet6.icmp6.rediraccept` -eq 1 ]; then icmp6_redimsg='off'; else icmp6_redimsg='on'; fi
	if [ `sysctl -n net.inet.ip.check_interface` -eq 0 ]; then right_interface='off'; else right_interface='on'; fi
	if [ `sysctl -n net.inet.ip.random_id` -eq 0 ]; then random_id='off'; else random_id='on'; fi
	if [ `sysctl -n net.inet.ip.redirect` -eq 1 ]; then ip_redirect='off'; else ip_redirect='on'; fi
	if [ `sysctl -n net.inet6.ip6.redirect` -eq 1 ]; then ipv6_redirect='off'; else ipv6_redirect='on'; fi
	if [ `sysctl -n net.inet.tcp.drop_synfin` -eq 0 ]; then tcp_with_synfin='off'; else tcp_with_synfin='on'; fi	
	if [ `sysctl -n net.inet.tcp.blackhole` -eq	0 ]; then tcp_blackhole='off'; else tcp_blackhole='on'; fi
	if [ `sysctl -n net.inet.udp.blackhole` -eq	0 ] ; then udp_blackhole='off'; else udp_blackhole='on'; fi
	if [ `sysctl -n net.inet6.ip6.use_tempaddr` -eq	0 ]; then use_tempaddr='off'; else use_tempaddr='on'; fi 
	if [ `sysctl -n net.inet6.ip6.prefer_tempaddr` -eq 0 ]; then prefer_privaddr='off'; else prefer_privaddr='on'; fi

	# /etc/rc.conf; defaults in /etc/defaults/rc.conf
	if [ $(sysrc -n clear_tmp_enable | tr "[:lower:]" "[:upper:]") = 'NO' ]; then clear_tmp='off'; else clear_tmp='on'; fi
	if [ `sysrc -n syslogd_flags` != '-ss' ]; then disable_syslogd='off'; else disable_syslogd='on'; fi 
	if [ `sysrc -n sendmail_enable` = 'NONE' ]; then disable_sendmail='on'; else disable_sendmail='off'; fi

	# /etc/ttys
	grep -q '^console.*off.*insecure$' /etc/ttys
	grep_return=$?
	if [ $grep_return -eq 1 ]; then secure_console='off'; else secure_console='on'; fi

	# /etc/loader.conf
	grep -q 'security.bsd.allow_destructive_dtrace=0' /boot/loader.conf
	grep_return=$?
	if [ $grep_return -eq 1 ]; then disable_ddtrace='off'; else disable_ddtrace='on'; fi


	FEATURES=`$DIALOG --backtitle "$BACKTITLE" \
    	--title "System Hardening" --nocancel --separate-output \
    	--checklist "\nPlease choose system security hardening options:" \
    	0 0 0 \
		"0 hide_uids" 		"Hide processes running as other users" ${hide_uids:-off} \
		"1 hide_gids" 		"Hide processes running as other groups" ${hide_gids:-off} \
		"2 hide_jail" 		"Hide processes running in jails" ${hide_jail:-off} \
		"3 read_msgbuf" 	"Disable reading kernel message buffer for unprivileged users" ${read_msgbuf:-off} \
		"4 proc_debug" 		"Disable process debugging facilities for unprivileged users" ${proc_debug:-off} \
		"5 hardlink_uid" 	"Unprivileged processes cannot create hard links to files owned by other users" ${hardlink_uid:-off} \
		"6 hardlink_gid" 	"Unprivileged processes cannot create hard links to files owned by other groups" ${hardlink_gid:-off} \
		"7 random_pid" 		"Randomize the PID of newly created processes" ${random_pid:-off} \
		"8 lock_shm" 		"Enable locking of shared memory pages in core" ${lock_shm:-off} \
		"9 msgbuf_timestamp"	"Show timestamp in message buffer" ${msgbuf_timestamp:-off} \
		"10 keymap_restricted" 	"Disallow keymap changes for non-privileged users" ${keymap_restricted:-off} \
		"11 clear_tmp" 		"Clean the /tmp filesystem on system startup" ${clear_tmp:-off} \
		"12 disable_syslogd" 	"Disable opening Syslogd network socket (disables remote logging)" ${disable_syslogd:-off} \
		"13 disable_sendmail" 	"Disable Sendmail service" ${disable_sendmail:-off} \
		"14 secure_console" 	"Enable console password prompt" ${secure_console:-off} \
		"15 disable_ddtrace" 	"Disallow DTrace destructive-mode" ${disable_ddtrace:-off} \
		3>&1 1>&2 2>&3`
	returncode=$?
	msg_button
	exec 3>&- # close file descriptor 3


	NETWORK_FEATURES=`$DIALOG --backtitle "$BACKTITLE" \
    	--title "System Hardening - Network security" --nocancel --separate-output \
    	--checklist "\nPlease choose system security hardening options:" \
   		0 0 0 \
		"0 icmp_redirects" 	"Ignore ICMP redirects" ${icmp_redirects:-off} \
		"1 icmp6_redimsg" 	"Ignore incoming ICMPv6 redirect messages" ${icmp6_redimsg:-off} \
		"2 right_interface" 	"Verify packet arrives on correct interface" ${right_interface:-off} \
		"3 random_id" 		"Assign a random IP id to each packet leaving the system" ${random_id:-off} \
		"4 ip_redirect" 	"Do not send IP redirects" ${ip_redirect:-off} \
		"5 ipv6_redirect" 	"Do not send IPv6 redirects" ${ip_redirect:-off} \
		"6 tcp_with_synfin" 	"Drop TCP packets with SYN+FIN set" ${tcp_with_synfin:-off} \
		"7 tcp_blackhole"	"Drop tcp packets destined for closed ports" ${tcp_blackhole:-off} \
		"8 udp_blackhole"	"Drop udp packets destined for closed sockets" ${udp_blackhole:-off} \
		"9 use_tempaddr"	"Enable IPv6 privacy extensions" ${use_tempaddr:-off} \
		"10 prefer_privaddr"	"Prefer IPv6 privacy addresses and use them over the normal addresses" ${prefer_privaddr:-off} \
		3>&1 1>&2 2>&3`
	returncode=$?
	msg_button	
	exec 3>&- # close file descriptor 3
}


# ---------------------- Adding new users  ----------------------
add_user () {

	$DIALOG --clear --backtitle "$BACKTITLE"\
			--title "Add User Accounts" \
			--defaultno \
        	--yesno "Would you like to add users to the installed system now?" 7 40
			
			returncode=$?
			yesno
			if [ $returncode -eq $DIALOG_OK ]; then
				clear; echo $BACKTITLE
				echo "============================================================"
				printf "Add Users\n\n"
				adduser
			fi
}


# -------------------------------------- IPFW Firewall -----------------------------
config_ipfw () {

# list of services, separated by spaces, that should be accessible on your pc
FIREWALL_MYSERVICES='22/tcp'

# List of IPs which has access to clients that should be allowed to access the provided services.
# Use keyword "any" instead of IP range when any clients should access these services
FIREWALL_ALLOWSERVICE=`netstat -r -4  | awk '/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $1}'` # IP range IPv4

returncode=0
while [ $returncode != 1 ] && [ $returncode != 255 ]
do
	exec 3>&1

	returntext=`$DIALOG --backtitle "$BACKTITLE" \
	  --help-status \
	  --help-button \
	  --item-help \
	  --title "IPFW firewall" \
	  --form "Configuring a simple IPFW firewall:" \
		15 50 0 \
		"Firewall type: "		1 1 "workstation"			1 22 11 0 "Configuring a firewall using stateful rules." \
		"Firewall quiete: " 		2 1 "YES"				2 22  3 0 "Don't log to standard output" \
		"My services: "			3 1 "$FIREWALL_MYSERVICES"		3 22 50 0 "List of services, separated by spaces, that should be accessible on your computer" \
		"Allow services: " 		4 1 "$FIREWALL_ALLOWSERVICE"		4 22 50 0 "List of IPs that should be allowed to access the provided services" \
		"Firewall log deny: "	 	5 1 "YES"				5 22  3 0 "Logs all connection attempts that are denied to /var/log/security" \
	2>&1 1>&3`
	returncode=$?
	exec 3>&-

	case $returncode in
		$DIALOG_OK)
			echo "YES"
			FIREWALL_ENABLE="YES"
			FIREWALL_TYPE=$(echo "$returntext" | sed -n 1p)
			FIRWWALL_QUIET=$(echo "$returntext" | sed -n 2p)
			FIREWALL_MYSERVICES=$(echo "$returntext" | sed -n 3p)
			FIREWALL_ALLOWSERVICE=$(echo "$returntext" | sed -n 4p)
			FIREWALL_LOGDENY=$(echo "$returntext" | sed -n 5p)
			returncode=1
			;;
		$DIALOG_CANCEL)
			"$DIALOG" --clear --backtitle "$BACKTITLE" \
			--title "IPFW firewall" \
			--yesno "Do you really want to quit without enabling the IPFW firewall?" 10 40
			case $? in
				$DIALOG_OK)
					break ;;
				$DIALOG_CANCEL)
					returncode=99 ;;
			esac
			;;
		$DIALOG_HELP)
			"$DIALOG" --clear --colors --backtitle "$BACKTITLE" \
			--no-collapse --cr-wrap \
			--title "IPFW firewall help" \
			--msgbox "\n\ZbFirewall type: \Z4workstation\Zn \n\
  Configuring an IPFW firewall using stateful rules.\n\n\
\ZbFirewall quiet: \Z4YES\Zn \n\
  Set to \Zb YES\Zn to disable the display of firewall rules\n\
  on the console during boot.\n \n\
\ZbMy services: \Z4$FIREWALL_MYSERVICES\Zn \n\
  My services is set to a list of TCP ports or services,\n\
  separated by spaces, that should be accessible on your server.\n\
  e.g. \Zb22/tcp 80/tcp 443/tcp\Zn or \Zbssh http https.\Zn \n\n\
\ZbAllow services: \Z4$FIREWALL_ALLOWSERVICE\Zn \n\
   List of IPs that should be allowed to access the provided\n\
   services. Therefore it allows you to limit access to your\n\
   exposed services to particular machines or network ranges.\n\
   For example, this could be useful if you want a machine to host\n\
   web content for an internal network.\n\n\
   The keyword \Zbany\Zn can be used instead to allow any external ip\n\
   to make use of the above services.\n\n\
\ZbFirewall log deny: \Z4YES\Zn\n\
  Set to \ZbYES\Zn to log all connection attempts that are denied to\n\
  /var/log/security.
  " 18 70
			;;
		*)
			echo "Return code: $returncode"
			exit
			;;
	esac
done
}


# -------------------- Use IPFW (stateful firewall)  --------------------
yesno_ipfw () {

	$DIALOG --clear --backtitle "$BACKTITLE"\
			--title "Configure a simple firewall" \
        	--yesno "Would you like to use a simple firewall (IPFW)?" 8 50
			
			returncode=$?
			yesno
			if [ $returncode -eq $DIALOG_OK ]; then
				config_ipfw
			fi
}


reboot_freebsd () {

	case $SYSTEM_REBOOT in
		$DIALOG_OK)
			echo ""
			shutdown -r +10s "FreeBSD will reboot!";;
		$DIALOG_CANCEL)
			echo "Installation is completed - System must be rebooted!";;
		$DIALOG_ERROR)
			echo "ERROR!";;
		$DIALOG_ESC)
			printf "Installation is completed - System must be rebooted!\n";;
		*)
		echo "Return code was $returncode";;
	esac
}


# ------------------------------------ reboot FreeBSD --------------------------
yesno_reboot () {

	SYSTEM_REBOOT=0
	
	$DIALOG --clear --backtitle "$BACKTITLE"\
			--title "Reboot FreeBSD" \
        	--yesno "Installation of Xfce Desktop Environment completed.\n\nPlease reboot FreeBSD!" 8 50
			
	SYSTEM_REBOOT=$?		 			
}


# ------------------------- add users to group ----
add_users_group () {
	local GROUP=$1
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Add users to the ${COLOR_CYAN}${GROUP}${COLOR_NC} group\n"
	for i in `awk -F: '($3 >= 1001) && ($3 != 65534) { print $1 }' /etc/passwd`; 
		do 
			pw groupmod $GROUP -m $i  2>&1
		done
	pw groupshow $GROUP | awk -v nc=$COLOR_NC -v cyan=$COLOR_CYAN  -v green=$COLOR_GREEN -F: '{printf "[ "green "INFO" nc " ]  Group: "cyan $1 nc"\tGID: " cyan $3 nc "\tMembers: " cyan $4 nc"\n"}'

}


# ---------------------- pkg activation status check --------------------------
check_pkg_activation () {
	if pkg -N >/dev/null  2>&1; then
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  pkg is installed and activated\n"
		INSTALL_PKG=0
	else
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  pkg will be installed\n"
		INSTALL_PKG=1
	fi
}


# ------------------------------------ set umask ------------------------------
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


# ---------------------- Using localization  ----------------------
set_localization () {

	# --------------- initialization: account type, charset and country code ------
	# awk search needs regular expression, you can't put /var/. Instead, use tilde: awk -v var="$var" '$0 ~ var'
	
	LANGUAGE_NAME=`awk -v locale="$LOCALE" -F ';' '$1~locale {print $2}' /tmp/LanguageCode_CountryCode`
	CHARSET=`echo $LOCALE | cut -d . -f2`				# Charset
	COUNTRY_CODE=`echo $LOCALE | cut -d . -f1 | cut -d _ -f2`	# Country_Code
}


# ------------------------------------- add login class user accounts ---
add_login_class () {
	local rc=0
	local language_name=`echo $LANGUAGE_NAME | tr "[:upper:]" "[:lower:]"` # lower cases
	DATE=`date "+%Y%m%d_%H%M%S"`

	awk "/lang=$LOCALE/{rc=1}/{exit}/ END{exit !rc}" /etc/login.conf #Login_class for $LOCALE exists?
	
	if [ $? -eq 1 ]; then  # add login class in /etc/login.conf if NOT exists!
		cp /etc/login.conf /etc/login.conf.$DATE #backup
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create backup of ${COLOR_CYAN}/etc/login.conf${COLOR_NC}. File: ${COLOR_CYAN}/etc/login.conf.$DATE${COLOR_NC}\n"
		COMMENT="#\n# ${LANGUAGE_NAME} Users Accounts. Setup proper environment variables.\n#\n"
		LOGIN_CLASS="$language_name|$LANGUAGE_NAME Users Accounts:\\\\\n\t:charset=${CHARSET}:\\\\\n\t\:lang=${LOCALE}:\\\\\n\t:tc=default:\n"

		awk -v text="$COMMENT" -v lc="$LOGIN_CLASS" '{print};/:lang=ru_RU.UTF-8:/{c=4}c&&!--c { print text lc }' /etc/login.conf > /etc/login.tmp
		mv /etc/login.tmp /etc/login.conf
		cap_mkdb /etc/login.conf
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Added ${COLOR_CYAN}${language_name}${COLOR_NC} language class to ${COLOR_CYAN}/etc/login.conf${COLOR_NC}\n"
	fi
}

# ------------------------------------ NOT USED -------------------------------
# -----------------------------------------------------------------------------
# Function not used at the moment -  use Shell Startup File Method to set language
# in xfce4; set LANG and MM_CHARSET via skel in ~/.profile

# ------------- Adapt /etc/login.conf to have the choosen language in xfce ---- 
# ------------------------logging in via lightdm gtk greeter ------------------
change_login_conf_gtk_greeter () {
	FILE="/etc/login.conf"

	if [ -f $FILE ]; then	# /etc/login.conf exists?
	
		# sed script to change ":lang=C.UTF-8:" to e.g. ":lang=de_DE.UTF-8" only on the first occurrence
		sed -i .bak -e '1{x;s/^/first/;x;}' \
			-e "1,/:lang=.*:/{x;/first/s///;x;s/:lang=.*:/:lang=${LOCALE}:/;}"  $FILE
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set ${COLOR_CYAN}lang=$LOCALE${COLOR_NC} in default section of ${COLOR_CYAN}/etc/login.conf${COLOR_NC}\n"
					
		# prevent multiple value: lang=C.UTF-8 in root class name if script exucute twice, (just delete existing lang=C.UTF-8) 				  
		sed -i .bak  '/^root/,/default/{/lang=C.UTF-8/d;}' $FILE
	
		# add lang=C.UTF-8 in root class name, Root can always login
		sed -i .bak '/^root:/,/:tc=default:/ s/:tc=default:/:lang=C.UTF-8:\\\n\t:tc=default:/' $FILE
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Added ${COLOR_CYAN}lang=C.UTF-8${COLOR_NC} in root name classe section in ${COLOR_CYAN}/etc/login.conf${COLOR_NC}\n"
		
		cap_mkdb /etc/login.conf
		rm ${FILE}.bak # Delete backup file
	fi
}                                                                                                                                                                                                       
# -----------------------------------------------------------------------------
# ------------------------------------ NOT USED -------------------------------


# ------------------------------------ set login class for ALL users ----
set_login_class () {
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set language settings (language code, country code and encoding) for ${COLOR_CYAN}ALL${COLOR_NC} users to ${COLOR_CYAN}${LANGUAGE_NAME}${COLOR_NC}.\n"
				
		for i in `awk -F: '($3 >= 1001) && ($3 != 65534) { print $1 }' /etc/passwd`; 
		do 
			pw usermod -n $i -L `echo ${LANGUAGE_NAME} | tr "[:upper:]" "[:lower:]"` 2>&1 | awk -v yellow=$COLOR_YELLOW -v nc=$COLOR_NC '{print "[ "yellow "WARNING" nc" ]  "$0}'
			pw usershow $i | awk -v nc=$COLOR_NC -v cyan=$COLOR_CYAN  -v green=$COLOR_GREEN -F: '{printf "[ "green "INFO" nc " ]  Login Name: "$1"\tHome: "$9"\t"cyan"Class: "$5 nc"\tShell: "$10"\n"}'  
		done
}


# ------------------------------------ freebsd update ----------------------------
freebsd_update () {
	
	# PAGER=cat, pls see  # environment variables section above, therefore no user interaction needed
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  FreeBSD Update: Applying latest FreeBSD security patches\n\n"
	freebsd-update fetch
	freebsd-update install
}


# ------------------------------------ pkg installation ----------------------------
install_pkg () {

	if [ "$INSTALL_PKG" -eq 1 ] ; then
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Bootstrapping pkg\n\n"
		env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg bootstrap
		echo ""
	else
		printf "[ ${COLOR_YELLOW}INFO${COLOR_NC} ]  Skipping pkg bootstrap\n"
	fi
}


# ------------------------------------ switch repository branch and update pkg ----------------------------
switch_to_latest_repository () {	
	local DIR="/usr/local/etc/pkg/repos"

	if [ $1 = "latest" ]; then
		mkdir -p $DIR
		cp /etc/pkg/FreeBSD.conf $DIR/FreeBSD.conf

		sed -i .bak 's/quarterly/latest/' $DIR/FreeBSD.conf
		rm /usr/local/etc/pkg/repos/FreeBSD.conf.bak

		if pkg update -f ; then
			# pkg update successfully completeted
			printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Switched from ${COLOR_CYAN}quarterly${COLOR_NC} to ${COLOR_CYAN}latest${COLOR_NC} pkg repository branch\n"
		else
			printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  PKG update failed\n"
			exit 1
		fi
	else
		if [ -f /usr/local/etc/pkg/repos/FreeBSD.conf ]; then
			sed -i .bak 's/latest/quarterly/' $DIR/FreeBSD.conf
			rm /usr/local/etc/pkg/repos/FreeBSD.conf.bak

			if pkg update -f ; then
				# pkg update successfully completeted
				printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Switched from ${COLOR_CYAN}latest${COLOR_NC} to ${COLOR_CYAN}quarterly${COLOR_NC} pkg repository branch\n"
			else
				printf "[ ${COLOR_RED}ERROR${COLOR_NC} ]  PKG update failed\n"
				exit 1
			fi
		fi
	fi
}


# ------------------------------------ install a package from the reposity catalogues ----
install_packages() {
	for PACKAGENAME in $*
	do
		if pkg search -L name $PACKAGENAME | cut -w -f1 | grep -x -q $PACKAGENAME; then #Check if FreeBSD package available
			printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}$PACKAGENAME${COLOR_NC} ...\n"
			pkg install -y $PACKAGENAME
		else
			printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] pkg: No packages available to install matching ${COLOR_CYAN}"$PACKAGENAME"${COLOR_NC}!\n"
		fi
	done
}



# --------------------------- update rc.conf ----------------------------------
update_rc_conf () {
	name=$1
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC} " 
	sysrc $name="YES"
}


# ------------------------------------ x11-fonts-------------------------------
install_fonts () {
local FONTS
# ------------------------------------ basic fonts ----------------------------
#x11-fonts/bitstream-vera		# Supports fully hinting, which improves the display on computer monitors.
#x11-fonts/cantarell-fonts		# Cantarell, a Humanist sans-serif font family
#x11-fonts/croscorefonts-fonts-ttf	# Google font for ChromeOS to replace MS TTF
#x11-fonts/dejavu			# will be installed with xorg
#x11-fonts/noto-basic			# Google Noto Fonts family (Basic)
#x11-fonts/noto-emoji			# Google Noto Fonts family (Emoji)
#x11-fonts/urwfonts			# URW font collection for X
#x11-fonts/webfonts			# TrueType core fonts for the Web
#x11-fonts/liberation-fonts-ttf 	# Liberation fonts from Red Hat to replace MS TTF fonts


# ------------------------------------ terminal & editor fonts-----------------
#x11-fonts/anonymous-pro		# Fixed width sans designed especially for coders
#x11-fonts/firacode			# Monospaced font with programming ligatures derived from Fira
#x11-hack/hack-font			# Monospaced font designed to be a workhorse typeface for code
#x11-fonts/inconsolata-ttf		# Attractive font for programming
#x11-fonts/source-code-pro-ttf		# Set of fonts by Adobe designed for coders

	FONTS="anonymous-pro bitstream-vera cantarell-fonts croscorefonts firacode hack-font inconsolata-ttf liberation-fonts-ttf noto-basic noto-emoji source-code-pro-ttf urwfonts webfonts"

	install_packages $FONTS
}


# --------------------------- set keyboard for X11 ---------------------------- 
set_xkeyboard () {
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  The default keymap for XFCE and the login is '${COLOR_CYAN}us${COLOR_NC}'.\n"
	if [ "$KEYBOARD_LAYOUT" != "us"  ] ; then
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Keyboard layout will be changed to '${COLOR_CYAN}$KEYBOARD_LAYOUT${COLOR_NC}'.\n"
	fi

	mkdir -p /usr/local/etc/X11/xorg.conf.d
	chmod 755 /usr/local/etc/X11/xorg.conf.d
	echo "Section \"InputClass\"
	  Identifier 		\"KeyboardDefaults\"
	  MatchIsKeyboard 	\"on\"
	  Option 		\"XkbLayout\" \"${KEYBOARD_LAYOUT}\"
EndSection" > /usr/local/etc/X11/xorg.conf.d/keyboard-${KEYBOARD_LAYOUT}.conf
	  
	chmod 644 /usr/local/etc/X11/xorg.conf.d/keyboard-${KEYBOARD_LAYOUT}.conf

	if [ $KEYBOARD_VARIANT != 'default' ]; then
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  As Keyboard variant '${COLOR_CYAN}$KEYBOARD_VARIANT${COLOR_NC}' will be set.\n"
		# The apostrophes mask the $ therefore masking must be removed before the variable. \"'${KEYBOARD_VARIANT}'\ 
		sed -i .bak '/EndSection/i \
	  Option 		\"XkbVariant\" \"'${KEYBOARD_VARIANT}'\"
					' /usr/local/etc/X11/xorg.conf.d/keyboard-${KEYBOARD_LAYOUT}.conf
		# delete backup file
		rm  /usr/local/etc/X11/xorg.conf.d/keyboard-${KEYBOARD_LAYOUT}.conf.bak

	fi
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
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}VMWare display driver${COLOR_NC} and ${COLOR_CYAN}Open VMWare tools${COLOR_NC} ...\n"
		# pkg install -y xf86-video-vmware open-vm-tools
		install_packages xf86-video-vmware open-vm-tools
		

		# --------------------------- update rc.conf, add VMWare tools --------
		# vmemctl is driver for memory ballooning
		# vmxnet is paravirtualized network driver
		# vmhgfs is the driver that allows the shared files feature of VMware Workstation and other products that use it
		# vmblock is block filesystem driver to provide drag-and-drop functionality from the remote console
		# VMware Guest Daemon (guestd) is the daemon for controlling communication between the guest and the host including time synchronization		
		update_rc_conf vmware_guest_vmblock_enable
		update_rc_conf vmware_guest_vmhgfs_enable
		update_rc_conf vmware_guest_vmmemctl_enable
		update_rc_conf vmware_guest_vmxnet_enable
		update_rc_conf vmware_guestd_enable 
		;;
				
	2) 	
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}nvidia display driver (X64)${COLOR_NC} ...\n"
		# pkg install -y nvidia-driver
		# pkg install -y nvidia-settings
		# pkg install -y nvidia-xconfig
		install_packages nvidia-driver nvidia-settings nvidia-xconfig
		
		# run nvidia autoconfig
		# nvidia-xconfig		# nvidia-xconfig will not be used 
		 
		# Set nvidia driver in /usr/local/etc/X11/xorg.conf.d
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create configuration file for NVIDIA driver in ${COLOR_CYAN}/usr/local/etc/X11/xorg.conf.d/driver-nvidia.conf${COLOR_NC}\n"
		mkdir -p /usr/local/etc/X11/xorg.conf.d
		chmod 755 /usr/local/etc/X11/xorg.conf.d
		echo "Section \"Device\"
		  Identifier 		\"Card0\"
		  Driver	 	\"nvidia\"
EndSection" > /usr/local/etc/X11/xorg.conf.d/driver-nvidia.conf
	  
		chmod 644 /usr/local/etc/X11/xorg.conf.d/driver-nvidia.conf
		
		
		# ---- update rc.conf, nvidia drivers - to load the kernel modules at boot ---
		# linux.ko and nvidia.ko will be loaded as dependency of nvidia-modeset.ko
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/etc/rc.conf${COLOR_NC} "
		sysrc kld_list+="nvidia-modeset";;
			 
	*) printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] Only NVIDEA graphics cards or installation on VMWare is supportet!\n"
	exit 1;;
	  
esac
}


# ---------- fetch wallpaper wallpaper for Xfce --------------- 
fetch_wallpaper () {
	
	# Variables
	local DIR="/usr/local/share/backgrounds/" # Xfce background folder
	if [ -d $DIR ]; then
		cd $DIR
			
		# --------------------- fetch favorite wallpaper ----------------------
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}wallpapers/Mountain_1920x1080.jpg${COLOR_NC} from gitgub "
		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/Mount_Fitz_Roy_1920x1080.jpg
			
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$DIR"${COLOR_NC} does not exist!\n"
	fi	
}


# ---------------------------- create skel templates - /usr/share/skel  -------
set_skel_template () {
	
	DATE=`date "+%Y%m%d_%H%M%S"`
	FILE="/usr/share/skel/dot.profile"
	
	# ---------------------- /usr/share/skel/dot.xinitrc ------------------
	# Start Xfce from the command line by typing startx 
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create default configuration files in ${COLOR_CYAN}/usr/share/skel/dot.xinitrc${COLOR_NC} in order to start Xfce from the command line\n"
	echo ". /usr/local/etc/xdg/xfce4/xinitrc" > /usr/share/skel/dot.xinitrc
	
	# ---------------------- /usr/share/skel/dot.profile ------------------
	# Set umask in .profile to umask 027 (rwxr-x---)
	# login.conf is not execute by lightdm when starting X11
		
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set umask=027 in ${COLOR_CYAN}$FILE${COLOR_NC}\n"
	
	# If this script runs several times: delete rows that has been inserted 
	# Pattern: sed '/regexp/,$d', delete from regular expression to end of file
	sed -i .bak '/^# file permissions: rwxr-x---/,$d' $FILE
	
	# add newline at end of file, if file ends without a newline
	if [ "$(tail -n1 $FILE)" != "" ]; then echo "" >> $FILE; fi
	
	# Set umask to 027 in dot.profile
	echo -e "# file permissions: rwxr-x---\numask 027" >> $FILE
	
	# Set default locale to have the choosen language in xfce
	# logging in via lightdm gtk greeter, 
	# ~/.profile will be executed from lightdm's session-wrapper=/usr/local/etc/lightdm/Xsession
	echo -e "\n# Set default locale\nLANG=${LOCALE}; export LANG\nMM_CHARSET=${CHARSET}; export MM_CHARSET" >> $FILE
				
	rm ${FILE}.bak # Delete backup file
	
	# populate users with the content of the skeleton directory - /usr/share/skel/dot.xinitrc
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create ${COLOR_CYAN}~/.xinitrc${COLOR_NC} in users home directory in order to start Xfce from the command line by typing startx.\n"
	printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Create or replace ${COLOR_CYAN}~/.profile${COLOR_NC} in users home directory\n"
	
	for i in `awk -F: '($3 >= 1001) && ($3 != 65534) { print $1 }' /etc/passwd`; 
		do 
			if [ -f /usr/home/${i}/.profile ]; then
				mv /usr/home/${i}/.profile /usr/home/${i}/.profile.$DATE
			fi
			pw usermod -m -n $i  2>&1
			
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
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Patching ${COLOR_CYAN}${FILE}${COLOR_NC} ...\n"
       
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
		
		rm ${FILE}.bak # Delete backup file
    
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
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$FILE"${COLOR_NC} does not exist!\n"
	fi	
	rm ${FILE}.bak # Delete backup file
	
	
	# ----------------------------- lightdm.conf ------------------------------
	
	# Set Screen size for lightdm when using VMware
	# Syntax: e.g. display-setup-script=xrandr --output default --primary --mode 2560x1440 --rate 60
	case $VGA_CARD in
		1) 	XRANDR="display-setup-script=xrandr --output default --mode $SCREEN_SIZE";;
		2) 	XRANDR="#display-setup-script=";;
		*) 	printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] Only NVIDEA graphics cards or installation on VMWare is supportet!\n"
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
		
		sed -i .bak -e "s/#greeter-setup-script=.*/greeter-setup-script=setxkbmap  -layout $KEYBOARD_LAYOUT/" \
					-e "s/#display-setup-script=.*/$XRANDR/" $FILE
		# overwrite if setting already exists
		sed -i .bak -e "s/^greeter-setup-script=.*/greeter-setup-script=setxkbmap  -layout $KEYBOARD_LAYOUT/" \
					-e "s/^display-setup-script=.*/$XRANDR/" $FILE
		
		sed -n "/^\[Seat/,/#exit-on-failure/p" $FILE               # Print [Seat:*] section
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$FILE"${COLOR_NC} does not exist!\n"
	fi	
	rm ${FILE}.bak # Delete backup file
	
	
    # ligtdm-gtk-greeter.conf
    FILE="/usr/local/etc/lightdm/lightdm-gtk-greeter.conf"
	XFILE=`basename $FILE .conf`
	
	if [ -f $FILE ]; then   # lightdm-gtk-greeter.conf exists?
        # tweak lightdm-gtk-greeter configuration
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Updating ${COLOR_CYAN}LightDM GTK+ Greeter${COLOR_NC} configuration ...\n"
        
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
        printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
    fi

   
   # ---------- patch Matcha-sea theme used in lockscreen --------------- 
   patch_lockscreen_theme
   
   # fetch FreeBSD locksceens for lightdm
   DIR="/usr/local/share/backgrounds/"				# Xfce background folder
   
	if [ -d $DIR ]; then
		cd /usr/local/share/backgrounds/
		
		
		# ------------------- fetch lock screen wallpapers --------------------
		printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Download ${COLOR_CYAN}Lock Screen Wallpapers${COLOR_NC} from gitgub ...\n"

		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/FreeBSD-lockscreen_v1-blue.png
		chmod 644 FreeBSD-lockscreen_v1-blue.png
		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/FreeBSD-lockscreen_v1-red.png
		chmod 644 FreeBSD-lockscreen_v1-red.png
		
		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/FreeBSD-lockscreen_v2-blue.png
		chmod 644 FreeBSD-lockscreen_v2-blue.png
		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/FreeBSD-lockscreen_v2-red.png
		chmod 644 FreeBSD-lockscreen_v2-red.png
		
		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/FreeBSD-lockscreen_v3-blue.png
		chmod 644 FreeBSD-lockscreen_v3-blue.png
		fetch --no-verify-peer ${GITHUB_REPOSITORY}/wallpaper/FreeBSD-lockscreen_v3-red.png
		chmod 644 FreeBSD-lockscreen_v3-red.png
		echo""
				
	else
		printf "[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}"$DIR"${COLOR_NC} does not exist!\n"
	fi	
}


# ----------------------- Post installation functions ----------------------------
# --------------------------------------------------------------------------------

# --------------------------- FreeBSD update ----------------------------------
daily_check_for_updates () {
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Add crontab file to check for updates daily ...\n"
	echo "# /etc/cron.d/s/:system_update - crontab file to automatically check for updates daily
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


# -------------------------- FreeBSD security settings (not entirely!) --------
# --------------- (some options already offers during installation)  ----------
system_hardening () {

    FILE="/etc/sysctl.conf"

	if [ -f $FILE ]; then   # /etc/sysctl.conf exists?
        
		# delete existing hardening values
		# /etc/sysctl.conf
        sed -i .bak -e "/^security.bsd.see_other_gids=.*/d" 			\
			-e "/^security.bsd.see_other_uids=.*/d" 		\
			-e "/^security.bsd.see_jail_proc=.*/d"			\
			-e "/^security.bsd.unprivileged_read_msgbuf=.*/d"	\
			-e "/^security.bsd.unprivileged_proc_debug=.*/d"	\
			-e "/^security.bsd.hardlink_check_uid=.*/d"		\
			-e "/^security.bsd.hardlink_check_gid=.*/d"		\
			-e "/^kern.randompid=.*/d"				\
			-e "/^kern.ipc.shm_use_phys=.*/d"			\
			-e "/^kern.msgbuf_show_timestamp=.*/d"			\
			-e "/^hw.kbd.keymap_restrict_change=.*/d"		\
			-e "/^net.inet.icmp.drop_redirect=.*/d"			\
			-e "/^net.inet6.icmp6.rediraccept=.*/d"			\
			-e "/^net.inet.ip.check_interface=.*/d"			\
			-e "/^net.inet.ip.random_id=.*/d"			\
			-e "/^net.inet.ip.redirect=.*/d"			\
			-e "/^net.inet6.ip6.redirect=.*/d"			\
			-e "/^net.inet.tcp.drop_synfin=.*/d"			\
			-e "/^net.inet.tcp.blackhole=.*/d"			\
			-e "/^net.inet.udp.blackhole=.*/d"			\
			-e "/^net.inet6.ip6.use_tempaddr=.*/d"			\
			-e "/^net.inet6.ip6.prefer_tempaddr=.*/d" $FILE
		
		# /etc/rc.conf
		sed -i .bak	-e "/^clear_tmp_enable=.*/d"\
				-e "/^syslogd_flags=.*/d"	\
				-e "/^sendmail_enable/d" /etc/rc.conf

		# /etc/ttys
	    	sed -i .bak "s/unknown.*off.*insecure/unknown	off secure/g" /etc/ttys 
		rm /etc/ttys.bak		
		
		# /boot/loader.conf
	    	sed -i .bak "/^security.bsd.allow_destructive_dtrace=.*/d" /boot/loader.conf
		
		
		# System security hardening options
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set system security hardening options in ${COLOR_CYAN}${FILE}${COLOR_NC} ...\n"
		for feature in $FEATURES $NETWORK_FEATURES; do

			case "$feature" in
				hide_uids)
					echo 'security.bsd.see_other_uids=0' >> $FILE		# Hide processes running as other users
					;;
				hide_gids)
					echo 'security.bsd.see_other_gids=0' >> $FILE		# Hide processes running as other groups 
					;;
				hide_jail)
					echo 'security.bsd.see_jail_proc=0' >> $FILE		# Hide processes running in jails
					;;
				read_msgbuf)
					echo 'security.bsd.unprivileged_read_msgbuf=0' >> $FILE	# Disable reading kernel message buffer for unprivileged users
					;;
				proc_debug)
					echo 'security.bsd.unprivileged_proc_debug=0' >> $FILE	# Disable process debugging facilities for unprivileged users
					;;
				hardlink_uid)
					echo 'security.bsd.hardlink_check_uid=1' >> $FILE	# Unprivileged users are not permitted to create hard links to files not owned by the
					;;
				hardlink_gid)
					echo 'security.bsd.hardlink_check_gid=1' >> $FILE	# Unprivileged users are not permitted to create hard links to files if they are not member of file's group
					;;
				random_pid)
					echo 'kern.randompid=1'	>> $FILE			# Randomize the PID of newly created processes	
					;;
				lock_shm)
					echo 'kern.ipc.shm_use_phys=1' >> $FILE			# Lock shared memory into RAM and prevent it from being paged out to swap (default 0, disabled)
					;;
				msgbuf_timestamp)
					echo 'kern.msgbuf_show_timestamp=1' >> $FILE		# Display timestamp in msgbuf (default 0)
					;;
				keymap_restricted)
					echo 'hw.kbd.keymap_restrict_change=4' >> $FILE		# Disallow keymap changes for non-privileged users
					;;
				# Network
				icmp_redirects)
					echo 'net.inet.icmp.drop_redirect=1' >> $FILE		# Ignore ICMP redirects (default 0)
					;;
				icmp6_redimsg)
					echo 'net.inet6.icmp6.rediraccept=0' >> $FILE		# Ignore ICMPv6 redirect messages (default 1, 1=accept)
					;;
				right_interface)
					echo 'net.inet.ip.check_interface=1' >> $FILE		# Verify packet arrives on correct interface (default 0)
					;;
				random_id)
					echo 'net.inet.ip.random_id=1' >> $FILE			# Assign a random IP id to each packet leaving the system (default 0)
					;;
				ip_redirect)
					echo 'net.inet.ip.redirect=0' >> $FILE			# Do not send IP redirects (default 1)
					;;
				ipv6_redirect)
					echo 'net.inet6.ip6.redirect=0' >> $FILE		# Do not send IPv6 redirects (default 1)
					;;
				tcp_with_synfin)
					echo 'net.inet.tcp.drop_synfin=1' >> $FILE		# Drop TCP packets with SYN+FIN set (default 0)
					;;
				tcp_blackhole)
					echo 'net.inet.tcp.blackhole=2'	>> $FILE		# Don't answer on closed TCP ports(default 0)
					;;
				udp_blackhole)
					echo 'net.inet.udp.blackhole=1'	>> $FILE		# Don't answer on closed UDP ports (default 0)
					;;
				use_tempaddr)
					echo 'net.inet6.ip6.use_tempaddr=1' >> $FILE		# Enable privacy settings for IPv6 (RFC 3041)
					;;
				prefer_privaddr)
					echo 'net.inet6.ip6.prefer_tempaddr=1' >> $FILE		# refer privacy addresses and use them over the normal addresses
					;;
				# /etc/rc.conf
				clear_tmp)
					printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Clean the ${COLOR_CYAN}/tmp ${COLOR_NC}filesystem on system startup ...\n"
					sysrc clear_tmp_enable="YES"
					;;
				disable_syslogd)
					printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Disable opening Syslogd network socket (disables remote logging) ...\n"
					sysrc syslogd_flags="-ss"
					;;
				disable_sendmail)
					printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Disable sendmail service ...\n"
					sysrc sendmail_enable="NONE"
					;;				
				# /etc/ttys	
				secure_console)
					printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Enable console password prompt ...\n"
					sed -i .bak "s/unknown.*off.*secure/unknown	off	insecure/g" /etc/ttys
					rm /etc/ttys.bak
					;;
				# /loader.conf
				disable_ddtrace)
					printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Disallow DTrace destructive-mode ...\n"
					echo 'security.bsd.allow_destructive_dtrace=0' >> /boot/loader.conf
					;;
			esac
		done

	else
 		printf "\n[ ${COLOR_RED}ERROR${COLOR_NC} ] ${COLOR_CYAN}${FILE}${COLOR_NC} does not exist!\n"
 	fi

	rm ${FILE}.bak /etc/rc.conf.bak /boot/loader.conf.bak # delete backup files
}

# -------------------------------------- Firewall -----------------------------
enable_ipfw_firewall () {

	if [ $FIREWALL_ENABLE = "YES" ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Enable the predefined ipfw firewall ...\n"
		sysrc firewall_enable="YES"				# Enable the predefined ipfw firewall 			
		sysrc firewall_type="workstation"			# Overwrite setting from dialog; protects only this machine using stateful rules
		if [ $FIRWWALL_QUIET = "YES" ]; then
			sysrc firewall_quiet="YES" 			# suppress rule display
		fi
		sysrc firewall_myservices="$FIREWALL_MYSERVICES"
		sysrc firewall_allowservices="$FIREWALL_ALLOWSERVICE"

		# log denied packets to /var/log/security
		if [ $FIREWALL_LOGDENY = "YES" ]; then
			sysrc firewall_logdeny="YES"
		fi
	fi
}


enable_rkhunter () {
	
	if pkg info | grep -q rkhunter; then 			# Check if FreeBSD package rkhunter is installed
		FILE="/etc/periodic.conf"			# this file contains local overrides for the default periodic configuration

		if [ ! -f $FILE ]; then   			# /etc/periodic.conf exists?
			touch $FILE
		else
			# delete existing parameters for rkhunter in /etc/periodic.conf
			sed -i .bak '/# Keep your rkhunter database up-to-date/,/daily_rkhunter_check_flags="--checkall --nocolors --skip-keypress"/d' $FILE
		
		rm ${FILE}.bak
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
	fi
}


# ------------------------ Intel and AMD CPUs microcode updates ---------------
install_cpu_microcode_updates () {
	if [ "$INSTALL_CPU_MICROCODE_UPDATES" -eq 1 ]; then
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}devcpu-data${COLOR_NC} will allow host startup to update the CPU microcode on a FreeBSD system automatically ...\n"
		install_packages devcpu-data # pkg install devcpu-data
		printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Update ${COLOR_CYAN}/boot/loader.conf${COLOR_NC} to update the CPU microcode automatically on a FreeBSD system startup ...\n"
		#loads and applies the update before the kernel begins booting
		sysrc -f /boot/loader.conf cpu_microcode_load="YES"
		sysrc -f /boot/loader.conf cpu_microcode_name="/boot/firmware/intel-ucode.bin"
	fi
}


# --------------------- Fix micro stuttering on AMD Ryzen ---------------------

fix_amd_ryzen_micro_stutter () {

	# Fix issues with micro stutters on AMD Ryzen system 
	# Stuttering in youtube videos, games, etc. on AMD Ryzen systems
	# https://lists.freebsd.org/pipermail/freebsd-current/2021-March/079237.html
	# Solution: sysctl kern.sched.steal_thresh=1

	FILE="/etc/sysctl.conf"
	sed -i .bak "/^kern.sched.steal_thresh=.*/d" $FILE
	rm ${FILE}.bak
	
	CPU=$(sysctl -n hw.model)
	MFT=$(echo ${CPU} | awk '{print $1}')
	CPU_BRAND=$(echo ${CPU} | awk '{print $2}')
	HYPERVISOR=$( sysctl -n hw.hv_vendor)

	if [ $MFT = "AMD" ] && [ $CPU_BRAND = "Ryzen" ]; then
		echo 'kern.sched.steal_thresh=1' >> $FILE
	fi
}


# ------------------ Delay in seconds before automatically booting ------------
set_autoboot_delay  () {

	# Delay in seconds before automatically booting
	printf "\n[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Set FreeBSD ${COLOR_CYAN}boot delay${COLOR_NC} to 5 seconds\n"
	sysrc -f /boot/loader.conf autoboot_delay="$AUTOBOOTDELAY"
}


## ----------------------------------------------------------------------------
## ----------------------------------- Main -----------------------------------
## ----------------------------------------------------------------------------

# precondions
set -o pipefail 	# Change the exit status of a pipeline to the last non-zero existatus of any command, if any
set -o errexit		# Exit immediately if any untested command fails in non-interactive mode 

{
display_date
check_if_root 
check_network
} 2>&1 | tee $LOGFILE

set +o errexit		# Disable errexit for dialog boxes

# Welcome, select language, country code and keyboard for installation
msgbox_welcome
menubox_language
menubox_xkeyboard

# ----------- Select applications & utilities for installation ----------------
checklist_applications
checklist_utilities
radiolist_repository_branch
yesno_summary

{
display_system_info
freebsd_update
set_umask
set_localization
add_login_class

## ----------------------- Create skel templates in /usr/share/skel ------------
set_skel_template
} 2>&1 | tee -a $LOGFILE

add_user

{
set_login_class
check_pkg_activation
install_pkg
switch_to_latest_repository $REPOSITORY # Quarterly or latest package branches 
} 2>&1 | tee -a $LOGFILE


## -------------------------------- start installation -------------------------
## -----------------------------------------------------------------------------

### ------------------------ install xorg, x11-fonts, set keyboard -------------
{
install_packages xorg
install_fonts
set_xkeyboard

## ------------------------- add users to group video for accelerated video ----
add_users_group video

## --------------- start moused daemon to support mouse operation in X11 -------
update_rc_conf moused_enable 

## ------------------------------------ install X11 video driver ---------------
## --------------------- only nvidea and VMWare video drivers are supportet ----
install_video_driver

## ------------------------- install xfce4, lightdm, xdg-user-dirs -------------
printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XFCE Desktop Environment with LightDM GTK+ Greeter${COLOR_NC} ...\n"
## pkg install -y xfce lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
install_packages xfce lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

## ------------------------------------ start lightdm --------------------------
update_rc_conf lightdm_enable

## -------------------------- install XDG user directories ---------------------
##pkg install xdg-user-dirs
install_packages xdg-user-dirs

## ------------------------------------ install xfce panel plugins -------------
install_packages xfce4-whiskermenu-plugin thunar-archive-plugin xfce4-weather-plugin xfce4-pulseaudio-plugin xfce4-screenshooter-plugin

## ------------------------------------ install Matcha and Arc themes ---------
printf "[ ${COLOR_GREEN}INFO${COLOR_NC} ]  Installing ${COLOR_CYAN}XFCE GTK themes: Matcha and Arc${COLOR_NC} ...\n"
install_packages matcha-gtk-themes gtk-arc-themes

## ------------------------------------- update rc.conf, enable dbus -----------
## xfce uses D-Bus as message bus and it must be enabled in /etc/rc.conf be started when the system boots
update_rc_conf dbus_enable

## ----------------------- fetch wallpaper wallpaper for Xfce ----------------- 
fetch_wallpaper

## ----------------------- Tweak lightdm --------------------------------------
set_lightdm_greeter
 
## -------------------------- install applications & utilities -----------------
install_packages $APP_LIST 
install_packages $UTILITY_LIST
enable_rkhunter	# Keep your rkhunter database up-to-date ans schedule daily security check
} 2>&1 | tee -a $LOGFILE


## -----------------------------------------------------------------------------
## ----------------------- Post installation tasks -----------------------------

# ------------------------- System hardening options --------------------------
checklist_system_hardening

# -------------------------------- IPFW firewall -------------------------------
yesno_ipfw # Use predifined ipfw firewall?

{
# ------------------------- System hardening options --------------------------
system_hardening

# ------------------------- enable IPFW firewall ------------------------------ 
enable_ipfw_firewall

# Daily check for FreeBSD and package updates
daily_check_for_updates

# ------------------------ Intel and AMD CPUs microcode updates ---------------
install_cpu_microcode_updates

# --------------------- Fix micro stuttering on AMD Ryzen ---------------------
fix_amd_ryzen_micro_stutter

# ------------------ Delay in seconds before automatically booting ------------
set_autoboot_delay 

# -------------- Specify the maximum desired resolution for the EFI console ---
sysrc -f /boot/loader.conf efi_max_resolution=$SCREEN_SIZE

} 2>&1 | tee -a $LOGFILE
# ------------------------------------ reboot FreeBSD --------------------------
sleep 1
yesno_reboot
reboot_freebsd 2>&1 | tee -a $LOGFILE

# ----------------------------------End of file--------------------------------
# -----------------------------------------------------------------------------
