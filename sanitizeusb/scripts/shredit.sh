#!/bin/sh

if [ -a ~/.usb-drive-log-probedisk ];then
  rm -rf ~/.usb-drive-log-probedisk
  probedisk > /dev/null
fi

. /etc/rc.d/PUPSTATE

boot=`echo $PDEV1 | awk -F "," '{ print $1 }' | sed s'/.$//'`

#boot=`cat ~/.usb-drive-log-probedisk`
boot1="/dev/"$boot
echo "This is your boot drive" $boot1
devices=`parted -lm | sed -n '/BYT;/{n;p;}' | awk -F":" '{print $1}'`

machine=`dmidecode --type 1 | grep 'Serial Number' | sed 's/ //g' | sed 's/^[ \t]*//'`
trap '' 2 3 20
for a in $devices;
do
 if [ $a = $boot1 ];then
  continue
 fi

dtype=`hdparm -I $a | grep 'Nominal\ Media\ Rotation\ Rate' |awk -F":" '{ print $2 }' | sed 's/ //g'`
f=`hdparm -I $a | grep frozen | awk '{ print $1 }' | sed 's/ //g'`
if [ "$dtype" = "SolidStateDevice" ];then
echo "Checking frozen SSD State"
    if [ "$f" = "not" ];then
       echo "This drive is not frozen: $a"
    else
       echo "Warning This drive is frozen!!!! " $a " Please hot plug the drive or remove!!!" 
       echo "It is advised to stop the sanitize process!"
       echo "Going to try and suspend"
       echo "Unmounting USB"
       umount /root/usb/sanitize
       sleep 5
       /etc/acpi/actions/suspend.sh >/dev/null 2>&1
       
       #mount /dev/$PDEV1 /root/usb/sanitize
    fi
fi
done

echo "##################################################################"
echo "##################################################################"
echo "##################################################################"
echo "Do you want to sanitize the hard drives on this PC?" $machine

while [ false ];do

echo "Enter [Y]es or [N]o"
read input
input=${input,,}

if [ $input = yes ];then
break
fi

if [ $input = y ];then
break
fi

if [ $input = n ];then
echo "Exiting"
exit 1
fi

if [ $input = no ];then
echo "Exiting"
exit 1
fi

done

a=1
result=0
pids=""

printf "%-10s | %s\n" "PC:" "$machine" >> /root/sanitize.log
ds=`date`
printf "%-10s | %s\n" "Start:" "$ds" >> /root/sanitize.log

for i in $devices;do
 if [ $i = $boot1 ];then
  echo "Skipping Boot Disk" $i
  continue
 fi
ndisk=`nvme list | awk '{print $2}' | awk 'FNR == 3 {print}'`
ntype=`nvme list | awk '{print $1}' | awk 'FNR == 3 {print}'` 
disk=`hdparm -I $i | grep 'Serial\ Number' | sed 's/ //g'`  
dtype=`hdparm -I $i | grep 'Nominal\ Media\ Rotation\ Rate' |awk -F":" '{ print $2 }' | sed 's/ //g'`
#echo $dtype


if [ "$dtype" = "SolidStateDevice" ];then
 echo "This is a SSD " $i
 f=`hdparm -I $i | grep frozen | awk '{ print $1 }' | sed 's/ //g'`
   if [ "$f" = "not" ];then
      printf "%-10s | %s\n" "Drive:" $disk >> /root/sanitize.log
      hdparm --user-master u --security-set-pass test $i
      time hdparm --user-master u --security-erase test $i 2> /dev/tty$a &
   else
     echo "This drive is frozen. You may to need to hotswap to unfreeze."
     echo "This is drive: $disk" 
   fi
fi

if [ "$ntype" = "$i" ];then
	echo "This is a NVME Drive " $i
	printf "%-10s | %s\n" "Drive:" $ndisk >> /root/sanitize.log
	nvme format -s1 $i 2> /dev/tty$a &


else
echo "This is a HDD " $i 
printf "%-10s | %s\n" "Drive:" $disk >> /root/sanitize.log
shred -f -v -z --iterations=2 $i 2> /dev/tty$a &

fi

a=`expr $a + 1` 
pids="$pids $!"

done


for pid in $pids; do

  echo "Sanitizing Disks"
  cat /proc/$pid/cmdline
  wait $pid && let "result=1" 
done

if [ "$result" == "1" ];
 then
 de=`date`
 printf "%-10s | %s\n" "End:" "$de" >> /root/sanitize.log
 echo "Finished Checking for Boot Drive"
 while [ false ];do
 
  if [ ! -d "/root/usb/sanitize" ];then
   echo "Please re-insert boot drive"
   read -p "Press [Enter] key when usb key has been re-inserted..."
  fi
  if [ -d "/root/usb/sanitize" ];then
  echo "Mounting USB drive"
  sleep 15
  sync 
    if [ -f "/root/usb/sanitize/vmlinuz" ];then
      cat /root/sanitize.log >> /root/usb/sanitize/sanitize.log
      sync
      umount /root/usb/sanitize 
      echo "Writing log file"
      echo "Sanitization Complete"
      echo "Remove USB Drive and Shut Off PC"
      trap 2 3 20
      exit 1
   fi
  fi
 done
fi
