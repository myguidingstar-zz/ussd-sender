#!/bin/bash
BASEDIR=$(dirname $0)

read ussdsport ussdrport < ~/.ussd-conf

function welcome() {
ACTION=`zenity --width=450 --height=200 --list --radiolist \
	--title="Kiểm tra tài khoản" \
	--text="Bạn muốn làm gì?" \
	--column "Chọn" --column  "Hành động" \
				TRUE 			"Kiểm tra tài khoản" \
				FALSE 			"Nạp tiền" \
				FALSE 			"Nhập lệnh khác"`

if [ -n "${ACTION}" ];then
  case $ACTION in
      "Kiểm tra tài khoản")
          checkbalance
          ;;
      "Nạp tiền")
          recharge
          ;;
      "Nhập lệnh khác")
          sendussd
          ;;
      *)
          exit
          ;;
  esac
fi
}

function disconnect () {
	#~turn of broadband network for Ubuntu.
	# This is unneccesary on Gentoo.
	nmcli nm wwan off
	nmcli dev | grep tty | grep -v disconnected | grep -v unavailable | read interface y
	if [ -n "$interface" ]
	then
		nmcli dev disconnect iface $interface
	fi
}

function checkbalance () {
	
	disconnect
	distscript='/ussd/huawei-ussd.pl'
	sleep 2
	ussdcode='*101#'
	mainbalance=`perl "$BASEDIR$distscript" -s $ussdsport -r $ussdrport "$ussdcode"`
	ussdcode='*102#'
	subbalance=`perl "$BASEDIR$distscript" -s $ussdsport -r $ussdrport "$ussdcode"`
	zenity --info --text="$mainbalance\n$subbalance"
	nmcli nm wwan on
	welcome
}

function recharge(){

	disconnect
	ussdcode=`zenity --entry  --title="Nạp tiền" --text="Nhập mã số thẻ cào:"`
	if [ -n "$ussdcode" ]
	then
		ussdcode="*100*${ussdcode}#"
		distscript='/ussd/huawei-ussd.pl'
		sleep 1
		output=`perl "$BASEDIR$distscript" -s $ussdsport -r $ussdrport "$ussdcode"`
		zenity --info --text="$output"
	fi
	nmcli nm wwan on
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
		(zenity --question --text="$rport có vẻ không phải thiết bị modem. Tiếp tục?") || welcome
	fi
	checks=`dmesg |grep modem|grep "$sport"`
	if [ -z "$checks" ]
		then
		(zenity --question --text="$rport có vẻ không phải thiết bị modem. Tiếp tục?") || welcome
	fi
	disconnect
	ussdcode=`zenity --entry  --title="Nhập lệnh USSD" \
		--text="Nhập lệnh USSD. Để nguyên (*101#) để kiểm tra tài khoản:" \
		--entry-text "*101#"`
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
