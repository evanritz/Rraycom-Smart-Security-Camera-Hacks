#!/bin/sh

killall softwdg watchall

while [ true ]
do
	echo 1 > /dev/watchdog
	sleep 1
done
