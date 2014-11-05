#!/bin/bash 

PARTITION_BY_NAME=/dev/block/platform/msm_sdcc.1/by-name/TA

inspectPartition() {
	opId=`adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c 'OP_ID='"`
	opName=`adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c 'OP_NAME='"`
	rooting=`adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c 'ROOTING_ALLOWED='"`
	s1Boot=`adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c -i 'S1_Boot'"`
	s1Loader=`adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c -i 'S1_Loader'"`
	s1Hw=`adb shell su -c "$BB cat /dev/block/$1 | $BB grep -s -m 1 -c -i 'S1_HWConf'"`

	if [[ "$opId" =~ "1" ]] && [[ "$opName" =~ "1" ]] && [[ "$rooting" =~ "1" ]] && [[ "$s1Boot" =~ "1" ]] && [[ "$s1Loader" =~ "1" ]] && [[ "$s1Hw" =~ "1" ]]
	then
		echo $1
	fi
}

root=`./check-root.sh`

#if not rooted, exit
if [ "$root" == "" ]
then 
	echo "Not rooted"
	exit 1
fi

backup_defaultTA=`adb shell su -c "$BB ls -l --color=never $PARTITION_BY_NAME" | tr -s ' ' | awk '{print $11}'`
#remove invalid head/tail chars
backup_defaultTA=`expr match "$backup_defaultTA" '\([0-9a-z\/]*\)'`

if [[ $backup_defaultTA != /* ]]
then
	echo Partition not found by name, trying harder 
	
	partition="";

	for part in `adb shell su -c "$BB cat /proc/partitions " | awk '{if ($3<=9999) print $4}'|grep --color=never mmcblk|xargs`
	do
		safepart=`expr match "$part" '\([0-9a-z\/]*\)'`
		echo ? $safepart
		possible=$(inspectPartition "$safepart")
		echo = $possible
		x=`adb shell su -c "$BB cat /dev/block/$safepart | $BB grep -s -m 1 -c 'OP_ID='"`
	done
	
	echo 

	#more than one match - fail 

	#one - OK
		
	echo found /dev/block/$part
	export partition=/dev/block/$part

	#else

	echo No partitions found.
	exit 1
fi

backup_defaultTAvalid=`adb shell su -c "if [ -b $backup_defaultTA ]; then echo '1'; else echo '0'; fi"`

if [[ "$backup_defaultTAvalid" =~ "1" ]]
then
	export partition=$backup_defaultTA
	echo found $partition
else 
	echo Partition found but not valid
	echo backup_defaultTA $backup_defaultTA
	echo backup_defaultTAvalid $backup_defaultTAvalid
	exit 1
fi