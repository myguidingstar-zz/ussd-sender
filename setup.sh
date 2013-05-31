#!/bin/bash
BASEDIR=$(dirname $0)
read ussdsport ussdrport < ~/.ussd-conf

function welcome(){
	ACTION=`zenity --width=450 --height=200 --list --radiolist \
			--text="What do you want to do?" \
			--title="Balance checker" \
			--column "Choice" --column "Action" \
					 FALSE             "List modem devices" \
					 TRUE              "Set modem device"`

if [ -n "${ACTION}" ]; then
  case $ACTION in
  "List modem devices")
    listdevices
    ;;
   "Set modem device")
    setmodem
    ;;
    *)
    exit
    ;;
  esac
fi
}
function listdevices(){
	# --title="List devices"
	listofdevice=`dmesg -T |grep modem|grep -E 'ttyUSB[0-9]{1,2}'`
	listofdevice2=`nmcli dev|grep -E 'ttyUSB[0-9]{1,2}'`
	if [ -n "$listofdevice" ]
	then
	zenity --info --text="This is the list of your modem devices:\n\n$listofdevice\n\nAnd this is device found by network manager:\n$listofdevice2"
	else
	zenity --error --text="No device found"
	fi
	welcome
}
function setmodem(){
	read ussdsport ussdrport < ~/.ussd-conf
	ussdsport=`zenity --entry  --title="Set modem device" \
				--text="Enter device to send command to. Leave empty for default (/dev/ttyUSB2):" \
				--entry-text "$ussdsport"`
	if [ -z "$ussdsport" ]
		then
		ussdsport="/dev/ttyUSB2"
	fi
	ussdrport=`zenity --entry  --title="Set modem device" \
				--text="Enter device to read from. Leave empty for the same as device for sending command:" \
				--entry-text "$ussdrport"`
	if [ -z "$ussdrport" ]
		then
		ussdrport="$ussdsport"
	fi
	echo "$ussdsport $ussdrport" > ~/.ussd-conf
	welcome
}
welcome
