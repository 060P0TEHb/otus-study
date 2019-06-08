# Подключаем второй диск в компьютер. Объявляем его массивом, копируем туда данные. Перезагружаемся, включаем первый диск в массив - данные синхронизируются.
```
[vagrant@lesson-2 ~]$ lsblk 
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk 
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0  40G  0 disk
```

# Объявляем новый диск как диск для массива

```
[vagrant@lesson-2 ~]$ sudo su
[root@lesson-2 vagrant]# fdisk /dev/sdb
Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table
Building a new DOS disklabel with disk identifier 0x1cf544c1.

Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): 
Using default response p
Partition number (1-4, default 1): 
First sector (2048-83886079, default 2048): 
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-83886079, default 83886079):  
Using default value 83886079
Partition 1 of type Linux and of size 40 GiB is set

Command (m for help): t
Selected partition 1
Hex code (type L to list all codes): fd
Changed type of partition 'Linux' to 'Linux raid autodetect'

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

# Создаем массив из 1 диска

```
[root@lesson-2 vagrant]# mdadm -C /dev/md1 -l 1 -n 2 missing /dev/sdb1
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
Continue creating array? y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md1 started.

# Создаем файловую систему

[root@lesson-2 vagrant]# mkfs.xfs /dev/md1
meta-data=/dev/md1               isize=512    agcount=4, agsize=2619264 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=10477056, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=5115, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

# Монтируем рейд, копируем туда данные

```
[root@lesson-2 vagrant]# mount /dev/md1 /mnt
[root@lesson-2 vagrant]# xfsdump -J - / | xfsrestore -J - /mnt/
xfsrestore: using file dump (drive_simple) strategy
xfsdump: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of lesson-2:/
xfsdump: dump date: Thu Jun  6 18:28:36 2019
xfsdump: session id: 3c98126c-ee89-4689-8e8d-ab0a47dd4912
xfsdump: session label: ""
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 3092218176 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description: 
xfsrestore: hostname: lesson-2
xfsrestore: mount point: /
xfsrestore: volume: /dev/sda1
xfsrestore: session time: Thu Jun  6 18:28:36 2019
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: f52f361a-da1a-4ea0-8c7f-ca2706e86b46
xfsrestore: session id: 3c98126c-ee89-4689-8e8d-ab0a47dd4912
xfsrestore: media id: 2d4b7657-9106-4a40-a5b9-e7993ce80ad2
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 3374 directories and 35818 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 3048174440 bytes
xfsdump: dump size (non-dir files) : 3027211040 bytes
xfsdump: dump complete: 78 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 78 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

# Подключаем служебные файловые системы, chroot в новую систему

```
[root@lesson-2 vagrant]# mount --bind /proc /mnt/proc && mount --bind /dev /mnt/dev && mount --bind /sys /mnt/sys && mount --bind /run /mnt/run && chroot /mnt/
```

# Записываем конфиг для mdadm

```
[root@lesson-2 /]# mdadm --detail --scan > /etc/mdadm.conf
```

# Корректируем fstab под рейд

```
[root@lesson-2 /]# blkid /dev/md*
/dev/md1: UUID="f811417c-e94d-4aee-a975-a001d0fecb43" TYPE="xfs" 
[root@lesson-2 /]# vim /etc/fstab

  #
  # /etc/fstab
  # Created by anaconda on Thu Feb 28 20:50:01 2019
  #
  # Accessible filesystems, by reference, are maintained under '/dev/disk'
  # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
  #
  UUID=f811417c-e94d-4aee-a975-a001d0fecb43 /                       xfs     defaults        0 0
  /swapfile none swap defaults 0 0
```

#Backup-им initramfs, создаем новую с поддержкой mdadmconf

```
[root@lesson-2 /]# mv /boot/initramfs-3.10.0-957.5.1.el7.x86_64.img /boot/initramfs-3.10.0-957.5.1.el7.x86_64.img.back
[root@lesson-2 /]# dracut --mdadmconf --fstab --add="mdraid" --filesystems "xfs" --add-drivers="raid1" --force /boot/initramfs-$(uname -r).img $(uname -r) -M
bash
nss-softokn
i18n
kernel-modules
mdraid
qemu
rootfs-block
terminfo
udev-rules
biosdevname
systemd
usrmount
base
fs-lib
shutdown
```

# Обновляем правила для grub, что бы ядро знала про рейд

```
[root@lesson-2 /]# vim /etc/default/grub

GRUB_CMDLINE_LINUX="no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.auto=1"
GRUB_PRELOAD_MODULES="mdraid1x"
```

# Генерируем новый конфиг

```
[root@lesson-2 /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Found linux image: /boot/vmlinuz-3.10.0-957.5.1.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-957.5.1.el7.x86_64.img
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
/usr/sbin/grub2-probe: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
done
```

# Прописываем grub на диск, перезагружаемся

```
[root@lesson-2 vagrant]# grub2-install /dev/sdb
Installing for i386-pc platform.
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Installation finished. No error reported.
```

# Выбираем в bios второй диск

![Log image](https://github.com/060P0TEHb/otus-study/raw/master/Lesson2-hard/load_log.jpg)

# Промежуточный итог

```
[vagrant@lesson-2 ~]$ lsblk 
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk  
└─sda1    8:1    0  40G  0 part  
sdb       8:16   0  40G  0 disk  
└─sdb1    8:17   0  40G  0 part  
  └─md1   9:1    0  40G  0 raid1 /
```

# Изменяем тип раздела для первого диска

```
[vagrant@lesson-2 ~]$ sudo su
[root@lesson-2 vagrant]# fdisk /dev/sda
Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.


Command (m for help): t
Selected partition 1
Hex code (type L to list all codes): fd
Changed type of partition 'Linux' to 'Linux raid autodetect'

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```

# Подключаем первый диск к рейду и наблюдаем за синхронизацией

```
[root@lesson-2 vagrant]# mdadm --manage /dev/md1 --add /dev/sda1
mdadm: added /dev/sda1

watch -n1 "cat /proc/mdstat"

Every 1.0s: cat /proc/mdstat                                                                                                                          Thu Jun  6 19:30:27 2019

Personalities : [raid1]
md1 : active raid1 sda1[2] sdb1[1]
      41908224 blocks super 1.2 [2/1] [_U]
      [==>..................]  recovery = 10.8% (4541056/41908224) finish=5.1min speed=122096K/sec

unused devices: <none>

Personalities : [raid1] 
md1 : active raid1 sda1[2] sdb1[1]
      41908224 blocks super 1.2 [2/2] [UU]
      
unused devices: <none>
```

# Устанавливаем grub на первый диск

```
[root@lesson-2 vagrant]# grub2-install /dev/sda
Installing for i386-pc platform.
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
grub2-install: warning: Couldn't find physical volume `(null)'. Some modules may be missing from core image..
Installation finished. No error reported.
```

# Проверяем, вы прекрасны

```
[vagrant@lesson-2 ~]$ lsblk 
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk  
└─sda1    8:1    0  40G  0 part  
  └─md1   9:1    0  40G  0 raid1 /
sdb       8:16   0  40G  0 disk  
└─sdb1    8:17   0  40G  0 part  
  └─md1   9:1    0  40G  0 raid1 /
```

