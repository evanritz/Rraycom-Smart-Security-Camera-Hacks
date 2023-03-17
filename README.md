# Rraycom-Smart-Secuirty-Camera

Model: C-S-ACS229-US

- 3/7/23: ROM dumped with ardunio setup
    - ROM File hashes are all different (maybe due to enivromental noise during read)
    - Only <=20 byte difference between ROM files
    - Will attempt ROM dump with CH341A Programmer for better results
    - For now, its good enough as binwalk was able to extract the rootfs
    - ROM dump added
    - root user MD5 password hash found!
        - **$1$EnVGPLqH$Jwh/FgaqrrHwHsmzHibnc1**
    - googlefu has found the password, No cracking required!
        - Username: **root**
        - Password: **hkipc2016**
    - ROM dump is missing some symlinks

- 3/9/23: True ROM dumped with SD card
    - Over telnet, dumped each partion to SD card
    - True ROM dump MD5 hash
        - cam.rom **0d37c47e0c0b43f9e35054a3b25f00f5**
    - Sections cut from ROM.
        - Bootloader
        - Kernel
        - Root and App filesystems
    - 2 binaries control the Camera
        - **sdk_app** - /mnt/flash/Server/mediaserver/
        - **hiapp**   - /mnt/flash/Server/LINUX/
    - Both have watchdogs placed on them
    - Both watchdogs restart the process, but dont cause the camera to reboot
        - Could attempt to fakeout the watchdogs