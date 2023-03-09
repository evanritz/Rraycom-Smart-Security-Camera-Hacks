# Rraycom-Smart-Secuirty-Camera

Model: C-S-ACS229-US

- 3/7/23: ROM dumped with ardunio setup
    - ROM File hashes are all different (maybe due to enivromental noise during read)
    - Only <=20 byte difference between ROM files
    - Will attempt ROM dump with CH341A Programmer for better results
    - For now, its good enough as binwalk was able to extract the rootfs
    - root user MD5 password hash found!
        - **$1$EnVGPLqH$Jwh/FgaqrrHwHsmzHibnc1**
    - [googlefu](https://gist.github.com/gabonator/74cdd6ab4f733ff047356198c781f27d?permalink_comment_id=3452955#gistcomment-3452955) has found the password, No cracking required!
        - Username: **root**
        - Password: **hkipc2016**
    - Some symlinks are missing in ROM dump
