#!/system/bin/sh
# 
# droidbox v1.0 by Jared Rummler (JRummy16)
# 
# Warning: this script has the potential to brick or damage your
# device. I take no responibility for any bricked phones.
# 
# This script is a compilation of useful functions available for
# most android devices. For best use symlink the commands in an
# updater-script for install like busybox or toolbox.
# 
# V1.0 - Initial release
# 

##--------------------------------------------------------------------------------------------
##--- Variables:
##--------------------------------------------------------------------------------------------

SCRIPT_NAME=droidbox
CMD=$($BB basename $0)
ARG=$@

# Directories:
DROIDBOX_DIR_EXTERNAL=/sdcard/droidbox
DROIDBOX_DIR_INTERNAL=/system/etc/droidbox
BACKUP_DIR=/sdcard/droidbox/MyBackup

# Defaults:
LOGGING=0	# Logging off by default
BANNER=1	# Show acssi banner on by default
ALLINONE=0	# All in one loop
REBOOT=1
PROMPTUNINSTALL=1

##--------------------------------------------------------------------------------------------
##--- Functions:
##--------------------------------------------------------------------------------------------

droidBoxUsage()
{
	$BB echo "DroidBox v1.0"
	$BB echo "Created by: Jared Rummler (JRummy16)"
	$BB echo ""
	$BB echo "Usage: $SCRIPT_NAME [function] [arguments]..."
	$BB echo "   or: function [arguments]..."
	$BB echo "         (Assuming droidbox is symlinked)"
	$BB echo ""
	$BB echo "Currently defined functions:"
	$BB echo ""
	$BB echo "ads, allinone, apploc, bkapps, camsound, compcache,"
	$BB echo "chglog, exe, fixperms, flashrec, freemem, install_zip,"
	$BB echo "load, rb, rmapk, rstapps, setcpu, setprops, slim, sound"
	$BB echo "switch, symlinkdb, sysrw, sysro, usb, zipalign_apks"
	$BB echo ""
	$BB echo "To see options for specific commands use:"
	$BB echo "       $SCRIPT_NAME [command] -help"
	$BB echo "   or: [command] -help (if symlinked)"
}

checkBusybox()
{
	if cat /system/xbin/busybox > /dev/nul 2>&1; then
		BB=/system/xbin/busybox
	elif cat /system/bin/busybox > /dev/nul 2>&1; then
		BB=/system/bin/busybox
	else
		echo "Error: Busybox not found!"
		exit
	fi
}

checkRoot()
{
	if $BB [ `$BB whoami` != "root" ]; then
		$BB echo "Error: Must be root to run this script"
		$BB echo "Type \"su\" in terminal and try again."
		exit
	fi
}

checkSd()
{
	if $BB [ -z "$($BB mount | $BB grep /sdcard)" ]; then
		LOG_FILE=$DROIDBOX_DIR_INTERNAL/droidbox.log
		printMsg "Error: sdcard not found! Please unmount your sdcard."
		exit
	else
		LOG_FILE=$DROIDBOX_DIR_EXTERNAL/droidbox.log
	fi
}

checkDevice()
{
	if $BB [ `getprop ro.build.product` != "$1" -o `getprop ro.product.device` != "$1" ]; then
		$BB echo "Your device is not supported for this script."
		$2
	fi
}

promptToReboot()
{
	$BB echo ""
	case $1 in
		performance)	$BB echo "A reboot is suggested for the best performance for your device."			;;
		changes)		$BB echo "To see the changes take effect a reboot is required."						;;
		*)				$BB echo "A reboot is suggested."													;;
	esac
	$BB echo -n "Would you like to reboot your device now? (y/n): "
	read rebootChoice
	case $rebootChoice in
		y|Y)	_rb --reboot								;;
		n|N)												;;
		*)		$BB echo "Invalid option in $rebootChoice."	;;
	esac
}

taskRuntime()
{
	RUNTIME=`$BB expr $STOP - $START`
	HOURS=`$BB expr $RUNTIME / 3600`
	REMAINDER=`expr $RUNTIME % 3600`
	MINS=`$BB expr $REMAINDER / 60`
	SECS=`$BB expr $REMAINDER % 60`
	$BB printf "%02d:%02d:%02d\n" "$HOURS" "$MINS" "$SECS"
}

printMsg()
{
	if $BB [ $LOGGING -eq 1 ]; then
		$BB echo $1 $2 | $BB tee -a $LOG_FILE
	else
		$BB echo $1 $2
	fi
}

allInOneLoop()
{
	if $BB [ $ALLINONE -eq 1 ]; then
		if $BB [ `$BB basename $0` == "$SCRIPT_NAME" ]; then
			$BB sleep $1
			`$BB basename $0` allinone
		else
			$BB sleep $1
			$0
		fi
	fi
}

_ads()
{
  #############################################################
  # Description:
  #    Uses the phone's hostfile to block ads
  # Created by:
  #    Jared Rummler (JRummy16) 
  # Last modified:
  #    9-21-2010
  #
	HOSTS_URL="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other"
	
	_adsUsage()
	{
		$BB echo "Usage: ads [on|off]"
		$BB echo ""
		$BB echo "Blocks or shows most ads"
	}
	
	getHosts()
	{
		$BB mkdir -p $DROIDBOX_DIR_INTERNAL
		if $BB [ ! -e $DROIDBOX_DIR_INTERNAL/$1 ]; then
			$BB echo -n "Downloading $1 to show/block ads... "
			$BB wget -q $HOSTS_URL/$1 -O $DROIDBOX_DIR_INTERNAL/$1
			$BB echo "done."
		fi
	}
	
	case $1 in
		off)
			getHosts hosts.local
			getHosts hosts.adblock
			$BB echo -n "Enabling ad blocking ... "
			$BB cat $DROIDBOX_DIR_INTERNAL/hosts.local > /system/etc/hosts
			$BB cat $DROIDBOX_DIR_INTERNAL/hosts.adblock >> /system/etc/hosts
			$BB echo "done."
			$BB echo ""
			$BB echo "Ads have been disabled."
		;;
		on)
			getHosts hosts.local
			$BB echo -n "Disabling ad blocking ... "
			$BB cat $DROIDBOX_DIR_INTERNAL/hosts.local > /system/etc/hosts
			$BB echo "done."
			$BB echo ""
			$BB echo "Ads have been enabled."
		;;
		*)
			_adsUsage
		;;
	esac
}

_allinone()
{
  #############################################################
  # Description:
  #    Displays a user friendly menu to run commonly used
  #    helpful scripts.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	ALLINONE=1
	
	_allinoneUsage()
	{
		$BB echo "Usage: allinone"
		$BB echo ""
		$BB echo "Displays a user friendly menu to run"
		$BB echo "commonly used droidbox scripts."
	}
	
	backupAndRestoreMenu()
	{
		$BB echo "-------------------------------------------------"
		$BB echo " 1  Go to backup options"
		$BB echo " 2  Go to restore options"
		$BB echo " 3  Exit this menu"
		$BB echo "-------------------------------------------------"
		$BB echo -n "Please choose a number: "
		read backupAndRestoreChoice
		case $backupAndRestoreChoice in
			1)	_bkapps														;;
			2)	_rstapps													;;
			3)																;;
			*)	$BB echo "Error: Invalid option in $backupAndRestoreChoice"	;;
		esac
	}

	allInOneOtherScripts()
	{
		$BB echo "---------------------------------------"
		$BB echo " 1   Zipalign apks"
		$BB echo " 2   Block Ads"
		$BB echo " 3   Show Ads"
		$BB echo " 4   Turn off camera shutter sounds."
		$BB echo " 5   Turn on camera shutter sounds."
		$BB echo " 6   Free Internal Memory"
		$BB echo " 7   Fix permissions"
		$BB echo " 8   Switch boot animations"
		$BB echo " 9   Switch live wallpapers"
		$BB echo " 10  View Changelog"
		$BB echo " 11  Mount / unmount USB storage"
		$BB echo " 12  Flash recovery image"
		$BB echo " 13  Change build properties"
		$BB echo " 14  Exit this menu"
		$BB echo "---------------------------------------"
		$BB echo -n "Please choose a number: "
		read scriptChoice
		case $scriptChoice in
			1)
				$BB echo "--------------------------------------------"
				$BB echo " 1  Zipalign all apks in /system and /data"
				$BB echo " 2  Enter directory to zipalign apks in"
				$BB echo " 3  Exit this menu"
				$BB echo "---------------------------------------"
				$BB echo -n "Please choose a number: "
				read zipalignChoice
				case $zipalignChoice in
					1)
						_zipalign_apks --all
					;;
					2)
						$BB echo "--------------------------------------------------"
						$BB echo " Please choose a destination to ZipAlign apks"
						$BB echo " Example 1: /sdcard/my_apps"
						$BB echo " Example 2: /system/app"
						$BB echo "--------------------------------------------------"
						$BB echo -n "Please enter path to apks: "
						read zipchoice
						_zipalign_apks "$zipchoice"
					;;
					3)
					
					;;
					*)
						$BB echo "Error: Invalid option in $zipalignChoice"
					;;
				esac
			;;
			2)
				_ads off
			;;
			3)
				_ads on
			;;
			4)
				_camsound off
			;;
			5)
				_camsound on
			;;
			6)
				$BB echo "----------------------------------"
				$BB echo " 1  Free 50MB of Internal Memory"
				$BB echo " 2  Free 75MB of Internal Memory"
				$BB echo " 3  Free 100MB of Internal Memory"
				$BB echo " 4  Default Internal Memory"
				$BB echo " 5  Exit this menu"
				$BB echo "----------------------------------"
				$BB echo -n "Please choose a number: "
				read freeMemChoice
				case $freeMemChoice in
					1)	_freemem 50mb										;;
					2)	_freemem 75mb										;;
					3)	_freemem 100mb										;;
					4)	_freemem default									;;
					5)														;;
					*)	$BB echo "Error: Invalid option in $freeMemChoice"	;;
				esac
			;;
			7)
				_fixperms
			;;
			8)
				_switch ba
			;;
			9)
				_switch lwp
			;;
			10)
				_chglog
			;;
			11)
				if $BB [ -z "$($BB mount | $BB grep /sdcard)" ]; then
					_usb -d
				else
					_usb -e
				fi
			;;
			12)
				$BB echo "----------------------------------"
				$BB echo " 1  Flash SPRecovery"
				$BB echo " 2  Flash ClockWork Recovery"
				$BB echo " 3  Exit this menu"
				$BB echo "----------------------------------"
				$BB echo -n "Please choose a number: "
				read flashRecChoice
				case $flashRecChoice in
					1)	_flashrec -c										;;
					2)	_flashrec -s										;;
					3)														;;
					*)	$BB echo "Error: Invalid option in $flashRecChoice"	;;
				esac
			;;
			13)
				_setprops
			;;
			14)
			
			;;
			*)
				$BB echo "Error: Invalid option in $scriptChoice"
			;;
		esac
	}
	
	allInOneBanner()
	{
		if $BB [ $BANNER -eq 1 ]; then
			$BB echo ""
			$BB echo "-------------------------------------------------"
			$BB echo "     ___   ____      ____         ____"
			$BB echo "    / _ | / / /____ /  _/___ ____/ __ \___ ___"
			$BB echo "   / __ |/ / //___/_/ / / _ |___/ /_/ / _ | -_)"
			$BB echo "  /_/ |_/_/_/     /___//_//_/   \____/_//_|__/"
			$BB echo ""
			$BB echo "                          -by: JRummy16"
		fi
	}
	
	if $BB [ $# -gt 0 ]; then
		_allinoneUsage
	fi
	
	checkSd
	allInOneBanner
	
	$BB echo "-------------------------------------------------"
	$BB echo " Choose between: 1, 2, 3, 4, 5, 6, 7, 8, 9 & 10"
	$BB echo " 1    Change Boot Animation"
	$BB echo " 2    Change Live Wallpaper"
	$BB echo " 3    Change Fonts"
	$BB echo " 4    Add Extra Applications"
	$BB echo " 5    Remove & Uninstall Applications"
	$BB echo " 6    Choose Apps2sd Options"
	$BB echo " 7    Set CPU and Show CPU Info."
	$BB echo " 8    Backup / Restore data"
	$BB echo " 9    Run Other Scripts"
	$BB echo " 10   Exit This Script"
	$BB echo "-------------------------------------------------"
	$BB echo -n "Please choose a number: "
	read allInOneChoice
	case $allInOneChoice in
		1)	_load --bootani										;;
		2)	_load --livewalls									;;
		3)	_load --fonts										;;
		4)	_load --extraapps									;;
		5)	_rmapk --menu										;;
		6)	_apploc --menu										;;
		7)	_setcpu												;;
		8)	backupAndRestoreMenu								;;
		9)	allInOneOtherScripts								;;
		10)	exit												;;
		*)	$BB echo "Error: Invalid option in $allInOneChoice"	;;
	esac
	
	allInOneLoop 0
}

_apploc()
{
  #############################################################
  # Description:
  #    Sets install location of apps to sdcard, internal or
  #    auto
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_applocUsage()
	{
		$BB echo "Usage: apploc"
		$BB echo ""
		$BB echo "Options:"
		$BB echo ""
		$BB echo "  2sd     Apps will be installed to external storage"
		$BB echo "  2in     Apps will be installed to internal storage"
		$BB echo "  2au     System will decide where to install apps"
		$BB echo "  -m      Print a user friendly menu for app locations"
		$BB echo "  -help   This help"
	}
	
	setAppInstallLocation()
	{
		$BB echo -n "Install location changed from `pm getInstallLocation | $BB sed -e 's/^..//' -e 's/.$//'` "
		pm setInstallLocation $1
		$BB echo "to `pm getInstallLocation | $BB sed -e 's/^..//' -e 's/.$//'`"
	}
	
	appLocationMenu()
	{
		$BB echo "---------------------------------------------------------"
		$BB echo " Your current install location is: `pm getInstallLocation | $BB cut -c 2-`"
		$BB echo " 1  [external]: Install on external storage (sdcard)."
		$BB echo " 2  [internal]: Install on internal device storage."
		$BB echo " 3  [auto]: Let system decide the best location."
		$BB echo " 4  Exit this menu"
		$BB echo "---------------------------------------------------------"
		$BB echo -n "Please choose a number: "
		read locationChoice
		case $locationChoice in
			1)	setAppInstallLocation 2								;;
			2)	setAppInstallLocation 1								;;
			3)	setAppInstallLocation 0								;;
			4)														;;
			*)	$BB echo "Error: Invalid option in $locationChoice"	;;
		esac
	}
	
	case $1 in
		2sd|--2sdcard)
			setAppInstallLocation 2
		;;
		2in|--2internal)
			setAppInstallLocation 1
		;;
		2au|--2auto)
			setAppInstallLocation 0
		;;
		-m|--menu)
			appLocationMenu
		;;
		*)
			_applocUsage
		;;
	esac
}

_bkapps()
{
  #############################################################
  # Description:
  #    Backs up applications, data, accounts and other
  #    configurations to the sdcard.
  # Created by:
  #    Jared Rummler (JRummy16) * modified from my original
  #    backup script. *
  # Last modified:
  #    9-9-2010
  #
	
	VERSION="1.1"
	PROMPT_REMOVE=1	# User will be prompted to remove previous backups
	
	backupUsage()
	{
		$BB echo " Usage: bkapps [-a|-nd|-c|-l|-m|-mu|-r|-h]"
		$BB echo ""
		$BB echo " options:"
		$BB echo ""
		$BB echo "    -a  | --apps       Backs up apps and their data"
		$BB echo "    -nd | --no_data    Backs up apps only (no data)"
		$BB echo "    -c  | --complete   Performs a complete backup"
		$BB echo "    -l  | --logging    Enable logging for this run"
		$BB echo "    -m  | --misc       Backs up wifi, home setup & accounts"
		$BB echo "    -r  | --remove     Deletes old backup without prompt"
		$BB echo "    -v  | --version    Print `$BB basename $0` version"
		$BB echo "    -h  | --help       This help"
		$BB echo ""
		$BB echo "    Always specify options as separate words" 
		$BB echo "    e.g. -r -c instead of -rc. Its required!"
		$BB echo "    If you enter a partial name of an app it"
		$BB echo "    will backup all files that match the"
		$BB echo "    name. Example: `$BB basename $0` pand will backup"
		$BB echo "    Pandora if you have it installed."
		exit
	}
	
	removeBackup()
	{
		$BB mkdir -p $1
		if $BB [ $PROMPT_REMOVE -eq 1 ]; then
			if $BB [ `$BB find $1 -type f | $BB wc -l` -eq 0 ]; then
				printMsg "A previous backup was found in $1"
				printMsg "If you choose to keep the backup some files could remain in your new backup."
				printMsg -n "Would you like to remove this backup before continuing (y/n)?"
				read remove
				case $remove in
					y|Y)
						printMsg -n "Removing old backup .."
						$BB rm -R $1
						printMsg ". done."
						;;
					*)	;;
				esac
			fi
		else
			printMsg -n "Removing previous backup .."
			$BB rm -R $1
			printMsg ". done."
		fi
	}
	
	backupApps()
	{
		APP_SUM=$( $BB find /data/app /data/app-private -iname *.apk | $BB wc -l )
		APP=1
		
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Backing up apps ..."
		$BB echo "**********************************"
		$BB echo ""
		
		$BB mkdir -p $BACKUP_DIR/apps
		$BB find /data/app /data/app-private -iname *.apk -print | while read apk	# To do: look for apps on external storage.
		do
			printMsg -n "($APP of $APP_SUM) Backing up: `$BB basename $apk` .."
			APP=$( $BB expr $APP + 1 )
			$BB cp -f $apk $BACKUP_DIR/apps
			printMsg ". done."
		done
	}
	
	backupData()
	{
		FILE_SUM=$( $BB find /data/data -type f | $BB wc -l )
		FILE=1
		
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Backing up data ..."
		$BB echo "**********************************"
		$BB echo ""
		
		$BB find /data/data -type f -print | while read f
		do
			$BB mkdir -p `$BB dirname $BACKUP_DIR$f`
			printMsg -n "($FILE of $FILE_SUM) Backing up: `$BB basename $f` .."
			FILE=$( $BB expr $FILE + 1 )
			$BB cp -f $f $BACKUP_DIR$f
			printMsg ". done."
		done
	}

	backupMisc()
	{
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Backing up misc settings ..."
		$BB echo "**********************************"
		$BB echo ""
		
		$BB mkdir -p $BACKUP_DIR/misc
		
		if $BB [ -e /data/misc/wifi/wpa_supplicant.conf ]; then
			printMsg -n "Backing up wifi settings .."
			$BB cp -f /data/misc/wifi/wpa_supplicant.conf $BACKUP_DIR/misc
			printMsg ". done."
		fi
		
		if $BB [ -e /data/system/accounts.db ]; then
			printMsg -n "Backing up accounts .."
			$BB cp -f data/system/accounts.db $BACKUP_DIR/misc	# Need to use sqlite3 :-/
			printMsg ". done."
		fi
		
		if $BB [ -e /data/system/appwidgets.xml ]; then
			printMsg -n "Backing up home screen setup .."
			$BB cp -f /data/system/appwidgets.xml $BACKUP_DIR/misc
			printMsg ". done."
		fi
	}

	backupAnyApp()
	{
		AA_FIND=$( $BB ls /data/app /data/app-private | $BB grep -i $1 )
		AA_SUM=$( $BB ls /data/app /data/app-private | $BB grep -i $1 | $BB wc -l )
		AA=1
		
		if $BB test -z $AA_FIND > /dev/null 2>&1; then
			printMsg "`$BB basename $0` unknown option $1"
			backupUsage
		else
			$BB mkdir -p $BACKUP_DIR/apps
			for apk in $AA_FIND
			do
				printMsg -n "($AA of $AA_SUM) Backing up: $apk .."
				$BB find /data/app /data/app-private -iname $apk -exec $BB cp -f {} $BACKUP_DIR/apps ';'
				AA=$( $BB expr $AA + 1 )
				printMsg ". done."
			done
		fi
	}

	acssiBanner()
	{
		# If you use this script please do not remove the banner.
		
		if $BB [ $BANNER -eq 1 ]; then
			$BB echo ""
			$BB echo "  __ )                |                  "
			$BB echo "  __ \    _\` |   __|  |  /  |   |  __ \  "
			$BB echo " ____/  \__,_| \___| _|\_\ \__,_|  .__/  "
			$BB echo "                                  _|     "
			$BB echo " "
			$BB echo "   |_   .   ************************"
			$BB echo "   |_)\/.   |J||R||u||m||m||y||1||6|"
			$BB echo "      /     ************************"
			$BB echo ""
			$BB echo "   `$BB basename $0` runtime: `taskRuntime`"
		elif $BB [ $BANNER -eq 0 ]; then
			$BB echo ""
			$BB echo "   `$BB basename $0` runtime: `taskRuntime`"		
		fi
	}

	backupAllInOneMenu()
	{
		if $BB [ $ALLINONE -eq 1 ]; then
			$BB echo "-------------------------------------------------"
			$BB echo " 1  Backup all applications and their data"
			$BB echo " 2  Backup all applications (no data)"
			$BB echo " 3  Perform a complete backup"
			$BB echo " 4  Backup wifi, home setup and accounts"
			$BB echo " 5  Exit this menu"
			$BB echo "-------------------------------------------------"
			$BB echo -n "Please choose a number: "
			read backupChoice
			case $backupChoice in
				1)	ALLINONE=0
					_bkapps -a											;;
				2)	ALLINONE=0
					_bkapps -nd											;;
				3)	ALLINONE=0
					_bkapps -c											;;
				4)	ALLINONE=0
					_bkapps -m											;;
				5)														;;
				*)	$BB echo "Error: Invalid option in $backupChoice"	;;
			esac
			ALLINONE=1
			allInOneLoop 1
		fi
	}
	
	backupAllInOneMenu
	
	if $BB [ -z "$1" ]; then
		backupUsage
	fi

	START=$($BB date +%s)
	checkSd

	while $BB test $# -ne 0
	do
		case "$1" in
			-a|--apps)
				removeBackup $BACKUP_DIR/apps
				backupApps
				removeBackup $BACKUP_DIR/data
				backupData
				BANNER=1
			;;
			-nd|--nodata)
				removeBackup $BACKUP_DIR/apps
				backupApps
				BANNER=1
			;;
			-c|--complete)
				removeBackup $BACKUP_DIR/apps
				backupApps
				removeBackup $BACKUP_DIR/data
				backupData
				backupMisc
				BANNER=1
			;;
			-h|-help|--help)
				backupUsage	
			;;
			-l|--logging)
				if $BB [ $LOGGING -eq 0 ]; then
					LOGGING=1
				else
					LOGGING=0
				fi
				BANNER=0	
			;;
			-m|--misc)
				backupMisc
			;;
			-mu|--menu)
				backupAllInOneMenu
			;;
			-r|--remove)
				if $BB [ $PROMPT_REMOVE -eq 0 ]; then
					PROMPT_REMOVE=1
				else
					PROMPT_REMOVE=0
				fi
				BANNER=0		
			;;
			-v|--version)
				$BB echo "`$BB basename $0` $VERSION"
				BANNER=0
			;;
			*)
				backupAnyApp $1
				BANNER=1
			;;
		esac
		shift
	done

	STOP=$($BB date +%s)
	acssiBanner
}

_camsound()
{
  #############################################################
  # Description:
  #    Rename camera sound files to disable the video record 
  #    and camera click sounds
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_camsoundUsage()
	{
		$BB echo "Usage: camsound sound [on|off]"
		$BB echo ""
		$BB echo "Turns the camera sounds (shutter and video cam) on or off"
	}
	
	controlSound()
	{
		if $BB [ -e /system/media/audio/ui/camera_click$1 ]; then
			$BB mv -f /system/media/audio/ui/camera_click$1 /system/media/audio/ui/camera_click$2
		fi
		if $BB [ -f /system/media/audio/ui/VideoRecord$1 ]; then
			$BB mv -f /system/media/audio/ui/VideoRecord$1 /system/media/audio/ui/VideoRecord$2
		fi
		$BB echo Camera sound has been $3.
	}
	
	case $1 in
		off)
			controlSound .ogg .bak disabled
		;;
		on)
			controlSound .bak .ogg enabled
		;;
		*)
			_camsoundUsage
		;;
	esac
}


_compcache()
{
  #############################################################
  # Description:
  #    Toggles compcache ramzswap module on or off
  # Created by:
  #    Jared Rummler (JRummy16) & Slayer
  # Last modified:
  #    9-19-2010
  #
	DEV=/dev/block/ramzswap0
	MODULE=ramzswap.ko
	MODULES_DIR=/system/lib/modules
	
	_compcacheUsage()
	{
	$BB echo "Usage:"
	$BB echo "    compcache [on|off|stats]"
	$BB echo ""
	$BB echo "Turns compcache (in-RAM swap) on or off"
	}
	
	if $BB [ $# == 0 ]; then
		_compcacheUsage
		return
	elif $BB [ ! -e $MODULES_DIR/$MODULE -o -z `which rzscontrol` ]; then
		$BB echo "Error: System does not support compcache."
		return
	fi

	case $1 in
		on|start)
			$BB echo -n "Enabling compcache ... "
			$BB echo 3 > /proc/sys/vm/drop_caches
			$BB insmod $MODULES_DIR/$MODULE
			rzscontrol $DEV --init
			rzscontrol /dev/block/ramzswap0 --init
			$BB swapon $DEV
			$BB echo "done."
		;;
		off|stop)
			$BB echo -n "Disabling compcache ... "
			$BB swapoff $DEV >/dev/null 2>&1
			$BB rmmod $MODULE >/dev/null 2>&1
			$BB echo "done."
		;;
		stats)
			rzcontrol $DEV --stats
		;;
		*)
			_compcacheUsage
	esac
}

_chglog()
{
  #############################################################
  # Description:
  #    View the changelog for various ROMs.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_chglogUsage()
	{
		$BB echo "Usage: chglog"
		$BB echo ""
		$BB echo "Shows the changelog for your current ROM"
	}
	
	if $BB [ $# -gt 0 ]; then
		_chglogUsage
	fi
	
	if $BB [ -z `$BB find /system/etc -type f | $BB grep -i changelog` ]; then	# /system/etc is the most common place.
		$BB echo "Error: changelog not found."
	else
		$BB find /system/etc -type f | $BB cat `$BB grep -i changelog`
		$BB echo ""
		if $BB [ $ALLINONE -eq 1 ]; then
			$BB sleep 10
		fi
	fi
}

_exe()
{
  #############################################################
  # Description:
  #    Makes any file executable.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_exeUsage()
	{
		$BB echo "usage: exe <path to file> <file name>"
		$BB echo ""
		$BB echo "Makes any file executable. You may either enter"
		$BB echo "the full path to the file or the file name."
		$BB echo "Ex: `$BB basename $0` my_script or `$BB basename $0`/system/xbin/my_script"
	}

	if $BB [ $1 == "-help" -o $# == 0 ]; then
		_exeUsage
	elif $BB [ -e $1 ]; then
		$BB chmod 0755 $1
	elif $BB [ ! -z "`$BB find / -iname $1 -type f`" ]; then	# make all files which match the given name executable.
		$BB chmod 0755 "`$BB find / -iname $1 -type f`"
	else
		$BB echo "Error: $1 not found."
		$BB echo ""
		_exeUsage
	fi
}

_fixperms()
{
  #############################################################
  # Description:
  #    Fixes permissions on Android data directories.
  # Created by:
  #    Cyanogen, ankn, smeat, thenefield, farmatito, rikupw
  #    and Kastro ** Slightly modified by JRummy16 **
  # Last modified:
  #    9-9-2010
  #
	
	VERSION="2.04"
	
	# Defaults
	DEBUG=0 # Debug off by default
	LOGGING=1 # Logging on by default
	VERBOSE=1 # Verbose on by default
	
	# Messages
	UID_MSG="Changing user ownership for:"
	GID_MSG="Changing group ownership for:"
	PERM_MSG="Changing permissions for:"
	
	# Initialise vars
	CODEPATH=""
	UID=""
	GID=""
	PACKAGE=""
	REMOVE=0
	NOSYSTEM=0
	ONLY_ONE=""
	SIMULATE=0
	DATAMOUNT=0
	SYSSDMOUNT=0
	fpStartTIME=$( $BB date +"%m-%d-%Y %H:%M:%S" )
	fpStartEPOCH=$( $BB date +%s )
	
	if $BB test "$SD_EXT_DIRECTORY" = ""; then
		#check for mount point, /system/sd included in tests for backward compatibility
		for MP in /sd-ext /system/sd; do
			if $BB test -d $MP; then
				SD_EXT_DIRECTORY=$MP
				break
			fi
		done
	fi
	
	_fixpermsUsage()
	{
		$BB echo "Usage fixpers [OPTIONS] [APK_PATH]"
		$BB echo "      -d         turn on debug"
		$BB echo "      -f         fix only package APK_PATH"
		$BB echo "      -l         disable logging for this run (faster)"
		$BB echo "      -r         remove stale data directories"
		$BB echo "                 of uninstalled packages while fixing permissions"
		$BB echo "      -s         simulate only"
		$BB echo "      -u         check only non-system directories"
		$BB echo "      -v         disable verbosity for this run (less output)"
		$BB echo "      -V         print version"
		$BB echo "      -h         this help"
	}
	
	fpParseargs()
	{
	  # Parse options
		while $BB test $# -ne 0; do
			case "$1" in
				-d)
					DEBUG=1
				;;
				-f)
					if $BB test $# -lt 2; then
						$BB echo "$0: missing argument for option $1"
						exit 1
					else
						if $BB test $( $BB echo $2 | $BB cut -c1 ) != "-"; then
							ONLY_ONE=$2
							shift;
						else
							$BB echo "$0: missing argument for option $1"
						exit 1
						fi
					fi
				;;
				-r)
					REMOVE=1
				;;
				-s)
					SIMULATE=1
				;;
				-l)
					if $BB test $LOGGING -eq 0; then
						LOGGING=1
					else
						LOGGING=0
					fi
				;;
				-v)
					if $BB test $VERBOSE -eq 0; then
						VERBOSE=1
					else
						VERBOSE=0
					fi
				;;
				-u)
					NOSYSTEM=1
				;;
				-V)
					$BB echo "$0 $VERSION"
					exit 0
				;;
				-h)
					_fixpermsUsage
					exit 0
				;;
				-*)
					$BB echo "$0: unknown option $1"
					$BB echo
					_fixpermsUsage
					exit 1
				;;
			esac
			shift;
		done
	}
	
	fpPrint()
	{
		MSG=$@
		if $BB test $LOGGING -eq 1; then
			$BB echo $MSG | $BB tee -a $LOG_FILE
		else
			$BB echo $MSG
		fi
	}
	
	fpStart()
	{

		if $BB test $( $BB grep -c " /data " "/proc/mounts" ) -eq 0; then
			$BB mount /data > /dev/null 2>&1
			DATAMOUNT=1
		fi

		if $BB test -e /dev/block/mmcblk0p2 && $BB test $( $BB grep -c " $SD_EXT_DIRECTORY " "/proc/mounts" ) -eq 0; then
			$BB mount $SD_EXT_DIRECTORY > /dev/null 2>&1
			SYSSDMOUNT=1
		fi

		if $BB test $( $BB mount | $BB grep -c /sdcard ) -eq 0; then
			LOG_FILE="/data/fix_permissions.log"
		else
			LOG_FILE="/sdcard/fix_permissions.log"
		fi
		if $BB test ! -e "$LOG_FILE"; then
			> $LOG_FILE
		fi
	   
	   fpPrint "$0 $VERSION started at $fpStartTIME"
	}
	
	fpChownUid()
	{
		FP_OLDUID=$1
		FP_UID=$2
		FP_FILE=$3

		#if user ownership doesn't equal then change them
		if $BB test "$FP_OLDUID" != "$FP_UID"; then
			if $BB test $VERBOSE -ne 0; then
				fpPrint "$UID_MSG $FP_FILE from '$FP_OLDUID' to '$FP_UID'"
			fi
			if $BB test $SIMULATE -eq 0; then
				$BB chown $FP_UID "$FP_FILE"
			fi
		fi
	}
	
	fpChownGid()
	{
		FP_OLDGID=$1
		FP_GID=$2
		FP_FILE=$3

		#if group ownership doesn't equal then change them
		if $BB test "$FP_OLDGID" != "$FP_GID"; then
			if $BB test $VERBOSE -ne 0; then
				fpPrint "$GID_MSG $FP_FILE from '$FP_OLDGID' to '$FP_GID'"
			fi
			if $BB test $SIMULATE -eq 0; then
				$BB chown :$FP_GID "$FP_FILE"
			fi
		fi
	}
	
	fpChmod()
	{
		FP_OLDPER=$1
		FP_OLDPER=$( $BB echo $FP_OLDPER | cut -c2-10 )
		FP_PERSTR=$2
		FP_PERNUM=$3
		FP_FILE=$4

		#if the permissions are not equal
		if $BB test "$FP_OLDPER" != "$FP_PERSTR"; then
			if $BB test $VERBOSE -ne 0; then
				fpPrint "$PERM_MSG $FP_FILE from '$FP_OLDPER' to '$FP_PERSTR' ($FP_PERNUM)"
			fi
			#change the permissions
			if $BB test $SIMULATE -eq 0; then
				$BB chmod $FP_PERNUM "$FP_FILE"
			fi
		fi
	}
	
	fpAll()
	{
		FP_NUMS=$( $BB cat /data/system/packages.xml | $BB egrep "^<package.*serId" | $BB grep -v framework-res.apk | $BB grep -v com.htc.resources.apk | $BB wc -l )
		I=0
		$BB cat /data/system/packages.xml | $BB egrep "^<package.*serId" | $BB grep -v framework-res.apk | $BB grep -v com.htc.resources.apk | while read all_line; do
			I=$( $BB expr $I + 1 )
			fpPackage "$all_line" $I $FP_NUMS
		done
	}
	
	fpSingle()
	{
		FP_SFOUND=$( $BB cat /data/system/packages.xml | $BB egrep "^<package.*serId" | $BB grep -v framework-res.apk | $BB grep -v com.htc.resources.apk | $BB grep -i $ONLY_ONE | $BB wc -l )
		if $BB test $FP_SFOUND -gt 1; then
			fpPrint "Cannot perform single operation on $FP_SFOUND matched package(s)."
		elif $BB test $FP_SFOUND = "" -o $FP_SFOUND -eq 0; then
			fpPrint "Could not find the package you specified in the packages.xml file."
		else
			FP_SPKG=$( $BB cat /data/system/packages.xml | $BB egrep "^<package.*serId" | $BB grep -v framework-res.apk | $BB grep -v com.htc.resources.apk | $BB grep -i $ONLY_ONE )
			fpPackage "${FP_SPKG}" 1 1
		fi
	}
	
	fpPackage()
	{
		pkgline=$1
		curnum=$2
		endnum=$3
		CODEPATH=$( $BB echo $pkgline | $BB sed 's%.* codePath="\(.*\)".*%\1%' |  $BB cut -d '"' -f1 )
		PACKAGE=$( $BB echo $pkgline | $BB sed 's%.* name="\(.*\)".*%\1%' | $BB cut -d '"' -f1 )
		UID=$( $BB echo $pkgline | $BB sed 's%.*serId="\(.*\)".*%\1%' |  $BB cut -d '"' -f1 )
		GID=$UID
		APPDIR=$( $BB echo $CODEPATH | $BB sed 's%^\(.*\)/.*%\1%' )
		APK=$( $BB echo $CODEPATH | $BB sed 's%^.*/\(.*\..*\)$%\1%' )
		
		#debug
		if $BB test $DEBUG -eq 1; then
			fpPrint "CODEPATH: $CODEPATH APPDIR: $APPDIR APK:$APK UID/GID:$UID:$GID"
		fi
		
		#check for existence of apk
		if $BB test -e $CODEPATH;  then
			fpPrint "Processing ($curnum of $endnum): $PACKAGE..."

			#lets get existing permissions of CODEPATH
			OLD_UGD=$( $BB ls -ln "$CODEPATH" )
			OLD_PER=$( $BB echo $OLD_UGD | $BB cut -d ' ' -f1 )
			OLD_UID=$( $BB echo $OLD_UGD | $BB cut -d ' ' -f3 )
			OLD_GID=$( $BB echo $OLD_UGD | $BB cut -d ' ' -f4 )

			#apk source dirs
			if $BB test "$APPDIR" = "/system/app"; then
				#skip system apps if set
				if $BB test "$NOSYSTEM" = "1"; then
					fpPrint "***SKIPPING SYSTEM APP ($PACKAGE)!"
					return
				fi
				fpChownUid $OLD_UID 0 "$CODEPATH"
				fpChownGid $OLD_GID 0 "$CODEPATH"
				fpChmod $OLD_PER "rw-r--r--" 644 "$CODEPATH"
			elif $BB test "$APPDIR" = "/data/app" || $BB test "$APPDIR" = "/sd-ext/app"; then
				fpChownUid $OLD_UID 1000 "$CODEPATH"
				fpChownGid $OLD_GID 1000 "$CODEPATH"
				fpChmod $OLD_PER "rw-r--r--" 644 "$CODEPATH"
			elif $BB test "$APPDIR" = "/data/app-private" || $BB test "$APPDIR" = "/sd-ext/app-private"; then
				fpChownUid $OLD_UID 1000 "$CODEPATH"
				fpChownGid $OLD_GID $GID "$CODEPATH"
				fpChmod $OLD_PER "rw-r-----" 640 "$CODEPATH"
			fi
		else
			fpPrint "$CODEPATH does not exist ($curnum of $endnum). Reinstall..."
			if $BB test $REMOVE -eq 1; then
				if $BB test -d /data/data/$PACKAGE ; then
					fpPrint "Removing stale dir /data/data/$PACKAGE"
					if $BB test $SIMULATE -eq 0 ; then
						$BB rm -R /data/data/$PACKAGE
					fi
				fi
			fi
		fi
		
		#the data/data for the package
		if $BB test -d "/data/data/$PACKAGE"; then
			#find all directories in /data/data/$PACKAGE
			$BB find /data/data/$PACKAGE -type d -exec $BB ls -ldn {} \; | while read dataline; do
				#get existing permissions of that directory
				OLD_PER=$( $BB echo $dataline | $BB cut -d ' ' -f1 )
				OLD_UID=$( $BB echo $dataline | $BB cut -d ' ' -f3 )
				OLD_GID=$( $BB echo $dataline | $BB cut -d ' ' -f4 )
				FILEDIR=$( $BB echo $dataline | $BB cut -d ' ' -f9 )
				FOURDIR=$( $BB echo $FILEDIR | $BB cut -d '/' -f5 )
				
				#set defaults for iteration
				ISLIB=0
				REVPERM=755
				REVPSTR="rwxr-xr-x"
				REVUID=$UID
				REVGID=$GID
				
				if $BB test "$FOURDIR" = ""; then
					#package directory, perms:755 owner:$UID:$GID
					fpChmod $OLD_PER "rwxr-xr-x" 755 "$FILEDIR"
				elif $BB test "$FOURDIR" = "lib"; then
					#lib directory, perms:755 owner:1000:1000
					#lib files, perms:755 owner:1000:1000
					ISLIB=1
					REVPERM=755
					REVPSTR="rwxr-xr-x"
					REVUID=1000
					REVGID=1000
					fpChmod $OLD_PER "rwxr-xr-x" 755 "$FILEDIR"
				elif $BB test "$FOURDIR" = "shared_prefs"; then
					#shared_prefs directories, perms:771 owner:$UID:$GID
					#shared_prefs files, perms:660 owner:$UID:$GID
					REVPERM=660
					REVPSTR="rw-rw----"
					fpChmod $OLD_PER "rwxrwx--x" 771 "$FILEDIR"
				elif $BB test "$FOURDIR" = "databases"; then
					#databases directories, perms:771 owner:$UID:$GID
					#databases files, perms:660 owner:$UID:$GID
					REVPERM=660
					REVPSTR="rw-rw----"
					fpChmod $OLD_PER "rwxrwx--x" 771 "$FILEDIR"
				elif $BB test "$FOURDIR" = "cache"; then
					#cache directories, perms:771 owner:$UID:$GID
					#cache files, perms:600 owner:$UID:GID
					REVPERM=600
					REVPSTR="rw-------"
					fpChmod $OLD_PER "rwxrwx--x" 771 "$FILEDIR"
				else
					#other directories, perms:771 owner:$UID:$GID
					REVPERM=771
					REVPSTR="rwxrwx--x"
					fpChmod $OLD_PER "rwxrwx--x" 771 "$FILEDIR"
				fi
				
				#change ownership of directories matched
				if $BB test "$ISLIB" = "1"; then
					fpChownUid $OLD_UID 1000 "$FILEDIR"
					fpChownGid $OLD_GID 1000 "$FILEDIR"
				else
					fpChownUid $OLD_UID $UID "$FILEDIR"
					fpChownGid $OLD_GID $GID "$FILEDIR"
				fi
				
				#if any files exist in directory with improper permissions reset them
				$BB find $FILEDIR -type f -maxdepth 1 ! -perm $REVPERM -exec $BB ls -ln {} \; | while read subline; do
					OLD_PER=$( $BB echo $subline | $BB cut -d ' ' -f1 )
					SUBFILE=$( $BB echo $subline | $BB cut -d ' ' -f9 )
					fpChmod $OLD_PER $REVPSTR $REVPERM "$SUBFILE"
				done
				
				#if any files exist in directory with improper user reset them
				$BB find $FILEDIR -type f -maxdepth 1 ! -user $REVUID -exec $BB ls -ln {} \; | while read subline; do
					OLD_UID=$( $BB echo $subline | $BB cut -d ' ' -f3 )
					SUBFILE=$( $BB echo $subline | $BB cut -d ' ' -f9 )
					fpChownUid $OLD_UID $REVUID "$SUBFILE"
				done
				
				#if any files exist in directory with improper group reset them
				$BB find $FILEDIR -type f -maxdepth 1 ! -group $REVGID -exec $BB ls -ln {} \; | while read subline; do
					OLD_GID=$( $BB echo $subline | $BB cut -d ' ' -f4 )
					SUBFILE=$( $BB echo $subline | $BB cut -d ' ' -f9 )
					fpChownGid $OLD_GID $REVGID "$SUBFILE"
				done
			done
		fi
	}
	
	dateDiff()
	{
		if $BB test $# -ne 2; then
			FP_DDM="E"
			FP_DDS="E"
			return
		fi
		FP_DDD=$( $BB expr $2 - $1 )
		FP_DDM=$( $BB expr $FP_DDD / 60 )
		FP_DDS=$( $BB expr $FP_DDD % 60 )
	}
	
	fpEnd()
	{
		if $BB test $SYSSDMOUNT -eq 1; then
			$BB umount $SD_EXT_DIRECTORY > /dev/null 2>&1
		fi

		if $BB test $DATAMOUNT -eq 1; then
			$BB umount /data > /dev/null 2>&1
		fi

		fpEndTIME=$( $BB date +"%m-%d-%Y %H:%M:%S" )
		fpEndEPOCH=$( $BB date +%s )

		dateDiff $fpStartEPOCH $fpEndEPOCH

		fpPrint "$0 $VERSION ended at $fpEndTIME (Runtime:${FP_DDM}m${FP_DDS}s)"
	}
	
	# MAIN SCRIPT:
	
	$BB echo ""
	$BB echo "**********************************"
	$BB echo "*** Fixing permissions ..."
	$BB echo "**********************************"
	$BB echo ""
	
	fpParseargs $@
	fpStart
	if $BB test "$ONLY_ONE" != "" -a "$ONLY_ONE" != "0" ; then
	   fpSingle "$ONLY_ONE"
	else
	   fpAll
	fi
	fpEnd
}

_flashrec()
{
  #############################################################
  # Description:
  #    Downloads and flashes commonly used recoveries.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-13-2010
  #
	FLASH_IMAGE_URL="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/flash_image"
	CLOCKWORK_URL="http://koush.tandtgaming.com/recoveries/recovery-clockwork-2.5.0.1-sholes.img"
	SPRECOVERY_URL="http://downloads.droidmod.org/recovery-0.99.3b.img"
	
	_flashrecUsage()
	{
		$BB echo "Usage: flashrec [-c|-s]"
		$BB echo ""
		$BB echo "options:"
		$BB echo "        -c	Flashes ClockWork Recovery."
		$BB echo "        -s	Flashes SPRecovery."

	}
	
	checkFlashImage()
	{
		if $BB [ ! -e /system/bin/flash_image -a ! -e /system/xbin/flash_image ]; then
			$BB echo "Downloading flash_image binary ... "
			$BB wget $FLASH_IMAGE_URL -O /system/bin/flash_image
			$BB chmod 0755 /system/bin/flash_image
		fi
	}
	
	flashRecovery()
	{
		checkDevice sholes return
		checkFlashImage
		if $BB [ ! -e /sdcard/goodies/recovery/`$BB basename $1` ]; then
			$BB echo "Downloading recovery image ... "
			$BB mkdir -p /sdcard/goodies/recovery
			$BB wget $1 -O /sdcard/goodies/recovery/`$BB basename $1`
		fi
		
		$BB echo -n "Flashing `$BB basename $1` ... "
		flash_image recovery /sdcard/goodies/recovery/`$BB basename $1` > /dev/nul 2>&1
		$BB echo "done."
	}
	
	case $1 in
		-c|--clockwork)
			flashRecovery $CLOCKWORK_URL
		;;
		-s|--sprecovery)
			flashRecovery $SPRECOVERY_URL
		;;
		*)
			_flashrecUsage
		;;
	esac
}

_freemem()
{
  #############################################################
  # Description:
  #    Set up the memfree task killer to leave a certain
  #    amount of ram free.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-17-2010
  #
	AT_BOOT=0
	
	_freememUsage()
	{
		$BB echo "Usage: freemem [-b|50mb|75mb|100mb|default]"
		$BB echo ""
		$BB echo "Configures the system to enusre that at least a given"
		$BB echo "amount of RAM is always available. -b flag will set the"
		$BB echo "given value at boot."
	}
	
	freeMemoryWarning()
	{
		$BB echo "Changing the memfree task killer to keep $1 of RAM may"
		$BB echo "have a negative effect on your system and is not recommended."
		$BB echo " "
		$BB echo -n "Would you like to continue despite this warning? (y/n): "
		read warningChoice
		case $warningChoice in
			y|Y)																;;
			n|N)	exit														;;
			*)		$BB echo "Error: Invalid option in $warningChoice" ; exit	;;
		esac
	}
	
	freeMemory()
	{
		if $BB [ $AT_BOOT -eq 1 ]; then
			$BB echo -n "Setting $($BB expr $6 \* 4 / 1024)mb of RAM free at boot ... "
			$BB sed -i -e "s|$INIT_MEMKILLER.*|$INIT_MEMKILLER $1,$2,$3,$4,$5,$6|g" init.rc
			$BB echo "done"
		else
			$BB echo -n "Keeping $($BB expr $6 \* 4 / 1024)mb of RAM free ... "
			$BB echo "$1,$2,$3,$4,$5,$6" > /sys/module/lowmemorykiller/parameters/minfree
			$BB echo "done."
		fi	
	}
	
	while $BB test $# -ne 0
	do
		case $1 in
			-b)					AT_BOOT=1															;;
			50|50mb)			freeMemoryWarning 50 ; freeMemory 2560 3840 6400 7680 10240 12800	;;
			75|75mb)			freeMemoryWarning 75 ; freeMemory 2560 3840 6400 10240 12800 19200	;;
			100|100mb)			freeMemoryWarning 100 ; freeMemory 2560 3840 6400 12800 12800 25600	;;
			25|25mb|default)	freeMemory 1536 2048 4096 5120 5632 6144							;;
			*)					_freememUsage														;;
		esac
		shift;
	done
}

_install_zip()
{
  #############################################################
  # Description:
  #    A sort of terminal version of "Rom Manager". Downloads
  #    lists of update packages and installs them through
  #    clockwork recovery.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-20-2010
  #
	UPDATE_PACKAGE_LIST="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/package.list"
	KERNEL_PACKAGE_LIST="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/kernel.list"
	
	_install_zipUsage()
	{
		$BB echo "Usage: install_zip [-m|-k|<path/to/zip]"
		$BB echo ""
		$BB echo "Options:"
		$BB echo "    -m             List of all update packages to flash"
		$BB echo "    -k             List of kernels to flash"
		$BB echo "    <path/to/zip>  Reboots to recovery and flashes specified zip"
		$BB echo ""
		$BB echo "This script acts as an old school \"rom manager\""
		$BB echo "in that the list of packages can update regulary"
		$BB echo "and zips can automatically be installed"
	}
	
	ghettoRomManager()
	{
		checkSd
		checkDevice sholes return
		$BB mkdir -p $DROIDBOX_DIR_EXTERNAL/files
		$BB echo -n "Downloading list of available packages ... "
		$BB wget -q $1 -O $DROIDBOX_DIR_EXTERNAL/files/update_package.list
		$BB echo "done."

		LIST=1
		$BB echo ""
		$BB echo "========================================"
		for update_package in `$BB cat $DROIDBOX_DIR_EXTERNAL/files/update_package.list | $BB awk '{print $1}'`
		do
			$BB echo " $LIST  $update_package" | $BB sed 's|_| |g'
			LIST=$( $BB expr $LIST + 1 )
		done
		$BB echo " $LIST  Exit this menu"
		$BB echo "========================================"
		$BB echo ""
		$BB echo -n "Please choose a number: "
		read installChoice
		$BB echo ""

		if $BB [ $installChoice == $LIST ]; then
			return
		elif $BB [ -z "`$BB sed -n "$installChoice{p;q;}" $DROIDBOX_DIR_EXTERNAL/files/update_package.list`" ]; then
			$BB echo "Error: Invalid choice in $installChoice"
			return
		fi
		
		UPDATE_PACKAGE=$( $BB sed -n "$installChoice{p;q;}" $DROIDBOX_DIR_EXTERNAL/files/update_package.list | $BB awk '{print $2}' )
		
		$BB echo -n "Are you sure you want to continue and install `$BB basename $UPDATE_PACKAGE`? (y/n): "
		read check
		case $check in
			y|Y)
				$BB echo "Downloading `$BB basename $UPDATE_PACKAGE` ... "
				$BB wget $UPDATE_PACKAGE -O $DROIDBOX_DIR_EXTERNAL/files/`$BB basename $UPDATE_PACKAGE`
				$BB echo -n "Preparing for install ... "
				$BB mkdir -p /cache/recovery
				$BB echo "install_zip SDCARD:"`$BB echo "$DROIDBOX_DIR_EXTERNAL/files/$( $BB basename $UPDATE_PACKAGE)" | $BB sed 's|/sdcard/||'`"" >> /cache/recovery/extendedcommand
				$BB echo "done."
				$BB echo ""
				$BB echo "Rebooting into recovery to apply update package ... "
				$BB sleep 2
				_rb --recovery
			;;
			n|N)
				$BB echo "Installation aborted."
				return
			;;
			*)
				$BB echo "Error: Invalid option in $check"
				return
			;;
		esac
	}
	
	case $1 in
		-m|--menu)
			ghettoRomManager $UPDATE_PACKAGE_LIST
		;;
		-k|--kernels)
			ghettoRomManager $KERNEL_PACKAGE_LIST
		;;
		*)
			if $BB [ $# == 0 ]; then
				_install_zipUsage
				return
			fi
			
			checkSd
			checkDevice sholes return
			if $BB [ -e $1 ]; then
				UPDATE_PACKAGE="$1"
			# check for matching file name:
			elif $BB [ ! -z "`$BB find /sdcard -iname $1 -type f`" ] && [ `$BB find /sdcard -iname $1 -type f | $BB wc -l` -eq 1 ]; then
				UPDATE_PACKAGE=$( $BB find / -iname $1 -type f )
			else
				$BB echo "Error: $1 not found."
				$BB echo ""
				_install_zipUsage
				return
			fi
			$BB echo -n "Are you sure you want to continue and install $UPDATE_PACKAGE? (y/n): "
			read checkInstall
			case $checkInstall in
				y|Y)
					$BB echo 
					$BB echo "Preparing to install $UPDATE_PACKAGE ... "
					$BB mkdir -p /cache/recovery
					$BB echo "install_zip SDCARD:"`$BB echo $UPDATE_PACKAGE | $BB sed 's|/sdcard/||'`"" >> /cache/recovery/extendedcommand
					$BB echo "done."
					$BB echo ""
					$BB echo "Rebooting into recovery to install $UPDATE_PACKAGE ... "
					$BB sleep 2
					_rb --recovery > /dev/null
				;;
				n|N)
					$BB echo "Installation aborted."
					return
				;;
				*)
					$BB echo "Error: Invalid option in $checkInstall"
					return
				;;
			esac
		;;
	esac
}

_load()
{
  #############################################################
  # Description:
  #    Installs custom boot animations, extra apps, custom
  #    fonts and live wallpapers.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_loadUsage()
	{
		$BB echo " Usage: load [ba|exa|fs|lwp]"
		$BB echo ""
		$BB echo " options:"
		$BB echo ""
		$BB echo "  ba  | --bootani    Lists bootanimations to install"
		$BB echo "  exa | --extraapps  Lists extra apps to install"
		$BB echo "  fs  | --fonts      Lists custom fonts to install"
		$BB echo "  lwp | --livewalls  Lists custom live wallpapers to install"
	}
	
	installBootAnimations()
	{
		BOOTANIMATION_DIR=/sdcard/goodies/bootanimations
		
		loadBootAnimation()
		{
			if $BB [ ! -e $BOOTANIMATION_DIR/$1/bootanimation.zip ]; then
				$BB echo "Downloading bootanimation ..."
				$BB mkdir -p $BOOTANIMATION_DIR/$1
				$BB wget $2 -O $BOOTANIMATION_DIR/$1/bootanimation.zip
			fi
			$BB echo -n "Removing old bootanimation.zip ... "
			$BB find /system/media /data/local -name bootanimation.zip -exec $BB rm -f {} ';'
			$BB echo "done."
			$BB echo -n "Installing bootanimation.zip ... "
			$BB cp -f $BOOTANIMATION_DIR/$1/bootanimation.zip /data/local
			$BB chmod 0655 /data/local/bootanimation.zip
			$BB echo "done."
		}
		
		$BB echo "----------------------------------------------------------"
		$BB echo "1   Banana                  29  Galaxy"
		$BB echo "2   Blood                   30  GundamMech"
		$BB echo "3   Cyanogen by Prash       31  Halo 3 Logo"
		$BB echo "4   Cyanogen by Cole2044    32  Hello Droid"
		$BB echo "5   Cyberchaos              33  Joe Droid"
		$BB echo "6   Froyo                   34  Matrix"
		$BB echo "7   Droid X                 35  Matrix Blue Topsy"
		$BB echo "8   Matrix                  36  Matrix Droid"
		$BB echo "9   Nexus1                  37  Matrix Droid Blue"
		$BB echo "10  Original Droid Eye      38  Midnight"
		$BB echo "11  Pink-Life               39  Modern Warfare 2"
		$BB echo "12  Rotting Apple           40  Moving Droid Eye"
		$BB echo "13  Stick Fight             41  Multicolor"
		$BB echo "14  Super Mario             42  Radar3ds Compilation"
		$BB echo "15  Spinning Droid          43  Redwings"
		$BB echo "16  Alex Grey Bardobeing    44  Rotting Apple"
		$BB echo "17  Aperture_Science        45  SAC"
		$BB echo "18  Bassist                 46  Sackboy"
		$BB echo "19  Blackground Blue Eyes   47  Shakugan"
		$BB echo "20  Blackground Red Eyes    48  Smokey Android"
		$BB echo "21  Cylon                   49  Spiral"
		$BB echo "22  Dancing Droids          50  Star Trek"
		$BB echo "23  Dancing Man             51  Star Wars Rebel Alliance"
		$BB echo "24  Decepticon              52  Star Wars Title"
		$BB echo "25  Droid-Life              53  Windows 7 Loading"
		$BB echo "26  DroidMod                54  Windows 7 Nexus"
		$BB echo "27  Eyes                    55  Yellow Boot"
		$BB echo "28  Eyes Fullscreen         56  Exit this menu."
		$BB echo "----------------------------------------------------------"
		$BB echo -n "Please choose a number: "
		read bootAniChoice
		case $bootAniChoice in
			1)	loadBootAnimation banana "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/banana/bootanimation.zip"				;;
			2)	loadBootAnimation blood "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/blood/bootanimation.zip"					;;
			3)	loadBootAnimation cyanogen2 "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/cyanogen2/bootanimation.zip"			;;
			4)	loadBootAnimation cyanogen3 "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/cyanogen3/bootanimation.zip"			;;
			5)	loadBootAnimation cyberchaos "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/cyberchaos/bootanimation.zip"		;;
			6)	loadBootAnimation droidx "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/droidx/bootanimation.zip"				;;
			7)	loadBootAnimation froyo "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/froyo/bootanimation.zip"					;;
			8)	loadBootAnimation matrix "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/matrix/bootanimation.zip"				;;
			9)	loadBootAnimation nexus "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/nexus/bootanimation.zip"					;;
			10)	loadBootAnimation originalboot "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/originalboot/bootanimation.zip"	;;
			11)	loadBootAnimation pinklife "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/pinklife/bootanimation.zip"			;;
			12)	loadBootAnimation rottingapple "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/rottingapple/bootanimation.zip"	;;
			13)	loadBootAnimation stickfight "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/stickfight/bootanimation.zip"		;;
			14)	loadBootAnimation supermario "http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/bootanimations/supermario/bootanimation.zip"		;;
			15)	loadBootAnimation Spinning_Droid "http://droidboots.com/http//droidboots.com/downloads/bootanimations/spinning_droid.zip"								;;
			16)	loadBootAnimation Alex_Grey_Bardobeing "http://droidboots.com/http//droidboots.com/downloads/bootanimations/alex_grey.zip"								;;
			17)	loadBootAnimation Aperture_Science "http://droidboots.com/http//droidboots.com/downloads/bootanimations/aperturescience.zip"							;;
			18)	loadBootAnimation Bassist "http://droidboots.com/http//droidboots.com/downloads/bootanimations/bassist.zip"												;;
			19)	loadBootAnimation Blackground_Blue_Eyes "http://droidboots.com/http//droidboots.com/downloads/bootanimations/blackblueeyes.zip"							;;
			20)	loadBootAnimation Blackground_Red_Eyes "http://droidboots.com/http//droidboots.com/downloads/bootanimations/blackredeyes.zip"							;;
			21)	loadBootAnimation Cylon "http://droidboots.com/http//droidboots.com/downloads/bootanimations/cylon.zip"													;;
			22)	loadBootAnimation Dancing_Droids "http://droidboots.com/http//droidboots.com/downloads/bootanimations/dancing_droids.zip"								;;
			23)	loadBootAnimation Dancing_Man "http://droidboots.com/http//droidboots.com/downloads/bootanimations/dancing_man.zip"										;;
			24)	loadBootAnimation Decepticon "http://droidboots.com/http//droidboots.com/downloads/bootanimations/decepticon.zip"										;;
			25)	loadBootAnimation Droid-Life "http://droidboots.com/http//droidboots.com/downloads/bootanimations/Droidlife.zip"										;;
			26)	loadBootAnimation DroidMod "http://droidboots.com/http//droidboots.com/downloads/bootanimations/droidmod.zip"											;;
			27)	loadBootAnimation Eyes "http://droidboots.com/http//droidboots.com/downloads/bootanimations/blue_eyes.zip"												;;
			28)	loadBootAnimation Eyes_Fullscreen "http://droidboots.com/http//droidboots.com/downloads/bootanimations/eyes_full.zip"									;;
			29)	loadBootAnimation Galaxy "http://droidboots.com/http//droidboots.com/downloads/bootanimations/galaxy.zip"												;;
			30)	loadBootAnimation GundamMech "http://droidboots.com/http//droidboots.com/downloads/bootanimations/GundamMech.zip"										;;
			31)	loadBootAnimation Halo_3_Logo "http://droidboots.com/http//droidboots.com/downloads/bootanimations/halo3_logo.zip"										;;
			32)	loadBootAnimation Hello_Droid "http://droidboots.com/http//droidboots.com/downloads/bootanimations/hellodroid.zip"										;;
			33)	loadBootAnimation Joe_Droid "http://droidboots.com/http//droidboots.com/downloads/bootanimations/joe.zip"												;;
			34)	loadBootAnimation Matrix "http://droidboots.com/http//droidboots.com/downloads/bootanimations/matrix_topsy.zip"											;;
			35)	loadBootAnimation Matrix_Blue_Topsy "http://droidboots.com/http//droidboots.com/downloads/bootanimations/matrix_blue_topsy.zip"							;;
			36)	loadBootAnimation Matrix_Droid "http://droidboots.com/http//droidboots.com/downloads/bootanimations/matrix_droid.zip"									;;
			37)	loadBootAnimation Matrix_Droid_Blue "http://droidboots.com/http//droidboots.com/downloads/bootanimations/matrix_droid_blue.zip"							;;
			38)	loadBootAnimation Midnight "http://droidboots.com/http//droidboots.com/downloads/bootanimations/midnight.zip"											;;
			39)	loadBootAnimation Modern_Warfare_2 "http://droidboots.com/http//droidboots.com/downloads/bootanimations/mw2_full.zip"									;;
			40)	loadBootAnimation Moving_Droid_Eye "http://droidboots.com/http//droidboots.com/downloads/bootanimations/movingeye.zip"									;;
			41)	loadBootAnimation Multicolor "http://droidboots.com/http//droidboots.com/downloads/bootanimations/Multicolor.zip"										;;
			42)	loadBootAnimation Radar3ds_Compilation "http://droidboots.com/http//droidboots.com/downloads/bootanimations/Radar3d.zip"								;;
			43)	loadBootAnimation Redwings "http://droidboots.com/http//droidboots.com/downloads/bootanimations/Redwings.zip"											;;
			44)	loadBootAnimation Rotting_Apple "http://droidboots.com/http//droidboots.com/downloads/bootanimations/rotting_apple.zip"									;;
			45)	loadBootAnimation SAC "http://droidboots.com/http//droidboots.com/downloads/bootanimations/SAC.zip"														;;
			46)	loadBootAnimation Sackboy "http://droidboots.com/http//droidboots.com/downloads/bootanimations/sackboy.zip"												;;
			47)	loadBootAnimation Shakugan "http://droidboots.com/http//droidboots.com/downloads/bootanimations/shakugan.zip"											;;
			48)	loadBootAnimation Smokey_Android "http://droidboots.com/http//droidboots.com/downloads/bootanimations/smokey_android.zip"								;;
			49)	loadBootAnimation Spiral "http://droidboots.com/http//droidboots.com/downloads/bootanimations/spiral.zip"												;;
			50)	loadBootAnimation Star_Trek "http://droidboots.com/http//droidboots.com/downloads/bootanimations/star_trek.zip"											;;
			51)	loadBootAnimation Star_Wars_Rebel_Alliance "http://droidboots.com/http//droidboots.com/downloads/bootanimations/rebel.zip"								;;
			52)	loadBootAnimation Star_Wars_Title "http://droidboots.com/http//droidboots.com/downloads/bootanimations/swtitle.zip"										;;
			53)	loadBootAnimation Windows_7_Loading "http://droidboots.com/http//droidboots.com/downloads/bootanimations/win7.zip"										;;
			54)	loadBootAnimation Windows_7_Nexus "http://droidboots.com/http//droidboots.com/downloads/bootanimations/win7_nexus.zip"									;;
			55)	loadBootAnimation Yellow_Boot "http://droidboots.com/http//droidboots.com/downloads/bootanimations/yellowboot.zip"										;;
			56)																																							;;
			*)	$BB echo "Error: Invalid option in $bootAniChoice"																										;;
		esac
	}

	installLiveWallpapers()
	{
		LIVEWALLPAPER_DIR=/sdcard/goodies/livewallpapers
			
		loadLiveWallpaper()
		{
			LIVEWALLPAPER_URL="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/livewallpapers/$1/LiveWallpapers.apk"
			
			if $BB [ ! -e $LIVEWALLPAPER_DIR/$1/LiveWallpapers.apk ]; then
				$BB echo "Downloading Live Wallpaper ... "
				$BB mkdir -p $LIVEWALLPAPER_DIR/$1
				$BB wget $LIVEWALLPAPER_URL -O $LIVEWALLPAPER_DIR/$1/LiveWallpapers.apk	
			fi
			$BB echo -n "Installing Live Wallpaper ... "
			$BB cp -f $LIVEWALLPAPER_DIR/$1/LiveWallpapers.apk /system/app
			$BB echo "done."
		}
		
		$BB echo "----------------------------------------------------------"
		$BB echo "1   Android 1            19  Neural Network Green"
		$BB echo "2   Android 2            20  Neural Network Red"
		$BB echo "3   Android 3            21  Electric"
		$BB echo "4   ArrowD Blue          22  Live Strong"
		$BB echo "5   ArrowD Green         23  Marley"
		$BB echo "6   ArrowD Pink          24  Nexus 1"
		$BB echo "7   BBoy                 25  Nexus 2"
		$BB echo "8   Bio Water            26  Nexus 3"
		$BB echo "9   BlueDotGrid          27  Nexus 4"
		$BB echo "10  Blue Dots            28  Nova Blue"
		$BB echo "11  CyanogenMod Girls    29  Nova Green"
		$BB echo "12  150 Colors           30  Nova Cyan"
		$BB echo "13  Cyan Droid           31  Kangerade (NexusMod like)"
		$BB echo "14  Droid 1              32  RainBokeh"
		$BB echo "15  Droid 2              33  Surf Droid"
		$BB echo "16  Droid 3              34  T.A.R.D.I.S."
		$BB echo "17  Droid 4              35  Original"
		$BB echo "18  Neural Network Blue  36  Exit this menu."
		$BB echo "----------------------------------------------------------"
		$BB echo -n "Please choose a number: "
		read lwpChoice
		case $lwpChoice in
			1)	loadLiveWallpaper lwpandroid1					;;
			2)	loadLiveWallpaper lwpandroid2					;;
			3)	loadLiveWallpaper lwpandroid3					;;
			4)	loadLiveWallpaper lwparrowdblue					;;
			5)	loadLiveWallpaper lwparrowdgreen				;;
			6)	loadLiveWallpaper lwparrowdpink					;;
			7)	loadLiveWallpaper lwpbboy						;;
			8)	loadLiveWallpaper lwpbiowater					;;
			9)	loadLiveWallpaper lwpbluedotgrid				;;
			10)	loadLiveWallpaper lwplwpbluedots				;;
			11)	loadLiveWallpaper lwplwpcmgirls					;;
			12)	loadLiveWallpaper lwpcolors						;;
			13)	loadLiveWallpaper lwpcyandroid					;;
			14)	loadLiveWallpaper lwpdroid1						;;
			15)	loadLiveWallpaper lwpdroid2						;;
			16)	loadLiveWallpaper lwpdroid3						;;
			17)	loadLiveWallpaper lwpdroid4						;;
			18)	loadLiveWallpaper lwpdroidblue					;;
			19)	loadLiveWallpaper lwpdroidgreen					;;
			20)	loadLiveWallpaper lwpdroidred					;;
			21)	loadLiveWallpaper lwpelectric					;;
			22)	loadLiveWallpaper lwplivestrong					;;
			23)	loadLiveWallpaper lwpmarley						;;
			24)	loadLiveWallpaper lwpnexus1						;;
			25)	loadLiveWallpaper lwpnexus2						;;
			26)	loadLiveWallpaper lwpnexus3						;;
			27)	loadLiveWallpaper lwpnexus4						;;
			28)	loadLiveWallpaper lwpnovablue					;;
			29)	loadLiveWallpaper lwpnovacyan					;;
			30)	loadLiveWallpaper lwpnovagreen					;;
			31)	loadLiveWallpaper lwpkangerade					;;
			32)	loadLiveWallpaper lwprainbokeh					;;
			33)	loadLiveWallpaper lwpsurfdroid					;;
			34)	loadLiveWallpaper lwptardis						;;
			35)	loadLiveWallpaper lwplwporiginal				;;
			36)													;;
			*)	$BB echo "Error: Invalid option in $lwpChoice"	;;
		esac
	}

	installFonts()
	{
		FONT_DIR=/sdcard/goodies/fonts
		FONT_URL="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/fonts"
		
		loadFonts()
		{
			$BB mkdir -p $FONT_DIR/$1
			if $BB [ `$BB find $FONT_DIR/$1 -iname *.ttf | $BB wc -l` -eq 0 ]; then
				$BB echo "Downloading fonts ... "
				$BB wget $FONT_URL/$1.zip -O $FONT_DIR/$1/$1.zip
				$BB unzip -o $FONT_DIR/$1/$1.zip -d $FONT_DIR/$1
				$BB rm -f $FONT_DIR/$1/$1.zip
			fi
			$BB find $FONT_DIR/$1 -iname *.ttf -print | while read ttf
			do
				$BB echo -n "Installing $ttf ... "
				$BB cp -f $ttf /system/fonts
				$BB echo "done."
			done
			promptToReboot changes
		}
		
		$BB echo "----------------------------------------------------------"
		$BB echo "1   Antipasto                15  Frontier"
		$BB echo "2   Applegaramound           16  Gangsta"
		$BB echo "3   Arial                    17  Haze"
		$BB echo "4   Bloody                   18  Infected"
		$BB echo "5   Bonzai                   19  Newspapaer"
		$BB echo "6   Broadway                 20  Purisa"
		$BB echo "7   Comic                    21  Sawasdee"
		$BB echo "8   Conforaa                 22  Stock font"
		$BB echo "9   Corsiva                  23  Times"
		$BB echo "10  Courier                  24  Trebuchet"
		$BB echo "11  Defused                  25  Zegoe"
		$BB echo "12  Dejavu                   26  Zegoelight"
		$BB echo "13  Dogtown                  27  Exit this menu."
		$BB echo "14  Droid"
		$BB echo "----------------------------------------------------------"
		$BB echo -n "Please choose a number: "
		read fontChoice
		case $fontChoice in
			1)	loadFonts antipasto								;;
			2)	loadFonts applegaramound						;;
			3)	loadFonts arial									;;
			4)	loadFonts bloody								;;
			5)	loadFonts bonzai								;;
			6)	loadFonts broadway								;;
			7)	loadFonts comic									;;
			8)	loadFonts conforaa								;;
			9)	loadFonts corsiva								;;
			10)	loadFonts courier								;;
			11)	loadFonts defused								;;
			12)	loadFonts dejavu								;;
			13)	loadFonts dogtown								;;
			14)	loadFonts droid									;;
			15)	loadFonts frontier								;;
			16)	loadFonts gangsta								;;
			17)	loadFonts haze									;;
			18)	loadFonts infected								;;
			19)	loadFonts newspaper								;;
			20)	loadFonts purisa								;;
			21)	loadFonts sawasdee								;;
			22)	loadFonts stock									;;
			23)	loadFonts times									;;
			24)	loadFonts trebuchet								;;
			25)	loadFonts zegoe									;;
			26)	loadFonts zegoelight							;;
			27)													;;
			*)	$BB echo "Error: Invalid option in $fontChoice"	;;
		esac
	}

	installExtraApps()
	{
		EXTRA_APPS_DIR=/sdcard/goodies/extraapps
		EXTRA_APPS_URL="http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/goodies/extraapps"
		
		loadExtraApps()
		{
			if $BB [ ! -e $EXTRA_APPS_DIR/$1 ]; then
				$BB echo "Downloading $1 ... "
				$BB mkdir -p $EXTRA_APPS_DIR
				$BB wget $EXTRA_APPS_URL/$1 -O $EXTRA_APPS_DIR/$1
			fi
			$BB echo -n "Installing $1 ... "	# Note: Apps must be signed with test keys.
			if $BB [ `pm install -r $EXTRA_APPS_DIR/$1 2>/dev/null` == "Success" ]; then
				$BB echo "done."
			else
				$BB echo "failed."
			fi
		}
		
		$BB echo "----------------------------------"
		$BB echo " 1   Amazon MP3"
		$BB echo " 2   IM"
		$BB echo " 3   Slide Show Widget"
		$BB echo " 4   Desire Mount USB"
		$BB echo " 5   Adobe Flash Player"
		$BB echo " 6   Road SMS"
		$BB echo " 7   Samsung S LWPs"
		$BB echo " 8   DroidX eye LWP"
		$BB echo " 9   Droid 2 Multi-Touch Keyboard"
		$BB echo " 10  Brut Google Maps by Brut.all"
		$BB echo " 11  Samsung Fascinate LWPs"
		$BB echo " 12  Droid2 R2D2 LWP's"
		$BB echo " 13  Exit this menu"
		$BB echo "----------------------------------"
		$BB echo -n "Please choose a number: "
		read appChoice
		case $appChoice in
			1)	loadExtraApps amazonmp3.apk								;;
			2)	loadExtraApps IM.apk									;;
			3)	loadExtraApps SlideShowWidget.apk						;;		
			4)	loadExtraApps mountusb.apk								;;
			5)	loadExtraApps com.adobe.flashplayer-1.apk				;;
			6)	loadExtraApps roadsms_1.01.apk							;;
			7)	if $BB [ ! -e /system/lib/libmnglw-0.8.2.so ]; then
					$BB wget $EXTRA_APPS_URL/libmnglw-0.8.2.so -O /system/lib/libmnglw-0.8.2.so
					$BB chmod 644 /system/lib/libmnglw-0.8.2.so
				fi
				loadExtraApps TATLiveWallpapersAurora.apk
				loadExtraApps TATLiveWallpapersBlueSea.apk
				loadExtraApps TATLiveWallpapersDandelion.apk
				loadExtraApps TATLiveWallpapersOceanWave.apk			;;
			8)	loadExtraApps LiveWallpapersDroidX-REDEYE-signed.apk	;;
			9)	if $BB [ -e /system/lib/libjni_latinime.so ]; then
					$BB mv -f /system/lib/libjni_latinime.so /system/lib/libjni_latinime.so.bak
				fi
				$BB wget $EXTRA_APPS_URL/libjni_latinime.so -O /system/lib/libjni_latinime.so
				$BB chmod 644 /system/lib/libjni_latinime.so
				loadExtraApps Droid2LatinIme.apk						;;
			10)	loadExtraApps maps4.4.0.4414-brut16.apk					;;
			11)	if $BB [ ! -e /system/lib/liblwfa-0.A.2-mng-p1.so ]; then
					$BB wget $EXTRA_APPS_URL/liblwfa-0.A.2-mng-p1.so -O /system/lib/liblwfa-0.A.2-mng-p1.so
					$BB chmod 644 /system/lib/liblwfa-0.A.2-mng-p1.so
				fi
				loadExtraApps TATLiveWallpapersConnection.apk
				loadExtraApps TATLiveWallpapersFlow.apk
				loadExtraApps TATLiveWallpapersForest.apk
				loadExtraApps TATLiveWallpapersLayersOfLight.apk
				loadExtraApps TATLiveWallpapersLuminescence.apk
				loadExtraApps TATLiveWallpapersSpark.apk				;;
			12)	loadExtraApps StarWarsESB_asteroids.apk
				loadExtraApps StarWarsESB_lightspeed.apk
				loadExtraApps StarWarsESB_R2D2.apk
				loadExtraApps StarWarsESB_spaceslug.apk					;;
			13)															;;
			*)	$BB echo "Error: Invalid option in $appChoice"			;;
		esac
	}
	
	case $1 in
		ba|--bootani)
			installBootAnimations
		;;
		exa|--extraapps)
			installExtraApps
		;;
		fs|--fonts)
			installFonts
		;;
		lwp|--livewalls)
			installLiveWallpapers
		;;
		*)
			_loadUsage
		;;
	esac
}

_rb()
{
  #############################################################
  # Description:
  #    Reboots, reboot recovery, and power downs device.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_rbUsage()
	{
		$BB echo "Usage: rb [-r] [-p]"
		$BB echo ""
		$BB echo "options:"
		$BB echo "        (default)   reboots device"
		$BB echo "        -r          reboot into recovery"
		$BB echo "        -p          powers down device"
	}
	
	prepareShutdown()
	{
		stop dhcpcd;
		
		$BB sleep 1;
		
		for i in `$BB cat /proc/mounts | $BB cut -f 2 -d " "`
		do
			$BB mount -o remount,ro $i > /dev/nul 2>&1
		done
		
		sync
	}
	
	case $1 in
		""|--reboot)
			$BB echo "See you soon ... "
			prepareShutdown
			$BB sleep 3
			toolbox reboot
		;;
		-r|--recovery)
			$BB echo "Booting into recovery ... "
			prepareShutdown
			$BB sleep 3
			toolbox reboot recovery
		;;
		-p|--power)
			$BB echo "Goodbye ... "
			prepareShutdown
			toolbox reboot -p
		;;
		*)
			_rbUsage
		;;
	esac
}

_rmapk()
{
  #############################################################
  # Description:
  #    Removes and pm uninstalls unwanted apps found in
  #    /system/app with any partial name match.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_rmapkUsage()
	{
		$BB echo "Usage:"
		$BB echo "    rmapk [-m|browser|calc|carhome|corpcal|clock|"
		$BB echo "          clock|email|facebook|gallery|genie|"
		$BB echo "          launcher|lwp|maps|mms|music|pandora|"
		$BB echo "          qoffice|spare|talk|twitter|youtube]"
		$BB echo ""
		$BB echo "Removes and uninstalls unwanted apps from /system"
		$BB echo ""
		$BB echo "--menu will print a user friendly menu with options."
		$BB echo "If you do rmapk [partial name of any apk] it will"
		$BB echo "search for any apk that matches and prompt you if"
		$BB echo "you would like to uninstall the app"
	}
	
	removeAnyApp()
	{
		if $BB test -z `$BB ls /system/app | $BB grep -i "$1"` > /dev/null 2>&1; then
			$BB echo "Error: $1 not found in /system/app!"
			$BB echo ""
			if $BB [ $ALLINONE -ne 1 ]; then
				_rmapkUsage
			fi
		else
			for apk in `$BB ls /system/app | $BB grep -i "$1"`	# Find the app with any partial name match.
			do
				packageName=$(pm list package -f | $BB grep $apk | $BB sed "s|package:/system/app/$apk=||g")	# get the apps package name for pm uninstall
				if $BB [ $PROMPTUNINSTALL -eq 1 ]; then
					$BB echo -n "Continue to remove and uninstall `$BB basename $apk`? (y/n): "
					read uninstallChoice
					case $uninstallChoice in
						y|Y)
							$BB echo -n "Removing and uninstalling `$BB basename $apk` ... "
							$BB rm -f /system/app/$apk
							if $BB [ `pm uninstall $packageName 2>/dev/null` == "Success" ]; then
								$BB echo "done."
							else
								$BB echo "Uninstall failed for `$BB basename $apk`!"
							fi
						;;
						n|N)
						
						;;
						*)
							$BB echo "Error: invalid choice in $uninstallChoice."
						;;
					esac
				else
					$BB echo -n "Removing and uninstalling `$BB basename $apk` ... "
					$BB rm -f /system/app/$apk
					if $BB [ `pm uninstall $packageName 2>/dev/null` == "Success" ]; then
						$BB echo "done."
					else
						$BB echo "Uninstall failed for `$BB basename $apk`!"
					fi
				fi
			done
		fi
	}
	
	while $BB test $# -ne 0; do
		case $1 in
			"")
				_rmapkUsage
			;;
			-m|--menu)
				PROMPTUNINSTALL=0
				$BB echo "----------------------------------------"
				$BB echo "1   Browser"
				$BB echo "2   Calculator"
				$BB echo "3   Calendar"
				$BB echo "4   Car Home"
				$BB echo "5   Desk Clock"
				$BB echo "6   Email"
				$BB echo "7   Facebook"
				$BB echo "8   LatinIME"
				$BB echo "9   Maps"
				$BB echo "10  Mms"
				$BB echo "11  Music"
				$BB echo "10  Pandora"
				$BB echo "13  Quick Office"
				$BB echo "14  Spare Parts"
				$BB echo "15  Talk"
				$BB echo "16  You Tube"
				$BB echo "17  Twitter"
				$BB echo "18. You choose which apps to delete."
				$BB echo "19. Exit this menu."
				$BB echo "----------------------------------------"
				$BB echo -n "Please choose a number: "
				read removeChoice
				case $removeChoice in
					1)	removeAnyApp Browser													;;
					2)	removeAnyApp Calculator													;;
					3)	removeAnyApp Calendar													;;
					4)	removeAnyApp CarHome													;;
					5)	removeAnyApp DeskClock													;;
					6)	removeAnyApp Email														;;
					7)	removeAnyApp Facebook													;;
					8)	removeAnyApp LatinIme													;;
					9)	removeAnyApp Maps														;;
					10)	removeAnyApp Mms														;;
					11)	removeAnyApp Music														;;
					12)	removeAnyApp Pandora													;;
					13)	removeAnyApp QuickOffice												;;
					14)	removeAnyApp SpareParts													;;
					15)	removeAnyApp Talk														;;
					16)	removeAnyApp YouTube													;;
					17)	removeAnyApp Twitter													;;
					18) PROMPTUNINSTALL=1
						$BB echo "-----------------------------------------"
						$BB ls /system/app
						$BB echo ""
						$BB echo -n "Please type the name of the app you wish to uninstall: "
						read removeUserChoice
						for userInput in $removeUserChoice 	# Allow for multiple entries.
						do
							for apk in `$BB ls /system/app | $BB grep -i $userInput`
							do
								removeAnyApp $apk
							done
						done																	;;
					19)																			;;
					*)	$BB echo "Error: Invalid option in $removeChoice"						;;
				esac
			;;
			browser)
				PROMPTUNINSTALL=0 ; removeAnyApp browser
			;;
			calc)
				PROMPTUNINSTALL=0 ; removeAnyApp calculator
			;;
			carhome)
				PROMPTUNINSTALL=0 ; removeAnyApp carhome
			;;
			corpcal)
				PROMPTUNINSTALL=0 ; removeAnyApp corpcal
			;;
			clock)
				PROMPTUNINSTALL=0 ; removeAnyApp deskclock
			;;
			email)
				PROMPTUNINSTALL=0 ; removeAnyApp email
			;;
			facebook)
				PROMPTUNINSTALL=0 ; removeAnyApp facebook
			;;
			gallery)
				PROMPTUNINSTALL=0 ; removeAnyApp gallery
			;;
			genie)
				PROMPTUNINSTALL=0 ; removeAnyApp geniewidget
			;;
			launcher)
				PROMPTUNINSTALL=0 ; removeAnyApp launcher2
			;;
			lwp)
				PROMPTUNINSTALL=0 ; removeAnyApp wallpapers
			;;
			maps)
				PROMPTUNINSTALL=0 ; removeAnyApp maps
			;;
			mms)
				PROMPTUNINSTALL=0 ; removeAnyApp mms
			;;
			music)
				PROMPTUNINSTALL=0 ; removeAnyApp music
			;;
			pandora)
				PROMPTUNINSTALL=0 ; removeAnyApp pandora
			;;
			qoffice)
				PROMPTUNINSTALL=0 ; removeAnyApp quickoffice
			;;
			spare)
				PROMPTUNINSTALL=0 ; removeAnyApp spareparts
			;;
			talk)
				PROMPTUNINSTALL=0 ; removeAnyApp talk
			;;
			twitter)
				PROMPTUNINSTALL=0 ; removeAnyApp twitter
			;;
			youtube)
				PROMPTUNINSTALL=0 ; removeAnyApp youtube
			;;
			*)
				for userInput in $1 	# Allow for multiple entries.
				do
					for apk in `$BB ls /system/app | $BB grep -i $userInput`
					do
						removeAnyApp $apk
					done
				done
			;;
		esac
		shift;
	done
}

_rstapps()
{
  #############################################################
  # Description:
  #    Restores backups of applications, data, accounts and other
  #    configurations.
  # Created by:
  #    Jared Rummler (JRummy16) ** modified from my original
  #    restore script. **
  # Last modified:
  #    9-13-2010
  #

	VERSION="1.1"
	REBOOT=0

	_rstappsUsage()
	{
		$BB echo " Usage: rstapps [2au|2in|2sd|-a|auto|-c|-nd|-l|loc|-m|-v]"
		$BB echo ""
		$BB echo " Options:"
		$BB echo "  2au | --a2auto     Sets install location to auto"
		$BB echo "  2in | --internal   Sets install location to internal storage"
		$BB echo "  2sd | --apps2sd    Sets install location to external storage"
		$BB echo "  -a  | --apps       Restore apps and data"
		$BB echo "  -c  | --complete   Performs a complete restore"
		$BB echo "  -nd | --no_data    Restore apps only (no data)"
		$BB echo "  -l  | --logging    Disables logging for this run"
		$BB echo "  loc | --location   Shows current install location"
		$BB echo "  -m  | --misc       Restore misc. data"
		$BB echo "  -h  | --help       This help"
		$BB echo ""
		$BB echo "   Always specify options as separate words" 
		$BB echo "   e.g. -r -c instead of -rc. Its required!"
		$BB echo "   To restore specific apps type the partial"
		$BB echo "   name of the app. Example: `$BB basename $0` pando"
		exit
	}

	restoreApps()
	{
		APP_SUM=`$BB find $BACKUP_DIR/apps -name *.apk | $BB wc -l`
		APP=1
		
		$BB mkdir -p $BACKUP_DIR/apps
		if $BB [ $APP_SUM -eq 0 ]; then
			printMsg "Error: No apps found to restore! Run a backup first."
			return
		fi
		
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Restoring apps ..."
		$BB echo "**********************************"
		$BB echo ""
		
		for apk in $BACKUP_DIR/apps/*.apk
		do
			printMsg -n "($APP of $APP_SUM) Installing `$BB basename $apk` .."
			APP=$( $BB expr $APP + 1 )
			if $BB [ `pm install -r $apk 2>/dev/null` == "Success" ]; then
				printMsg ". done."
			else
				printMsg ". failed!"
			fi
		done
	}
	
	restoreData()
	{
		# Get a list of installed packages that are currently backed up:
		$BB echo "" > $BACKUP_DIR/package.list
		$BB cat /data/system/packages.xml | $BB egrep "^<package.*serId" | while read appInfo
		do
			PACKAGE_NAME=$( $BB echo $appInfo | $BB sed 's%.* name="\(.*\)".*%\1%' | $BB cut -d '"' -f1 )
			if $BB [ -d $BACKUP_DIR/data/data/$PACKAGE_NAME ]; then
				$BB echo "$PACKAGE_NAME" >> $BACKUP_DIR/package.list
			fi
		done
		
		PACK_SUM=`$BB cat $BACKUP_DIR/package.list | $BB wc -l`
		PACK=1
		
		if $BB [ $PACK_SUM -eq 0 ]; then
			printMsg "Error: No data found to restore! Run a backup first."
			return
		fi
		
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Restoring data ..."
		$BB echo "**********************************"
		$BB echo ""
		
		for package in `$BB cat $BACKUP_DIR/package.list`
		do
			$BB echo -n "($PACK of $PACK_SUM) Restoring: $package .."
			PACK=$( $BB expr $PACK + 1 )
			$BB cp -R $BACKUP_DIR/data/data/$package /data/data
			printMsg ". done."
		done
	}
	
	restoreMisc()
	{
		$BB echo "**********************************"
		$BB echo "*** Restoring misc settings ..."
		$BB echo "**********************************"
		$BB echo ""
		
		$BB mkdir -p $BACKUP_DIR/misc
		
		if $BB [ -e $BACKUP_DIR/misc/wpa_supplicant.conf ]; then
			printMsg -n "Restoring wifi settings .."
			$BB cp -f $BACKUP_DIR/misc/wpa_supplicant.conf /data/misc/wifi
			$BB chown 1000:1010 /data/misc/wifi/wpa_supplicant.conf
			$BB chown system:wifi /data/misc/wifi/wpa_supplicant.conf
			$BB chmod 660 /data/misc/wifi/wpa_supplicant.conf
			printMsg ". done."
		fi
		
		if $BB [ -e $BACKUP_DIR/misc/accounts.db ]; then
			printMsg -n "Restoring accounts .."
			$BB cp -f $BACKUP_DIR/misc/accounts.db data/system	# Need to use sqlite3 :-/
			printMsg ". done."
		fi
		
		if $BB [ -e $BACKUP_DIR/misc/appwidgets.xml ]; then
			printMsg -n "Restoring home screen setup .."
			$BB cp -f $BACKUP_DIR/misc/appwidgets.xml /data/system
			printMsg ". done."
		fi
	}
	
	restoreAnyApp()
	{
		APP_SUM=`$BB ls $BACKUP_DIR/apps | $BB grep -i $1 | $BB wc -l`
		APP=1
		
		$BB mkdir -p $BACKUP_DIR/apps
		
		if $BB [ $APP_SUM -eq 0 ]; then
			printMsg "Error: $1 not found for restore."
			$BB echo ""
			printMsg "Error: `$BB basename $0` unknown option $1"
			_rstappsUsage
		else
			for apk in `$BB ls $BACKUP_DIR/apps | $BB grep -i $1`
			do
				printMsg -n "($APP of $APP_SUM) Installing $apk .."
				APP=$( $BB expr $APP + 1 )
				if $BB [ `pm install -r $BACKUP_DIR/apps/$apk 2>/dev/null` == "Success" ]; then
					printMsg ". done."
				else
					printMsg ". failed!"
				fi
			done
		fi
	}
	
	rebootDevice()
	{
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Rebooting device ..."
		$BB echo "**********************************"
		$BB echo ""
		
		$BB sleep 5
		_rb --reboot > /dev/null
	}
	
	acssiBanner()
	{
		# If you use this script in a rom please do not remove the banner.
		
		if $BB [ $BANNER -eq 1 ]; then
		
			$BB echo ""
			$BB echo "   _ \               |                     "
			$BB echo "  |   |   _ \   __|  __|   _ \    __|  _ \ "
			$BB echo "  __ <    __/ \__ \  |    (   |  |     __/ "
			$BB echo " _| \_\ \___| ____/ \__| \___/  _|   \___| "
			$BB echo " "
			$BB echo "    |_   .   ************************"
			$BB echo "    |_)\/.   |J||R||u||m||m||y||1||6|"
			$BB echo "       /     ************************"
			$BB echo ""
			$BB echo "    `$BB basename $0` runtime: `taskRuntime`"
		
		elif $BB [ $BANNER -eq 2 ]; then
			$BB echo ""
			$BB echo "    `$BB basename $0` runtime: `taskRuntime`"
		fi
	}
	
	restoreAllInOneMenu()
	{
		if $BB [ $ALLINONE -eq 1 ]; then
			$BB echo "-------------------------------------------------"
			$BB echo " 1  Restore all applications and their data"
			$BB echo " 2  Restore all applications (no data)"
			$BB echo " 3  Perform a complete restore"
			$BB echo " 4  restore wifi, home setup and accounts"
			$BB echo " 5  Exit this menu"
			$BB echo "-------------------------------------------------"
			$BB echo -n "Please choose a number: "
			read restoreChoice
			case $restoreChoice in
				1)	ALLINONE=0
					_rstapps -a											;;
				2)	ALLINONE=0
					_rstapps -nd										;;
				3)	ALLINONE=0
					_rstapps -c											;;
				4)	ALLINONE=0
					_rstapps -m											;;
				5)														;;
				*)	$BB echo "Error: Invalid option in $restoreChoice"	;;
			esac
			ALLINONE=1
			allInOneLoop 1
		fi
	}
	
	restoreAllInOneMenu
	
	if $BB [ -z "$1" ]; then
		restoreUsage
	fi
	
	START=$($BB date +%s)
	
	while $BB test $# -ne 0
	do
		case "$1" in
			2au|--a2auto)
				_apploc 2au
				BANNER=0
			;;
			2in|--internal)
				_apploc 2in
				BANNER=0
			;;
			2sd|--apps2sd)
				_apploc 2sd
				BANNER=0
			;;
			-a|--apps)
				checkSd
				restoreApps
				restoreData
				_zipalign_apks --all
				_fixperms
				BANNER=1
				acssiBanner
				$BB sleep 2
				rebootDevice
			;;
			-c|--complete)
				checkSd
				restoreApps
				restoreData
				restoreMisc
				_zipalign_apks --all
				_fixperms
				BANNER=1
				acssiBanner
				$BB sleep 2
				rebootDevice
			;;
			-nd|--no_data)
				checkSd
				restoreApps
				BANNER=1
			;;
			-h|-help|--help)
				restoreUsage
			;;
			-l|--logging)
				if $BB [ $LOGGING -eq 0 ]; then
					LOGGING=1
				else
					LOGGING=0
				fi
				BANNER=0
			;;
			loc|--location)
				$BB echo "Install Location is currently set to `pm getInstallLocation | $BB cut -c 2-`"
			;;
			-m|--misc)
				checkSd
				restoreMisc
				BANNER=1
			;;
			-v|--version)
				$BB echo "`$BB basename $0` $VERSION"
				exit
			;;
			*)
				restoreAnyApp
			;;
		esac
		shift
	done
	
	STOP=$($BB date +%s)
	acssiBanner
}

_setcpu()
{
  #############################################################
  # Description:
  #    Shows cpu info and sets cpu frequencies and scaling
  #    governors.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-20-2010
  #
	AVAILABLE_FREQ="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies"
	AVAILABLE_GOVERNORS="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
	
	# For init.rc:
	MIN_FREQ="write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
	MAX_FREQ="write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
	SCALING_GOV="write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
	SAMPLING_RATE="write /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate"
	UP_THRESHOLD="write /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold"
	
	_setcpuUsage()
	{
		$BB echo "Usage: setcpu"
		$BB echo ""
		$BB echo "Shows cpu info and sets cpu frequencies"
		$BB echo "and scaling governors"
	}
	
	setCpu()
	{
		$BB echo "$1" > /sys/devices/system/cpu/cpu0/cpufreq/$2
		$BB echo "Applied: "`cat /sys/devices/system/cpu/cpu0/cpufreq/$2`""	
	}
	
	listFreq()
	{
		LIST=1
		$BB echo "---------------------------------------"
		for freq in `$BB cat $AVAILABLE_FREQ`
		do
			$BB echo " $LIST  $freq MHz"
			LIST=$( $BB expr $LIST + 1 )
		done
		$BB echo " $LIST  Exit this menu"
		$BB echo "---------------------------------------"
	}
	
	listGovernors()
	{
		$BB echo "---------------------------------------"
		LIST=1
		for governor in `$BB cat $AVAILABLE_GOVERNORS`
		do
			$BB echo " $LIST  $governor"
			LIST=$( $BB expr $LIST + 1 )
		done
		$BB echo " $LIST  Exit this menu"
		$BB echo "---------------------------------------"
	}
	
	setFreq()
	{
		listFreq
		$BB echo "Your current $1 freq is: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_"$1"_freq`""
		$BB echo ""
		$BB echo -n "Please choose a number: "
		read freqChoice
		NEW_FREQ=`$BB cat $AVAILABLE_FREQ | $BB awk -v n="$freqChoice" '{print $n}'`
		if $BB [ $freqChoice == $LIST ]; then
			return
		elif $BB [ -z "$NEW_FREQ" ]; then
			$BB echo "Error: Invalid choice in $freqChoice"
			return
		else
			if $BB [ $1 == "min" ]; then
				if $BB [ $NEW_FREQ -gt `$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq` ]; then
					$BB echo "Error: Can't set minimum speed higher than maximum speed"
					return
				fi
			elif $BB [ $1 == "max" ]; then
				if $BB [ $NEW_FREQ -lt `$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq` ]; then
					$BB echo "Error: Can't set maximum speed lower than minimum speed"
					return
				fi
			fi
		fi
		setCpu $NEW_FREQ scaling_"$1"_freq
	}
	
	initFreq()
	{
		listFreq
		$BB echo "Current $2 cpu frequency set at boot is: "`$BB grep "$1" init.sholes.rc | $BB sed "s|$1||"`""
		$BB echo ""
		$BB echo -n "Please choose a number: "
		read bootFreq
		NEW_FREQ=`$BB cat $AVAILABLE_FREQ | $BB awk -v n="$bootFreq" '{print $n}'`
		if $BB [ $bootFreq == $LIST ]; then
			return
		elif $BB [ -z "$NEW_FREQ" ]; then
			$BB echo "Error: Invalid choice in $BootFreq"
			return
		fi
		if $BB [ $2 == "minimum" ]; then
			if $BB [ $NEW_FREQ -gt `$BB grep "$MAX_FREQ" init.sholes.rc | $BB sed "s|$MAX_FREQ||"` ]; then
				$BB echo "Error: Can't set minimum speed higher than maximum speed"
				return
			fi
		elif $BB [ $2 == "maximum" ]; then
			if $BB [ $NEW_FREQ -lt `$BB grep "$MIN_FREQ" init.sholes.rc | $BB sed "s|$MIN_FREQ||"` ]; then
				$BB echo "Error: Can't set maximum speed lower than minimum speed"
				return
			fi
		fi
		$BB sed -i -e "s|$1.*|$1 $NEW_FREQ|g" init.sholes.rc
		$BB echo "$2 frequency was changed to: "`$BB grep "$1" init.sholes.rc | $BB sed "s|$1||"`""
	}
	
	cpuInfo()
	{
		$BB echo "-----------------------------------------------------------"
		$BB echo " Maximum Frequency Applied: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq`""
		$BB echo " Maximum Frequency Available: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq`""
		$BB echo " Minimum Frequency Applied: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq`""
		$BB echo " Minimum Frequency Available: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq`""
		$BB echo " Current Frequency Speed: "`$BB cat /proc/cpuinfo | $BB grep BogoMIPS | $BB awk '{print $3}'`""
		$BB echo " Scaling Governor Applied: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`""
		$BB echo " Available Frequencies: "`$BB cat $AVAILABLE_FREQ`""
		$BB echo " Scaling Governors Available: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`""
		$BB echo " Up Threshold Applied: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold`""
		$BB echo " Sampling Rate Applied: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate`""
		$BB echo "-----------------------------------------------------------"
	}
	
	if $BB [ $# -gt 0 ] ; then
		_setcpuUsage
	fi
	
	$BB echo "---------------------------------------"
	$BB echo " 1  Set Maximum Frequency."
	$BB echo " 2  Set Minimum Frequency."
	$BB echo " 3  Set Scaling Governor."
	$BB echo " 4  Show CPU Info."
	$BB echo " 5  Advanced."
	$BB echo " 6  Install kernels"
	$BB echo " 7  Exit this menu"
	$BB echo "---------------------------------------"
	$BB echo -n "Please choose a number: "
	read cpuChoice
	case $cpuChoice in
		1)	
			setFreq max
		;;
		2)	
			setFreq min
		;;
		3)	
			listGovernors
			$BB echo "Your current governor is: "`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`""
			$BB echo ""
			$BB echo -n "Please choose a number: "
			read govChoice
			NEW_GOVERNOR=`$BB cat $AVAILABLE_GOVERNORS | $BB awk -v n="$govChoice" '{print $n}'`
			if $BB [ -z "$NEW_GOVERNOR" ]; then
				$BB echo "Error: Invalid choice in $govChoice"
				return
			fi
			setCpu $NEW_GOVERNOR scaling_governor
		;;
		4)
			cpuInfo
		;;
		5)
			checkDevice sholes return	# Currently only for sholes (init.sholes.rc).
			# Droid X & Droid2 use: init.mapphone_umts.rc. Need other device infon
			mount -o remount,rw -t yaffs2 `$BB grep " /system " "/proc/mounts" | $BB cut -d ' ' -f1` / > /dev/nul 2>&1
			$BB echo "-------------------------------------------"
			$BB echo " 1 Set minimum frequency at boot"
			$BB echo " 2 Set maximum frequency at boot"
			$BB echo " 3 Set scaling governer at boot"
			$BB echo " 4 Set sampling rate"
			$BB echo " 5 Set up threshold"
			$BB echo " 6 Exit this menu"
			$BB echo "-------------------------------------------"
			$BB echo -n "Please choose a number: "
			read advancedChoice
			case $advancedChoice in
				1)	
					initFreq "$MIN_FREQ" minimum
				;;
				2)
					initFreq "$MAX_FREQ" maximum
				;;
				3)
					listGovernors
					$BB echo "Current scaling governor set at boot is: "`$BB grep "$SCALING_GOV" init.sholes.rc | $BB sed "s|$SCALING_GOV||"`""
					$BB echo ""
					$BB echo -n "Please choose a number: "
					read initGovChoice
					NEW_GOVERNOR=`$BB cat $AVAILABLE_GOVERNORS | $BB awk -v n="$initGovChoice" '{print $n}'`
					if $BB [ $initGovChoice == $LIST ]; then
						return
					elif $BB [ -z "$NEW_GOVERNOR" ]; then
						$BB echo "Error: Invalid choice in $initGovChoice"
						return
					fi
					$BB sed -i -e "s|$SCALING_GOV.*|$SCALING_GOV $NEW_GOVERNOR|g" init.sholes.rc
					$BB echo "Scaling governor was changed to: "`$BB grep "$SCALING_GOV" init.sholes.rc | $BB sed "s|$SCALING_GOV||"`""
				;;
				4)
					$BB echo ""
					$BB echo "Current sampling rate is: "`$BB grep "$SAMPLING_RATE" init.sholes.rc | $BB sed "s|$SAMPLING_RATE||"`""
					$BB echo ""
					$BB echo -n "Enter your sampling rate: "
					read initSamplingRate
					$BB sed -i -e "s|$SAMPLING_RATE.*|$SAMPLING_RATE $initSamplingRate|g" init.sholes.rc
					$BB echo "Sampling rate was changed to: "`$BB grep "$SAMPLING_RATE" init.sholes.rc | $BB sed "s|$SAMPLING_RATE||"`""
				;;
				5)
					UP_THRESHOLD="write /sys/devices/system/cpu/cpu0/cpufreq/ondemand/up_threshold"
					$BB echo ""
					$BB echo "Current up threshold is: "`$BB grep "$UP_THRESHOLD" init.sholes.rc | $BB sed "s|$UP_THRESHOLD||"`""
					$BB echo ""
					$BB echo -n "Enter your up threshold: "
					read initUpThreshold
					$BB sed -i -e "s|$UP_THRESHOLD.*|$UP_THRESHOLD $initUpThreshold|g" init.sholes.rc
					$BB echo "Sampling rate was changed to: "`$BB grep "$UP_THRESHOLD" init.sholes.rc | $BB sed "s|$UP_THRESHOLD||"`""
				;;
				6)
				
				;;
				*)
					$BB echo "Error: Invalid option in $advancedChoice"
				;;
			esac
		;;
		6)
			_install_zip --kernels
		;;
		7)
		
		;;
		*)	
			$BB echo "Error: Invalid option in $cpuChoice"
			if $BB [ $ALLINONE -ne 1 ]; then
				_setcpuUsage
			fi
		;;
	esac
}

_setprops()
{
  #############################################################
  # Description:
  #    Sets various build properties.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_setpropsUsage()
	{
		$BB echo "Usage: setprops"
		$BB echo ""
		$BB echo "Prints a menu to set various build properties"
	}
	
	setPropHeapSize()
	{
		$BB mkdir -p /data/local/tmp
		$BB cp -f /system/build.prop /data/local/tmp/build.prop
		$BB sed -i -e "s/^dalvik\.vm.heapsize.*$/dalvik.vm.heapsize=$1/" /data/local/tmp/build.prop
		if $BB [ `$BB grep dalvik.vm.heapsize /data/local/tmp/build.prop` == "dalvik.vm.heapsize=$1" ]; then
			$BB cp -f /data/local/tmp/build.prop /system/build.prop
			$BB echo "Changed VM Heap Size to $1."
			$BB echo "Changing the VM heap size changes the performance of your system, potentially for the worse."
			$BB echo "If you notice a decrease in performance try another setting."
			promptToReboot changes
		else
			$BB echo "Error: Failed to set VM heap size to $1! No change was made."
		fi
		$BB rm -f /data/local/tmp/build.prop
	}
	
	setPropWifiScanInterval()	{
		$BB mkdir -p /data/local/tmp
		$BB cp -f /system/build.prop /data/local/tmp/build.prop
		$BB sed -i -e "s/^wifi\.supplicant_scan_interval.*$/wifi.supplicant_scan_interval = $1/" /data/local/tmp/build.prop
		if $BB [ "`$BB grep wifi.supplicant_scan_interval /data/local/tmp/build.prop`" == "wifi.supplicant_scan_interval = $1" ]; then
			$BB cp -f /data/local/tmp/build.prop /system/build.prop
			$BB echo "Changed wifi scan interval to "`if $BB [ $1 -gt 60 ]; then MIN=$( $BB expr $1 / 60 ) ; SEC=$( $BB expr $1 % 60 ) ; $BB echo $MIN minutes and $SEC seconds ; elif $BB [ $1 -le 60 ]; then $BB echo $1 seconds ; fi`"."
			promptToReboot changes
		else
			$BB echo "Error: failed to change wifi scan interval! No change was made."
		fi
		$BB rm -f /data/local/tmp/build.prop
	}
	
	setPropRingDelay()	{
		$BB mkdir -p /data/local/tmp
		$BB cp -f /system/build.prop /data/local/tmp/build.prop
		$BB echo -n "Changing Ring Delay... "
		$BB sed -i -e "s/^ro\.telephony\.call_ring\.delay=.*$/ro.telephony.call_ring.delay=$1/" /data/local/tmp/build.prop
		if $BB [ `$BB grep ro.telephony.call_ring.delay /data/local/tmp/build.prop` == "ro.telephony.call_ring.delay=$1" ]; then
			$BB cp -f /data/local/tmp/build.prop /system/build.prop
			$BB echo "done."
		else
			$BB echo "failed."
		fi
		$BB rm -f /data/local/tmp/build.prop
	}
	
	setPropStagefright()	{
		$BB mkdir -p /data/local/tmp
		$BB cp -f /system/build.prop /data/local/tmp/build.prop
		$BB echo -n ""`if $BB [ $1 == "true" ]; then $BB echo "Enabling" ; elif $BB [ $1 == "false" ]; then $BB echo "Disabling" ; fi`" stagefright... "
		$BB sed -i -e "s/^media\.stagefright.enable-player.*$/media.stagefright.enable-player=$1/" /data/local/tmp/build.prop
		if $BB [ `$BB grep media.stagefright.enable-player /data/local/tmp/build.prop` == "media.stagefright.enable-player=$1" ]; then
			$BB cp -f /data/local/tmp/build.prop /system/build.prop
			$BB echo "done."
		else
			$BB echo "failed."
		fi
		$BB rm -f /data/local/tmp/build.prop
	}
	
	if $BB [ $# -gt 0 ]; then
		_setpropsUsage
	fi
	
	$BB echo "----------------------------------"
	$BB echo " 1  Change Dalvik VM Heap Size"
	$BB echo " 2  Change Wifi Scan Interval"
	$BB echo " 3  Change Call Ring Delay"
	$BB echo " 4  Enable/Disable StageFright"
	$BB echo " 5  Exit this menu"
	$BB echo "----------------------------------"
	$BB echo -n "Please choose a number: "
	read setPropChoice
	case $setPropChoice in
		1)	
			$BB echo "----------------------------------"
			$BB echo " Your current VM Heap Size is: `getprop dalvik.vm.heapsize`"
			$BB echo " 1  Set VM Heap Size to 12m"
			$BB echo " 2  Set VM Heap Size to 16m"
			$BB echo " 3  Set VM Heap Size to 24m (defualt)"
			$BB echo " 4  Set VM Heap Size to 32m"
			$BB echo " 5  Exit this menu"
			$BB echo "----------------------------------"
			$BB echo -n "Please choose a number: "
			read heapSizeChoice
			case $heapSizeChoice in
				1)	setPropHeapSize 12m									;;
				2)	setPropHeapSize 16m									;;
				3)	setPropHeapSize 24m									;;
				4)	setPropHeapSize 32m									;;
				5)														;;
				*)	$BB echo "Error: Invalid option in $heapSizeChoice"	;;
			esac
		;;
		2)	
			$BB echo "---------------------------------------------"
			$BB echo " Your current wifi scan interval is: `getprop wifi.supplicant_scan_interval`"
			$BB echo " 1  Change wifi scan interval to 30 seconds"
			$BB echo " 2  Change wifi scan interval to 45 seconds"
			$BB echo " 3  Change wifi scan interval to 60 seconds"
			$BB echo " 4  Change wifi scan interval to 90 seconds"
			$BB echo " 5  Change wifi scan interval to 2 minutes"
			$BB echo " 6  Change wifi scan interval to 3 minutes"
			$BB echo " 7  Exit this menu"
			$BB echo "---------------------------------------------"
			$BB echo -n "Please choose a number: "
			read wifiScanChoice
			case $wifiScanChoice in
				1)	setPropWifiScanInterval 30							;;
				2)	setPropWifiScanInterval 45							;;
				3)	setPropWifiScanInterval 60							;;
				4)	setPropWifiScanInterval 90							;;
				5)	setPropWifiScanInterval 120							;;
				6)	setPropWifiScanInterval 180							;;
				7)														;;
				*)	$BB echo "Error: Invalid option in $wifiScanChoice"	;;
			esac
		;;
		3)	
			$BB echo "------------------------------"
			$BB echo " 1  Reduce ring delay by 1/4"
			$BB echo " 2  Reduce ring delay by 1/3"
			$BB echo " 3  Reduce ring delay in half"
			$BB echo " 4  Reduce ring delay by 2/3"
			$BB echo " 5  Reduce ring delay by 3/4"
			$BB echo " 6  Set to defualt delay time"
			$BB echo " 7  Exit this menu"
			$BB echo "------------------------------"
			$BB echo -n "Please choose a number: "
			read ringDelayChoice
			case $ringDelayChoice in
				1)	setPropRingDelay 2250									;;
				2)	setPropRingDelay 2000									;;
				3)	setPropRingDelay 1500									;;
				4)	setPropRingDelay 1000									;;
				5)	setPropRingDelay 750									;;
				6)	setPropRingDelay 3000									;;
				7)															;;
				*)	$BB echo "Error: Invalid option in $ringDelayChoice"	;;
			esac
		;;
		4)	
			$BB echo "Stagefright is currently "$(if $BB [ `getprop media.stagefright.enable-player` == "true" ]; then $BB echo "enabled" ; fi ; if $BB [ `getprop media.stagefright.enable-player` == "false" ]; then $BB echo "disabled" ; fi)"."
			$BB echo "------------------------------"
			$BB echo " 1  Disable Stagefright"
			$BB echo " 2  Enable Stagefright"
			$BB echo " 3  Exit this menu"
			$BB echo "------------------------------"
			$BB echo -n "Please choose a number: "
			read stagefrightChoice
			case $stagefrightChoice in
				1)	setPropStagefright false								;;
				2)	setPropStagefright true									;;
				3)															;;
				*)	$BB echo "Error: Invalid option in $stagefrightChoice"	;;
			esac
		;;
		5)
		
		;;
		*)
			$BB echo "Error: Invalid option in $setPropChoice"
		;;
	esac
}

_slim()
{
  #############################################################
  # Description:
  #    Creates a list of media and apps and then removes
  #    unwanted specified files.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	SLIM_DIR=/sdcard/slim
	
	_slimUsage()
	{
		$BB echo "Usage: slim [-l] [-s]"
		$BB echo ""
		$BB echo "Options:"
		$BB echo "    -l | --list    Creates a list of your apps and media"
		$BB echo "    -s | --slim    Removes unwanted specified files"
		$BB echo "    -h | --help    This help"
		$BB echo ""
		$BB echo "Instructions to remove files:"
		$BB echo "  Run `$BB basename $0` -l"
		$BB echo "  Open $DROIDBOX_DIR_EXTERNAL/apps.list and $DROIDBOX_DIR_EXTERNAL/media.list"
		$BB echo "  Remove the '#' sign infront of unwanted files"
		$BB echo "  Run `$BB basename $0` -s"
	}
	
	listFiles()
	{
		$BB mkdir -p $DROIDBOX_DIR_EXTERNAL
		$BB echo -n "Creating files... "
		$BB echo "" > $DROIDBOX_DIR_EXTERNAL/apps.list
		$BB find /system/app -iname *.apk -exec $BB echo "#{}" >> $DROIDBOX_DIR_EXTERNAL/apps.list ';'
		$BB echo "" > $DROIDBOX_DIR_EXTERNAL/media.list
		$BB find /system/media -iname *.ogg -exec $BB echo "#{}" >> $DROIDBOX_DIR_EXTERNAL/media.list ';'	
		$BB echo " done."
	}
	
	slimApps()
	{
		if $BB [ ! -e $DROIDBOX_DIR_EXTERNAL/apps.list ]; then
			$BB echo "Error: No list found to slim apps."
			return
		fi
		
		for apk in `$BB cat $DROIDBOX_DIR_EXTERNAL/apps.list | $BB sed 's|#.*||g'`
		do
			if $BB [ -e $apk ]; then
				PROMPTUNINSTALL=0
				_rmapk `$BB basename $apk`
			else
				$BB echo "Can\`t remove $apk (no such file found)."
			fi
		done
	}
	
	slimMedia()
	{
		if $BB [ ! -e $DROIDBOX_DIR_EXTERNAL/media.list ]; then
			$BB echo "Error: No list found to slim media."
			return
		fi
		
		for ogg in `$BB cat $DROIDBOX_DIR_EXTERNAL/media.list | $BB sed 's|#.*||g'`
		do
			if $BB [ -e $ogg ]; then
				$BB echo -n "Removing `$BB basename $ogg` ... "
				$BB rm -f $ogg
				$BB echo "done."
			else
				$BB echo "Can\`t remove $ogg (no such file found)."
			fi
		done
	}
	
	case $1 in
		-l|--list)
			listFiles
		;;
		-s|--slim)
			slimApps
			slimMedia
		;;
		*)
			_slimUsage
		;;
	esac
}

_sound()
{
  #############################################################
  # Description:
  #    Changes lock/unlock notification sounds
  # Created by:
  #    Jared Rummler (JRummy16) 
  # Last modified:
  #    9-18-2010
  #

	soundUsage()
	{
		$BB echo "Usage: sound [unlock|lock]"
		$BB echo ""
		$BB echo "Options:"
		$BB echo "    lock    Changes lock screen lock notification sound"
		$BB echo "    unlock  Changes unlock screen lock notification sound"
		$BB echo ""
		$BB echo "Both options will list available sounds that you can"
		$BB echo "choose for your lock screen (lock/unlock) notification"
		$BB echo "sound. Simply type the name of the sound and it will"
		$BB echo "change after you reboot your device."
	}

	lockScreenSound()
	{
		if $BB [ -z $2 ]; then
			SOUNDS_DIR=/system/media/audio
		elif $BB [ -d $2 ]; then
			SOUNDS_DIR="$2"	# User can enter the path to .ogg files as the 2nd argument.
		fi
		$BB find $SOUNDS_DIR -name *.ogg -type f -exec sh -c '$BB echo "`$BB basename {}`"' ';'
		$BB echo ""
		$BB echo -n "Type the file name for your $1 sound:"
		read soundChoice
		# Check if file exists:
		if $BB [ -z $($BB ls `$BB find $SOUNDS_DIR -name *.ogg -type f` | $BB grep -i $soundChoice) ]; then
			$BB echo "Error: $soundChoice not found."
			return
		fi
		$BB ls `$BB find $SOUNDS_DIR -name *.ogg -type f` | $BB grep -i $soundChoice | while read ogg	# Partial name match
		do
			$BB cp -f $ogg /system/media/audio/ui/$1.ogg
			$BB echo ""
			$BB echo "`$BB basename $ogg` is now used as your $1 sound."
			$BB echo ""
		done
		promptToReboot changes
	}

	case $1 in
		lock)
			lockScreenSound Lock $2
		;;
		unlock)
			lockScreenSound Unlock $2
		;;
		*)
			soundUsage
		;;
	esac
}

_switch()
{
  #############################################################
  # Description:
  #    Switches bootanimations and live wallpapers that are
  #    found on the root of the sdcard.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_switchUsage()
	{
		$BB echo "Usage: switch [lwp|ba]"
		$BB echo ""
		$BB echo "Switches commonly changed files."
		$BB echo "Files must be on the root of the sdcard."
	}		
	
	switchBootAnimation()
	{
		if $BB [ -e /sdcard/bootanimation.zip ]; then
			$BB echo -n "Removing old boot animation ... "
			$BB find /data/local /system/media -name bootanimation.zip -exec $BB rm -f {} ';'
			$BB echo "done."
			$BB echo -n "Installing bootanimation from /sdcard ... "
			$BB cp -f /sdcard/bootanimation.zip /data/local
			$BB chmod 0655 /data/local/bootanimation.zip
			$BB echo "done."
		else
			$BB echo "Error: bootanimation.zip not found on the root of your sdcard."
		fi
	}
	
	switchLiveWallpaper()
	{
		if $BB [ -e /sdcard/LiveWallpapers.apk ]; then
			$BB echo -n "Installing Live Wallpaper ... "
			$BB cp -f /sdcard/LiveWallpaper.apk /system/app
			$BB echo "done."
		else
			$BB echo "Error: LiveWallpapers.apk not found on the root of your sdcard."
		fi
	}
	
	case $1 in
		ba|--bootanimation)
			switchBootAnimation
		;;
		lwp|--LiveWallpaper)
			switchLiveWallpaper
		;;
		*)
			_switchUsage
		;;
	esac
}

_symlinkdb()
{
  #############################################################
  # Description:
  #    Symlinks droidbox functions
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-17-2010
  #
	_linkdroidboxUsage()
	{
		$BB echo "Usage: $SCRIPT_NAME symlinkdb"
		$BB echo ""
		$BB echo "Symlinks droidbox functions"
	}
	
	if $BB [ $# -gt 0 ] ; then
		_linkdroidboxUsage
	fi
	
	for script in ads allinone apploc bkapps camsounds compcache chglog exe fixperms flashrec freemem install_zip load rb rmapk rstapps setcpu setprops slim sound switch sysrw sysro usb zipalign_apks
	do
		if $BB [ -e /system/xbin/$script ]; then
			$BB rm -f /system/xbin/$script
		fi
		$BB echo -n "Symlinking: $script ... "
		$BB ln -s $0 /system/xbin/$script
		$BB echo "done."
	done
}

_sysro()
{
  #############################################################
  # Description:
  #    Remounts the /system partition read-only
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_sysroUsage()
	{
		$BB echo "Usage:"
		$BB echo "    sysro"
		$BB echo ""
		$BB echo "Mounts the /system partition read-only"
	}
	
	if $BB [ $# -gt 0 ]; then
		_sysroUsage
	fi
	
	mount -o remount,ro -t yaffs2 `$BB grep " /system " "/proc/mounts" | $BB cut -d ' ' -f1` /system > /dev/nul 2>&1
	$BB echo "System mounted read-only"
	sync
}

_sysrw()
{
  #############################################################
  # Description:
  #    remounts the /system partition read/write
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #
	_sysrwUsage()
	{
		$BB echo "Usage:"
		$BB echo "    `$BB basename $0`"
		$BB echo ""
		$BB echo "Mounts the /system partition read/write"
	}
	
	if $BB [ $# -gt 0 ]; then
		_sysrwUsage
	fi
	
	$BB mount -o remount,rw -t yaffs2 `$BB grep " /system " "/proc/mounts" | $BB cut -d ' ' -f1` /system > /dev/nul 2>&1
	$BB echo "System mounted read/write"
}

_usb()
{
  #############################################################
  # Description:
  #    Enables / Disables USB mass storage.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-12-2010
  #
	_usbUsage()
	{
		$BB echo "Usage: usb [-e|-d]"
		$BB echo ""
		$BB echo "options:"
		$BB echo "        -e   enables usb mass storage"
		$BB echo "        -d   disables usb mass storage"
	}
	
	case $1 in
		-e|--enable|on)
			$BB echo "/dev/block/vold/179:0" > /sys/devices/platform/usb_mass_storage/lun0/file
			$BB echo "USB Mass Storage Enabled"
		;;
		-d|--disable|off)
			$BB echo "" > /sys/devices/platform/usb_mass_storage/lun0/file
			$BB echo "USB Mass Storage Disabled"
		;;
		*)
			_usbUsage
		;;
	esac
}

_zipalign_apks()
{
  #############################################################
  # Description:
  #    Zipaligns apks. By default apps in /data and /system
  #    are zipaligned.
  # Created by:
  #    Jared Rummler (JRummy16)
  # Last modified:
  #    9-9-2010
  #	
	ZIPALIGN_BINARY=http://www.froyoroms.com/files/developers/jrummy/JRummy/Other/zipalign
	
	_zipalign_apksUsage()
	{
		$BB echo " Usage: zipalign_apks [-a|-sd|<destination>]"
		$BB echo ""
		$BB echo " options:"
		$BB echo ""
		$BB echo "    -a  | --all     Zipaligns all apks in /data and /system"
		$BB echo "                    ^ Runs as default with no options."
		$BB echo "    -sd | --sdcard  Zipaligns all apks in /sdcard"
		$BB echo "    <destination>   Zipaligns all apks in users choice"
		$BB echo "    -h  | --help    This help"
		$BB echo ""
		$BB echo "    Always specify options as separate words" 
		$BB echo "    e.g. -r -c instead of -rc. Its required!"
		$BB echo "    To zipalign apks in your own destination"
		$BB echo "    of choice just type the directory path after"
		$BB echo "    `$BB basename $0`."
		$BB echo "    Example: `$BB basename $0` /sdcard/apps"
	}
	
	zipalignApks()
	{
		$BB echo ""
		$BB echo "**********************************"
		$BB echo "*** Zipaligning apks ..."
		$BB echo "**********************************"
		$BB echo ""
		
		if $BB [ -z "$($BB mount | $BB grep /sdcard)" ]; then
			TMP_ZIPALIGN_DIR=/data/local/zipalign_apks/tmp
		else
			TMP_ZIPALIGN_DIR=/sdcard/zipalign_apks/tmp
		fi
		
		APK_SUM=`$BB find $1 -name *.apk | $BB wc -l`
		APK=1
		APKS_ZIPALIGNED=0
		
		$BB mkdir -p $TMP_ZIPALIGN_DIR
		
		for apk in `$BB find $1 -name *.apk`
		do
			zipalign -c 4 $apk
			ZIPCHECK=$?
			$BB echo -n "($APK of $APK_SUM) "
			APK=$( $BB expr $APK + 1 )
			case $ZIPCHECK in
				1)
					$BB echo -n "ZipAligning: `$BB basename $apk` .."
					zipalign -v -f 4 $apk $TMP_ZIPALIGN_DIR/`$BB basename $apk`
					if $BB [ -e $TMP_ZIPALIGN_DIR/`$BB basename $apk` ]; then
						$BB cp -f $TMP_ZIPALIGN_DIR/`$BB basename $apk` $apk
						$BB rm -f $TMP_ZIPALIGN_DIR/`$BB basename $apk`
						$BB echo ". done"
						APKS_ZIPALIGNED=$( $BB expr $APKS_ZIPALIGNED + 1 )
					else
						$BB echo ". failed!"
					fi
				;;
				*)
					$BB echo "ZipAlign already completed on "`$BB basename $apk`""
				;;
			esac
		done
		
		$BB echo ""
		$BB echo "Total apks zipaligned: $APKS_ZIPALIGNED"
		$BB rm -R $TMP_ZIPALIGN_DIR
		if $BB [ $APKS_ZIPALIGNED -gt 0 -a $REBOOT -eq 1 ]; then
			promptToReboot performance
		fi
	}
	
	case "$1" in
		""|-a|--all)
			zipalignApks "/data /system"
		;;
		-sd|--sdcard)
			checkSd
			zipalignApks /sdcard
		;;
		-h|-help|--help)
			_zipalign_apksUsage
		;;
		*)	# Zipalign apks in users choice:
			if $BB [ -d $1 ]; then
				zipalignStart
				zipalignApks "$1"
			else
				_zipalign_apksUsage
			fi
		;;
	esac
}

 ###--------------------------------
 #-                 __
 #--  |\/| _ . _   (_  _ _. _ |_ .
 #--  |  |(_||| )  __)(_| ||_)|_ .
 #-                        |
 ###--------------------------------

checkBusybox
checkRoot
_sysrw > /dev/null

if $BB [ ! -z "${ARG}"  -a "$($BB basename $0)" == "${SCRIPT_NAME}" ] ; then
	CMD=$1;	shift 1
	ARG=$@
fi

case ${CMD} in
	ads)
		_ads ${ARG}
	;;
	allinone)
		_allinone ${ARG}
	;;
	apploc)
		_apploc ${ARG}
	;;
	bkapps)
		_bkapps ${ARG}
	;;
	camsound)
		_camsound ${ARG}
	;;
	compcache)
		_compcache ${ARG}
	;;
	chglog)
		_chglog ${ARG}
	;;
	exe)
		_exe ${ARG}
	;;
	fixperms)
		_fixperms ${ARG}
	;;
	flashrec)
		_flashrec ${ARG}
	;;
	freemem)
		_freemem ${ARG}
	;;
	install_zip)
		_install_zip ${ARG}
	;;
	load)
		_load ${ARG}
	;;
	rb)
		_rb ${ARG}
	;;
	rmapk)
		_rmapk ${ARG}
	;;
	rstapps)
		_rstapps ${ARG}
	;;
	setcpu)
		_setcpu ${ARG}
	;;
	setprops)
		_setprops ${ARG}
	;;
	slim)
		_slim ${ARG}
	;;
	sound)
		_sound ${ARG}
	;;
	switch)
		_switch ${ARG}
	;;
	symlinkdb)
		_symlinkdb ${ARG}
	;;
	sysro)
		_sysro ${ARG}
		exit
	;;
	sysrw)
		_sysrw ${ARG}
		exit
	;;
	usb)
		_usb ${ARG}
	;;
	zipalign_apks)
		_zipalign_apks ${ARG}
	;;
	*)
		droidBoxUsage
	;;
esac
_sysro > /dev/null