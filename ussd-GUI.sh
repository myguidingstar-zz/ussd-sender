#!/bin/bash
BASEDIR=$(dirname $0)

read ussdsport ussdrport < ~/.ussd-conf

if [ -f ~/.ussd-conf ]
then
{
	setradio=FALSE
	checkradio=TRUE
}
else
{
	setradio=TRUE
	checkradio=FALSE
}
fi
function welcome(){
ACTION=`zenity --width=450 --height=200 --list --radiolist --text="What do you want to do?" --title="Balance checker" --column "Choice" --column "Action" FALSE "List modem devices" $setradio "Set modem device" $checkradio "Check balance/Prepaid recharge/Send USSD command"`

if [ -n "${ACTION}" ];then
  case $ACTION in
  "List modem devices")
    listdevices
    ;;
   "Set modem device")
    setmodem
    ;;
   "Check balance/Prepaid recharge/Send USSD command")
    sendussd
    ;;
    *)
    exit
    ;;
  esac
fi
}
function listdevices(){
	# --title="List devices"
	listofdevice=`dmesg |grep modem|grep -E 'ttyUSB[0-9]{1,2}'`
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
	ussdsport=`zenity --entry  --title="Set modem device" --text="Enter device to send command to. Leave empty for default (/dev/ttyUSB2):" --entry-text "$ussdsport"`
	if [ -z "$ussdsport" ]
	then
	ussdsport="/dev/ttyUSB2"
	fi
	ussdrport=`zenity --entry  --title="Set modem device" --text="Enter device to read from. Leave empty for the same as device for sending command:" --entry-text "$ussdrport"`
	if [ -z "$ussdrport" ]
	then
	ussdrport="$ussdsport"
	fi
	echo "$ussdsport $ussdrport" > ~/.ussd-conf
	welcome
}
function sendussd(){
	read ussdsport ussdrport < ~/.ussd-conf
	#get information about device
	if [ -z "$ussdsport" ]
	then
	ussdsport="/dev/ttyUSB2"
	fi
	if [ -z "$ussdrport" ]
	then
	ussdrport="$ussdsport"
	fi
	rport=${ussdrport:5}
	sport=${ussdsport:5}
	checkr=`dmesg |grep modem|grep "$rport"`
	if [ -z "$checkr" ]
	then
		(zenity --question --text="$rport seems to be not a modem. Are you sure to continue?") || welcome
	fi
	checks=`dmesg |grep modem|grep "$sport"`
	if [ -z "$checks" ]
	then
		(zenity --question --text="$rport seems to be not a modem. Are you sure to continue?") || welcome
	fi
	#~turn of broadband network for Ubuntu. This is unneccesary on Gentoo -- BEGIN
	nmcli nm wwan off
	nmcli dev | grep tty | grep -v disconnected | grep -v unavailable | read interface y
	if [ -n "$interface" ]
	then
		nmcli dev disconnect iface $interface
	fi
	#~turn of broadband network for Ubuntu. This is unneccesary on Gentoo -- END
	#remove the above code if you use Gentoo.
	ussdcode=`zenity --entry  --title="USSD command" --text="Enter USSD command. Leave empty for default (*101#) to check balance:" --entry-text "*101#"`
	if [ -z "$ussdcode" ]
	then
	ussdcode='*101#'
	fi
	distscript='/ussd/huawei-ussd.pl'
	sleep 1
	output=`perl "$BASEDIR$distscript" -s $ussdsport -r $ussdrport "$ussdcode"`
	zenity --info --text="$output"
	nmcli nm wwan on
	welcome
}
welcome
