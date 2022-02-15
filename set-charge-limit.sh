#!/bin/bash
# Battery charge limiter for Asus laptops
# By Rudra Pratap Singh
# License: GNU GPLv3

### FUNCTIONS ###

welcomemsg()

{
	kdialog --title "Welcome!" --msgbox "Welcome. This will setup the Asus Battery charge limit on the system." &>/dev/null

	kdialog --title "Important Note!" --yes-label "ready" --no-label "exit" --yesno "Before proceeding further, please make sure that the system is up to date." &>/dev/null
}

#error() { printf "%s\n" "$1" >&2; exit 1; }
error() { printf "%s\n" "$1"; exit ; }

# CHECK WEATHER THE BATTERY IS SUPPORTED OR NOT
systemcheck()
{
	battery=$(if [ -d /sys/class/power_supply/BATT ] ; then
			echo BATT
			elif [ -d /sys/class/power_supply/BAT1 ] ; then
			echo BAT1
			elif [ -d /sys/class/power_supply/BAT0 ] ; then
			echo BAT0
			else
			echo NOPE
			fi)

	if [[	"$battery" = "NOPE"	]] ; then 
		kdialog --msgbox "Battery is not supported" &>/dev/null
		exit 1
	fi
}

# CHECK WEATHER THE SUPPORTED BATTERY HAS THE THRESHOLD LIMIT OR NOT
batterycheck()
{
	if [ -f /sys/class/power_supply/$battery/charge_control_end_threshold ] ; then
		kdialog --msgbox "Charge threshold is Supported. " &>/dev/null
	else
		kdialog --msgbox "Charge threshold is NOT Supported" &>/dev/mull
		exit 1
	fi
}

# ASK THE USER FOR THE CHARGE LIMIT
getchargelimit()
{
	value=$(kdialog --inputbox "Enter a charge limit (20-100): " 2>/dev/null)
	if [ $value -gt 19 ] && [ $value -lt 100 ] ; then
	:
	else
	kdialog --msgbox "Enter an integer value between 20-100" 2>/dev/null
	exit 1
	fi
}

getpassword()
{
	pass1=1
	pass2=2
	while ! [ "$pass1" = "$pass2" ]; do
		pass1=$(kdialog  --password "Enter Sudoer's Password." 2>/dev/null)
		pass2=$(kdialog  --password "Retype Password Password." 2>/dev/null)
	done ;
}

# SETS THE CHARGE LIMIT
setchargelimit()
{
	touch file_1
	cat > file_1 <<EOF
[Unit]
Description=Set the battery charge threshold
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/bash -c 'echo $value > /sys/class/power_supply/$battery/charge_control_end_threshold'

[Install]
WantedBy=multi-user.target
EOF

echo $pass1 | sudo -S cp file_1 /etc/systemd/system/battery-charge-threshold.service
echo $pass1 | sudo -S systemctl enable battery-charge-threshold.service
echo $pass1 | sudo -S systemctl start battery-charge-threshold.service

rm file_1
unset pass1
unset pass2
}

completed()
{
	kdialog --msgbox "Charge limit has been set" 2>/dev/null
}

### ACTUAL SCRIPT ###

welcomemsg || error "User exited at welcomemsg"
systemcheck || error "User exited at systemcheck"
batterycheck || error "User exited at batterycheck"
getchargelimit || error "User exited at getchargelimit"
getpassword || error "User exited at getpassword"
setchargelimit || error "User exited at setchargelimit"
completed || error "User exited at function \"completed\""
