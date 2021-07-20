#120221 moved this code here from /etc/profile, also take 'exec' prefix off call to xwin.

if which Xorg &>/dev/null ; then
   #want to go straight into X on bootup only...
   if [ ! -f /tmp/bootcnt.txt ] ; then
      touch /tmp/bootcnt.txt
      dmesg > /tmp/bootkernel.log
      xwin
   fi
else
   echo -e "\n\\033[1;31mSorry, cannot start X.. Xorg not found. \\033[0;39m"
fi

### END ###

##############
echo "Beginning to Sanitize This PC?"
while [ false ];do

echo "Enter [Y]es or [N]o"
read input
input=${input,,}

if [ $input = yes ];then
/root/shredit.sh
break
fi

if [ $input = y ];then
/root/shredit.sh
break
fi

if [ $input = n ];then
echo "Exiting"
break
fi

if [ $input = no ];then
echo "Exiting"
break
fi

done
