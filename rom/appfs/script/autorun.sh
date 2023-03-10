#! /bin/sh

ISVP_DRV_PATH=/mnt/flash/Server/driver
ISVP_DRV_ISP_PATH=${ISVP_DRV_PATH}/t31
ISVP_DRV_SENSOR_PATH=${ISVP_DRV_PATH}/extdrv
ISVP_DRV_TXX_PATH=${ISVP_DRV_SENSOR_PATH}

if [ ! -e /mnt/flash/productinfo/AlarmInOut.txt ];then
	echo 1 1 > /mnt/flash/productinfo/AlarmInOut.txt
fi

[ ! -f var/lock/fw_printenv.lock ] && mkdir -p /var/lock && touch /var/lock/fw_printenv.lock

export PATH=/mnt/flash/Server/tools:${PATH}

#echo isvpt20 > /var/hisi_type.cfg
echo isvpt31 > /var/hisi_type.cfg

CPU_TYPE=$(cat /proc/cpuinfo | awk 'NR==1 {print $4}')
DDR_SIZE=$(cat /proc/cmdline | awk '{print $2}' | sed 's/.*=//;s/M.*//')
if [ $DDR_SIZE -lt "64" ];then
	echo 16384  > /proc/sys/net/core/rmem_default
	echo 81920  > /proc/sys/net/core/rmem_max
	echo 16384 > /proc/sys/net/core/wmem_default
	echo 81920 > /proc/sys/net/core/wmem_max
	echo "4096 8192 81920" > /proc/sys/net/ipv4/tcp_rmem
	echo "4096 16384 81920" > /proc/sys/net/ipv4/tcp_wmem
	echo "200 300 400" > /proc/sys/net/ipv4/tcp_mem
	echo "200 300 400" > /proc/sys/net/ipv4/udp_mem
	echo 10 > /proc/sys/vm/dirty_ratio
	echo 5 > /proc/sys/vm/dirty_background_ratio
	echo 500 > /proc/sys/vm/dirty_expire_centisecs
	echo 500 > /proc/sys/vm/vfs_cache_pressure
	echo 800 > /proc/sys/vm/min_free_kbytes
fi

#if [ "$CPU_TYPE" = "bull" ];then
#	if [ $DDR_SIZE -lt "64" ];then
#		echo isvpt21 > /var/hisi_type.cfg
#	else
#		echo isvpt20 > /var/hisi_type.cfg
#	fi
#	ISVP_DRV_ISP_PATH=${ISVP_DRV_PATH}/t20
	#ISVP_DRV_TXX_PATH=${ISVP_DRV_ISP_PATH}

	# echo 100 > /proc/sys/vm/swappiness
	# echo 16777216 > /sys/block/zram0/disksize
	# mkswap /dev/zram0
	# swapon /dev/zram0
#	echo 4096  > /proc/sys/net/core/rmem_default
#	echo 65536  > /proc/sys/net/core/rmem_max
#	echo 256960 > /proc/sys/net/core/wmem_max
#	echo 16384 > /proc/sys/net/core/wmem_default

#	echo "4096 8192 65536" > /proc/sys/net/ipv4/tcp_rmem
#	echo "4096 16384 256960" > /proc/sys/net/ipv4/tcp_wmem
#	echo "400 600 800" > /proc/sys/net/ipv4/tcp_mem
#fi

[ -d /mnt/flash/Server/lib ] && mount --bind /mnt/flash/Server/lib /usr/lib
[ -d /mnt/flash/Server/etc ] && mount --bind /mnt/flash/Server/etc /etc
touch /tmp/resolv.conf
touch /tmp/TZ
[ -d /mnt/flash/Server/root ] && mount --bind /mnt/flash/Server/root /root
[ -d /mnt/flash/Server/usr/sbin ] && cp -rf /usr/sbin /mnt/flash/Server/usr/ && mount --bind /mnt/flash/Server/usr/sbin /usr/sbin
#[ -d /mnt/flash/Server/firmware ] && mount --bind /mnt/flash/Server/firmware /lib/firmware


for webDir in jpgimage jpgmulreq mjpg mjpgstreamreq
do
	mkdir -p /tmp/web/$webDir
	mount --bind /tmp/web/$webDir /mnt/flash/Server/web/$webDir 2>/dev/null
done

if [ -f /mnt/flash/logo.tgz ];then
	cp -rf /mnt/flash/Server/web/browse/images /tmp
	mount --bind /tmp/images /mnt/flash/Server/web/browse/images
	tar xzvf /mnt/flash/logo.tgz -C /mnt/flash/Server/web/browse/images/
fi

[ -f /mnt/flash/Server/LINUX/odm.cfg ] && cp /mnt/flash/Server/LINUX/odm.cfg /mnt/flash/databak/odm.cfg
if ! diff -q /mnt/flash/databak/odm.cfg /mnt/flash/databak/odm_bak.cfg 2>/dev/null ; then
	[ -f /mnt/flash/databak/odm.cfg ] && rm /mnt/flash/databak/Version.txt && cp /mnt/flash/databak/odm.cfg /mnt/flash/databak/odm_bak.cfg
fi

lsusb | awk '{print $6}' | grep -v "1d6b" || echo > /tmp/NoneUsbdevInserted

if [ -e /mnt/flash/Server/resource/wifi/hi3881.ko ]; then
	rm -rf /tmp/NoneUsbdevInserted
	cd /sys/class/gpio/
	echo 6 > export
	echo out > gpio6/direction
	echo 1 > gpio6/value
	sleep 1
	echo 0 > gpio6/value 
	sleep 1
	echo 1 > gpio6/value
	cd -
	
	mkdir -p /tmp/system/lib/firmware
	mkdir -p /tmp/system/lib/modules 
	mkdir -p /tmp/system/lib/modules/3.10.14__isvp_swan_1.0__ 
	
	mount --bind /tmp/system/ /system/
	
	#mount --bind /mnt/flash/Server/etc/firmware/ /lib/firmware
fi

check_return()
{
	if [ $? -ne 0 ] ;then
		echo err: $1
		/root/watchall &
		echo exit
		exit
	fi
}



lsmod | grep "sinfo" > /dev/null
if [ $? -ne 0 ] ;then
	insmod ${ISVP_DRV_ISP_PATH}/sinfo.ko
	check_return "insmod sinfo"
fi

echo 1 >/proc/jz/sinfo/info
check_return "start sinfo"

SENSOR_INFO=$(cat /proc/jz/sinfo/info)
check_return "get sensor type"
echo ${SENSOR_INFO}
#rmmod sinfo

SENSOR=${SENSOR_INFO#*:}
ISP_PARAM="isp_clk=125000000"
SENSOR_PARAM=
CARRIER_SERVER_PARAM="--nrvbs 2"

if [ "$SENSOR" = "sc3335" ]; then
	ISP_PARAM="isp_clk=200000000"
	MEM=$(fw_printenv -n bootargs|awk '{print $2}')
	echo "____${MEM}____"
	if [ "${MEM}" = "mem=40M@0x0" ];then
		fw_setenv bootargs 'console=ttyS1,115200n8 mem=39M@0x0 rmem=25M@0x2700000 init=/linuxrc rootfstype=squashfs root=/dev/mtdblock2 rw mtdparts=jz_sfc:256k(boot),1472k(kernel),1024k(root),384K(config),-(appfs)'
		reboot && sleep 3 && exit 0
	fi
elif [ "$SENSOR" = "sc2332" ]; then
	if [ -f /mnt/flash/productinfo/domeJson.cfg ]; then
		resolution=`sed 's/.*main\"[ ]*\://g' /mnt/flash/productinfo/domeJson.cfg  | sed 's/}.*//g'`
		if [ ${resolution} -eq 2 ]; then
			ISP_PARAM="isp_clk=125000000"
		elif [ ${resolution} -eq 3 ]; then
			ISP_PARAM="isp_clk=200000000"
		fi
	else
		ISP_PARAM="isp_clk=200000000"
	fi
elif [ "$SENSOR" = "sc500ai" -o "$SENSOR" = "sc401ai" ]; then
	ISP_PARAM="isp_clk=200000000"
fi

echo --------------------
echo ${ISP_PARAM}
echo ${SENSOR_PARAM}
echo ${CARRIER_SERVER_PARAM}

lsmod | grep "avpu" > /dev/null
if [ $? -ne 0 ]; then
	if [ "$SENSOR" = "sc3335" ]; then
		insmod ${ISVP_DRV_ISP_PATH}/avpu.ko clk_name=mpll avpu_clk=500000000
	else
		insmod ${ISVP_DRV_ISP_PATH}/avpu.ko
	fi
	check_return "insmod avpu"
fi

lsmod | grep "tx_isp" > /dev/null
if [ $? -ne 0 ] ;then
	insmod ${ISVP_DRV_ISP_PATH}/tx-isp-t31.ko ${ISP_PARAM} isp_ch0_pre_dequeue_time=14 isp_ch0_pre_dequeue_interrupt_process=0 isp_ch0_pre_dequeue_valid_lines=540 isp_memopt=1
	check_return "insmod isp drv"
fi

lsmod | grep "audio" > /dev/null
if [ $? -ne 0 ] ;then
	insmod ${ISVP_DRV_ISP_PATH}/audio.ko spk_gpio=-1
	check_return "insmod audio"
fi

lsmod | grep ${SENSOR} > /dev/null
if [ $? -ne 0 ] ;then
	insmod ${ISVP_DRV_SENSOR_PATH}/sensor_${SENSOR}_t31.ko ${SENSOR_PARAM}
	check_return "insmod sensor drv"
fi

DEVICEID=$(echo $SENSOR | tr '[a-z]' '[A-Z]')

if [ "$SENSOR" = "sc2135" -o "$SENSOR" = "imx291" ]; then
	ln -sf /mnt/flash/Server/default_cfg/CameraInfo /tmp/CameraInfo
elif [ "$SENSOR" = "bf3115" -o "$SENSOR" = "sc1135" -o "$SENSOR" = "jxh42" ]; then
	ln -sf /mnt/flash/Server/default_cfg/CameraInfo_normal /tmp/CameraInfo
else
	ln -sf /mnt/flash/Server/default_cfg/CameraInfo_normal /tmp/CameraInfo
	cp /mnt/flash/Server/default_cfg/CameraInfo_normal /mnt/flash/databak/CameraInfo
fi

if [ "$SENSOR" = "sc3335" ]; then
	cp /mnt/flash/Server/default_cfg/VideoInfo_3M /mnt/flash/databak/VideoInfo
elif [ "$SENSOR" = "sc401ai" -o "$SENSOR" = "sc500ai" ]; then
	cp /mnt/flash/Server/default_cfg/VideoInfo_5M /mnt/flash/databak/VideoInfo
elif [ "$SENSOR" = "sc2332" ]; then
	if [ -f /mnt/flash/productinfo/domeJson.cfg ]; then
		resolution=`sed 's/.*main\"[ ]*\://g' /mnt/flash/productinfo/domeJson.cfg  | sed 's/}.*//g'`
		if [ ${resolution} -eq 2 ]; then
			cp /mnt/flash/Server/default_cfg/VideoInfo_2M /mnt/flash/databak/VideoInfo
			echo "SetResolution=2M"
		elif [ ${resolution} -eq 3 ]; then
			cp /mnt/flash/Server/default_cfg/VideoInfo_3M /mnt/flash/databak/VideoInfo
			echo "SetResolution=3M"
		fi
	else
		cp /mnt/flash/Server/default_cfg/VideoInfo_3M /mnt/flash/databak/VideoInfo
		echo "SetResolution=3M"
	fi
fi

#[ -f /mnt/flash/${SENSOR}.bin ] && mount --bind /mnt/flash/${SENSOR}.bin /etc/sensor/${SENSOR}.bin

echo SENSOR $SENSOR
echo DEVICEID $DEVICEID

echo -n "DEVICEID V6202IR-$DEVICEID" > /mnt/flash/productinfo/deviceid.txt

SENSOR_DRV=$SENSOR

#insmod ${ISVP_DRV_TXX_PATH}/audio.ko
#insmod ${ISVP_DRV_TXX_PATH}/exfat.ko
#insmod ${ISVP_DRV_TXX_PATH}/isvp_i2c.ko
#insmod ${ISVP_DRV_TXX_PATH}/sensor_i2c.ko
#lsmod | grep ${SENSOR} > /dev/null
#if [ $? -ne 0 ] ;then
#	insmod ${ISVP_DRV_SENSOR_PATH}/sensor_${SENSOR_DRV}.ko
#	check_return "insmod sensor drv"
#fi

insmod ${ISVP_DRV_SENSOR_PATH}/sample_pwm_core.ko
insmod ${ISVP_DRV_SENSOR_PATH}/sample_pwm_hal.ko
insmod ${ISVP_DRV_SENSOR_PATH}/sample_motor.ko vmaxstep=2000

free
echo 3 > /proc/sys/vm/drop_caches
free
#echo 512 > /proc/sys/vm/min_free_kbytes
#chmod -R 777 /mnt/flash/Server/mediaserver/*
cd /mnt/flash/Server/LINUX
#/mnt/flash/Server/mediaserver/sdk_app &
#sleep 2
mkdir -p /mnt/flash/log
/mnt/flash/Server/script/update_isvp.sh
/root/watchall &
