insmod /mnt/flash/Server/resource/wifi/hi3881.ko g_fw_mode=1

MACINFO=$(ifconfig wlan0|grep HWaddr|awk '{print $5}')
echo "Got random macInfo: ${MACINFO}"

ifconfig wlan0 up
ifconfig wlan0 down
echo "wlan0 al_tx 1 0 20 1 7" > /sys/hisys/hipriv
ifconfig wlan0 up
echo "wlan0 set_cal_freq -15" > /sys/hisys/hipriv
echo "wlan0 set_cal_bpwr 0 20" > /sys/hisys/hipriv
echo "wlan0 al_tx 0" > /sys/hisys/hipriv
ifconfig wlan0 down
echo "wlan0 al_tx 1 0 20 7 7" > /sys/hisys/hipriv
ifconfig wlan0 up
echo "wlan0 set_cal_bpwr 1 15" > /sys/hisys/hipriv
echo "wlan0 al_tx 0" > /sys/hisys/hipriv
ifconfig wlan0 down
echo "wlan0 al_tx 1 0 20 13 7" > /sys/hisys/hipriv
ifconfig wlan0 up
echo "wlan0 set_cal_bpwr 0 15" > /sys/hisys/hipriv
echo "wlan0 set_cal_bpwr 1 15" > /sys/hisys/hipriv
echo "wlan0 set_cal_bpwr 2 15" > /sys/hisys/hipriv
echo "wlan0 al_tx 0" > /sys/hisys/hipriv
ifconfig wlan0 down

echo "wlan0 w_cal_data 0" > /sys/hisys/hipriv
sleep 3
echo "wlan0 set_efuse_mac ${MACINFO} 0" > /sys/hisys/hipriv

sleep 3
reboot
