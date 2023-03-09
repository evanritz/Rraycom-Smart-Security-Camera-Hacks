#!/bin/sh
mmc_mount()
{
#build-in kernel
#	insmod /usr/share/exfat.ko
	mkdir /tmp/mmc
	cd /dev/
	for mmc in `ls -r mmcblk*`
	do
		mount -t vfat -o utf8 $mmc /tmp/mmc
		[ $? = 0 ] && return 0
	done
	for mmc in `ls -r mmcblk*`
	do
		mount -t exfat -o utf8 $mmc /tmp/mmc
		[ $? = 0 ] && return 0
	done
	cd -
	return 1
}

firmware_update()
{
	ls /dev/mmcblk* | grep mmcblk || return 1
	mmc_mount
	[ $? != 0 ] && return 1
	UPDATE_BIN_NAMES=`ls /tmp/mmc/T31*.bin`
	[ $? != 0 ] && return 1
	echo $UPDATE_BIN_NAME
	for UPDATE_BIN_NAME in $UPDATE_BIN_NAMES
	do
		echo UPDATE_BIN_NAME=$UPDATE_BIN_NAME
		if [ -n $UPDATE_BIN_NAME ]; then
			APP_NAME=`echo $UPDATE_BIN_NAME | sed -e 's/.*_[0-9]\{8\}_//g'| awk -F'_' '{print $1}'`
			APP_NAME_NOW=`awk -F'_|-' '{print $2}' /mnt/flash/databak/Version.txt`
			echo app are $APP_NAME and $APP_NAME_NOW
			if [ $APP_NAME = $APP_NAME_NOW ]; then
				DATE_UPDATE=`echo $UPDATE_BIN_NAME | sed  -e 's/.*v[0-9]\{1,3\}_[0-9]\{1,3\}_[0-9]\{1,3\}_//g'  | awk -F'_' '{print $1}'`
				DATE_UPDATE=${DATE_UPDATE#*[0-9][0-9]}
				echo updatadate=$DATE_UPDATE
				DATE_NOW=`awk -F'-' '{print $2}' /mnt/flash/databak/Version.txt `
				echo nowdate=$DATE_NOW
				if [ -e /dev/mtdblock4 ]; then
					update_target=/dev/mtd4
				else
					update_target=/mnt/flash/Server.tar.xz
				fi
		#rm -f /tmp/mmc/update_success.bin /tmp/mmc/update_fail.bin
				if [ $DATE_UPDATE != $DATE_NOW ]; then
					if [ -f /mnt/flash/update.md5 ];then
						md5number=`md5sum $UPDATE_BIN_NAME | awk '{print $1}'`
						md5number_old=`cat /mnt/flash/update.md5`
						if [ $md5number = $md5number_old ];then
							echo "no update!"
							return 1
						fi
					fi
					echo "update now!"
					/mnt/flash/Server/LINUX/update $UPDATE_BIN_NAME $update_target
				else
					echo "no update!"
					return 1
				fi
				if [ $? = 0 ]; then
					md5sum $UPDATE_BIN_NAME | awk '{print $1}' > /mnt/flash/update.md5
		#mv /tmp/mmc/update.bin /tmp/mmc/update_success.bin
					echo update success
					return 0
				else
		#mv $UPDATE_BIN_NAME /tmp/mmc/update_fail.bin
					echo update fail
		#return 1
				fi
			fi
		fi
	done
	if [ -e /tmp/mmc/update_fac.bin ]; then
		md5sum /tmp/mmc/update_fac.bin | awk '{print $1}' | tr [a-z] [A-Z] > /tmp/update_fac.md5
		diff -i /tmp/update_fac.md5 /mnt/flash/update.md5 && return 1
		if [ -e /dev/mtdblock4 ]; then
			update_target=/dev/mtd4
		else
			update_target=/mnt/flash/Server.tar.xz
		fi
		rm -f /tmp/mmc/update_success.bin /tmp/mmc/update_fail.bin
		/mnt/flash/Server/LINUX/update /tmp/mmc/update_fac.bin $update_target
		if [ $? = 0 ]; then
			md5sum /tmp/mmc/update_fac.bin | awk '{print $1}' > /mnt/flash/update.md5
			touch /tmp/mmc/update_success.bin
			echo update success
			return 0
		else
			touch /tmp/mmc/update_fail.bin
			echo update fail
		fi
	fi
	
	return 1
}

firmware_update
[ $? = 0 ] && reboot
#lsmod | grep exfat && rmmod exfat
[ -d /tmp/mmc ] && umount /tmp/mmc
rmdir /tmp/mmc
