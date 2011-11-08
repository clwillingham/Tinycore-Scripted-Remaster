#!/bin/sh
# Original script by Robert Shingledecker
# (c) Robert Shingledecker 2003-2010
# A simple script to save/restore configs, directories, etc defined by the user
# in the file .filetool.lst
# Added ideas from WDef for invalid device check and removal of bfe password upon failure
# Added comparerestore and dry run (Brian Smith)

alias awk="busybox awk"
alias dc="busybox dc"
alias expr="busybox expr"
alias ls="busybox ls"
alias mount="busybox mount"
alias tar="busybox tar"
alias umount="busybox umount"
alias wc="busybox wc"
alias sudo='sudo '

. /etc/init.d/tc-functions
CMDLINE="$(cat /proc/cmdline)"

MYDATA=mydata
[ -r /etc/sysconfig/mydata ] && read MYDATA < /etc/sysconfig/mydata
# Functions --

abort(){
  echo "Usage: filetool.sh options device"
  echo "Where options are:"
  echo "-b backup"
  echo "-p prompt"
  echo "-r restore"
  echo "-s safe backup mode"
  echo "-d dry run backup"
  echo -n "Press enter to continue:" ; read ans
  exit 1
}

blowfish_encrypt(){
KEY=$(cat /etc/sysconfig/bfe)
cat << EOD | sudo /usr/bin/bcrypt -c "$MOUNTPOINT"/"$FULLPATH"/$1 2>/dev/null
"$KEY"
"$KEY"
EOD
if [ "$?" != 0 ]; then failed; fi
sync
}

clean_up(){
if [ $MOUNTED == "no" ]; then
  sudo umount $MOUNTPOINT
fi
# Only store device name if backup/restore successful
[ $1 -eq 0 ] && echo "${D2#/dev/}"/$FULLPATH  > /opt/.backup_device
# Remove bfe password if decryption fails
[ $1 -eq 98 ] && rm -f /etc/sysconfig/bfe
sync
exit $1
}

failed(){
echo "${RED}failed.${NORMAL}"
clean_up 98
}

# Main  --
unset BACKUP PROMPT RESTORE SAFE DRYRUN

[ -z $1 ] && abort
if grep -q "safebackup" /proc/cmdline; then SAFE=TRUE; fi
while getopts bprsd OPTION
do
  case ${OPTION} in
   b) BACKUP=TRUE ;;
   p) PROMPT=TRUE ;;
   r) RESTORE=TRUE ;;
   s) SAFE=TRUE ;;
   d) DRYRUN=TRUE ;;
   *) abort ;;
  esac
done
[ "$BACKUP" ] && [ "$RESTORE" ] && abort
shift `expr $OPTIND - 1`
# TARGET device is now $1

if [ $DRYRUN ]; then
  echo "${BLUE}Performing dry run backup (backup will not actually take place).   Please wait.${NORMAL}"; echo
  totalcompressedsize=`sudo tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst -cvzf - 2>/tmp/backup_dryrun_list | wc -c`
  for entry in `cat /tmp/backup_dryrun_list`; do
    if [ -f "/${entry}" ]; then
      size=`sudo ls -al "/${entry}" | awk '{print $5}'`
      totalsize=$(($totalsize + $size))
      sizemb=`dc $size 1024 / 1024 / p`
      printf "%6.2f MB  /%s\n" $sizemb $entry
    fi
  done
  rm /tmp/backup_dryrun_list
  totalsizemb=`dc $totalsize 1024 / 1024 / p`
  totalcompressedsizemb=`dc $totalcompressedsize 1024 / 1024 / p`
  printf "\nTotal backup size (uncompressed):  %6.2f MB (%d bytes)\n" $totalsizemb $totalsize
  printf "Total backup size (compressed)  :  %6.2f MB (%d bytes)\n\n" $totalcompressedsizemb $totalcompressedsize
  exit 0
fi

#Get the TARGET name from argument 1 or /opt/.backup_device
if [ -z $1 ]; then
  TARGET="$(cat /opt/.backup_device 2>/dev/null)"
else
  TARGET="$1"
fi

if [ -z "$TARGET" ]; then
  # Last chance to default to persistent TCE directory if exists
  read TCEDIR < /opt/.tce_dir
  if [ "$TCEDIR" == "/tmp/tce" ]; then
    echo "Invalid or not found $TARGET"
    echo -n "Press enter to continue:" ; read ans
    exit 1
  else
    TARGET="${TCEDIR#/mnt/}"
  fi
fi

TARGET="${TARGET#/dev/}"
DEVICE="${TARGET%%/*}"
FULLPATH="${TARGET#$DEVICE/}"
[ "$FULLPATH" = "$DEVICE" ] && FULLPATH=""

find_mountpoint $DEVICE

if [ -z "$MOUNTPOINT" ]; then
  echo "Invalid device $DEVICE"
  echo -n "Press enter to continue:" ; read ans
  exit 1
fi

if [ $MOUNTED == "no" ]; then
   sudo mount $MOUNTPOINT
   if [ "$?" != 0 ]; then
      echo "Unable to mount device $DEVICE"
      echo -n "Press enter to continue:" ; read ans
      exit 1
   fi
fi

echo "${D2#/dev/}"/$FULLPATH > /opt/.backup_device

trap failed SIGTERM

if [ "$BACKUP" ] ; then
  sed -i /^$/d /opt/.filetool.lst
  if [ "$SAFE" ]; then
    if [ -r $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz.bfe -o -r $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz ]; then                     
      echo -n "${BLUE}Copying existing backup to ${GREEN}$MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.[tgz|tgz.bfe]${NORMAL} .. "  
      sudo mv -f $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.tgz 2>/dev/null || sudo mv -f $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz.bfe $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.tgz.bfe 2>/dev/null
      if [ "$?" == 0 ]; then
        echo "${GREEN}Done."
      else
        echo "Error: Unable to rename ${MYDATA}.tgz to ${MYDATA}bk.tgz"
        exit 2
      fi
    else                                                                                                                      
      echo "Neither ${MYDATA}.tgz nor ${MYDATA}.tgz.bfe exist.  Proceeding with creation of initial backup ..."               
    fi
  fi
  if [ "$PROMPT" ]; then
    sudo tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst  -czvf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz
    echo -n "Press enter to continue:" ; read ans
  else
    echo -n "${BLUE}Backing up files to ${GREEN}$MOUNTPOINT/$FULLPATH/${MYDATA}.tgz ${NORMAL}"
    [ -f /tmp/backup_status ] && sudo rm -f /tmp/backup_status
    sudo tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst  -czf "$MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz"  2>/tmp/backup_status &
    rotdash $!
    sync
    [ -s /tmp/backup_status ] && sed -i '/socket ignored/d' /tmp/backup_status 2>/dev/null
    [ -s /tmp/backup_status ] && exit 1
    touch /tmp/backup_done
  fi
  if [ -f /etc/sysconfig/bfe ]; then
     echo -n "encrypting .. "
     blowfish_encrypt ${MYDATA}.tgz
  fi
  echo "${GREEN}Done.${NORMAL}"
  clean_up 0
fi

if [ "$RESTORE" ] ; then
  if [ -f /etc/sysconfig/bfe ]; then
     TARGETFILE="${MYDATA}.tgz.bfe"
  else
     TARGETFILE="${MYDATA}.tgz"
  fi
  if [ ! -f $MOUNTPOINT/"$FULLPATH"/$TARGETFILE ] ; then
     if [ $MOUNTED == "no" ]; then
      sudo umount $MOUNTPOINT
     fi
  fi
  if [ -f /etc/sysconfig/bfe ]; then
     KEY=$(cat /etc/sysconfig/bfe)
     if grep -q "comparerestore" /proc/cmdline && [ ! -e /etc/sysconfig/comparerestore ]; then
       for file in `cat << EOD | /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | tar -tzf -
"$KEY"
EOD`; do
	 if [ -f "/${file}" ]; then
	   sudo mv "/${file}" "/${file}.orig_file"
	 fi
       done
       sudo touch /etc/sysconfig/comparerestore
     fi
     if [ "$PROMPT" ]; then
cat << EOD | sudo /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | sudo tar  -C / -zxvf -
"$KEY"
EOD
       if [ "$?" != 0 ]; then failed; fi
       echo -n "Press enter to continue:" ; read ans
     else
       echo -n "${BLUE}Restoring backup files from encrypted backup ${YELLOW}$MOUNTPOINT/$FULLPATH ${BLUE}mounted over device ${MAGENTA}$D2 ${NORMAL}"
cat << EOD | sudo /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | sudo tar  -C / -zxf -
"$KEY"
EOD
       if [ "$?" != 0 ]; then failed; fi
       echo "${GREEN}Done.${NORMAL}"
     fi
     clean_up 0
  fi
  if grep -q "comparerestore" /proc/cmdline && [ ! -e /etc/sysconfig/comparerestore ]; then
    for file in `tar -tzf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz`; do
      if [ -f "/${file}" ]; then
	sudo mv "/${file}" "/${file}.orig_file"
      fi
    done
    sudo touch /etc/sysconfig/comparerestore
  fi
  if [ "$PROMPT" ]; then
    sudo tar -C / -zxvf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz
    echo -n "Press enter to continue:" ; read ans
  else
    echo -n "${BLUE}Restoring backup files from ${YELLOW}$MOUNTPOINT/$FULLPATH/${MYDATA}.tgz ${NORMAL}"
    sudo tar -C / -zxf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz 2>/dev/null &
    rotdash $!
    echo "${GREEN}Done.${NORMAL}"
  fi
  clean_up 0
fi
echo "I don't understand the command line parameter: $1"
abort
