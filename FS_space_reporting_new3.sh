#!/bin/sh
# Use this script to generate FS reports

echo
HOSTNAME=`uname -n`
echo HOSTNAME=$HOSTNAME
echo

## Create the work directory if not found
## 02-Oct-2018 - Corrected a bug in which the script fails if the target directory path exists as a file instead of as a directory.

if [ ! -d /tmp/FS.REPORTS_${HOSTNAME} ]
then
	# In case the destination path exists as a file, it needs to be deleted 
	rm /tmp/FS.REPORTS_${HOSTNAME}
	echo "Work directory not found, creating it now."
	mkdir /tmp/FS.REPORTS_${HOSTNAME}
	ls -ld /tmp/FS.REPORTS_${HOSTNAME}
	echo
else
	echo "Work directory found, clearing the directory:"
	ls -l /tmp/FS.REPORTS_${HOSTNAME}
	rm /tmp/FS.REPORTS_${HOSTNAME}/*
	ls -l /tmp/FS.REPORTS_${HOSTNAME}
	echo
fi

## Determine the OS
OS=`uname -a | awk '{print $1}'`

## <Start> - Outer case statement - To select script execution path based on OS
case $OS in
HP-UX)

	#############################################
	echo "The HP-UX portion is not yet ready yet"
	#############################################

;;
AIX)

## Prompt user for input
echo "Do you wish to gather statistics for single FS or all FS?"
echo 
echo "Please enter 1 for single FS or 2 for all FS."

## Read user's input to a variable
read FS_option

## New section added on 18 Sep 2018 
## <Start> - Inner case statement 1 - To provide the option of selecting only a specific FS for reporting 
## Re-direct script execution depending on above user choice
case $FS_option in
1)
	# Section which is executed if a specific FS is to be reported
	df -gt
	echo
	
	## Prompt user for input
	echo "Please select the FS to collect statistics from the above listing"
	echo
	echo ">> Please enter ONLY the /dev/xxxx path (first column) to avoid incorrect reporting:"
	
	## Read user's input to a variable
	read FS_selected
	echo

	## Check if user's input is valid
	echo "Checking if $FS_selected is listed under /etc/filesystems"
	echo
	lsfs | grep -w "$FS_selected"
	if [ $? -ne 0 ]
	then
		echo "Invalid choice. Please run script and select again."
		exit 1
	else
		echo
		echo "The selected FS is found in /etc/filesystems" 
		echo ">> Please press any key to continue or Ctrl-C to abort"
		read userinput
	fi
;;
2)
	# Section which is executed if no specific FS is selected. (All FS will selected for reporting).
	
	## Prompt user for any input to proceed with rest of script
	echo "You have opted to gather statistics for all mounted FS and this will take a longer time."
	echo ">> Please press any key to continue or Ctrl-C to abort"
	read userinput
;;
*)
	## Exit the script if user input is invalid
	echo "Invalid choice. Please run script and select again."
	exit 1
;;
esac
## <End> - Inner case statement 1 - To provide the option of selecting only a specific FS for reporting 

## Prompt user for input
echo "Please enter a choice and press return."
echo "	Enter 1 to generate the FS report for a specific date."
echo "	Enter 2 to generate the FS report for a specific month."
echo "	Enter 3 to generate the FS report for the last 7 days (~ 1 week)" 
echo "	Enter 4 to generate the FS report for the last 30 days (~ 1 month)" 
echo "	Enter 5 to generate the FS report for the last 180 days (~ 6 months)" 
echo "	Enter 6 to generate the FS report for the last 365 days (~ 1 year)" 
echo "	Enter 7 to generate the FS report between a specific Start and End date"

## Read user's input to a variable
read choice

## <Start> - Inner case statement 2 - To select the specific date or range for reporting and copy the required souce files to the work directory
case $choice in
1)
	# Section which is executed if a specific date is to be selected 
	
	## Prompt user for input
	echo "Please enter the sample date in ddmmyy (eg. 120517 for 12-May-2017) format:"
	read ddmmyy
	echo $ddmmyy
	
	## Check if user's input is valid (and exit script if input is invalid)
	ls -lrt /var/adm/sa/df_log."$ddmmyy"* 
	if [ $? -ne 0 ]
	then
		echo "/var/adm/sa/df_log.$ddmmyy cannot be found."
		exit 1
	fi
	
	## Copy the relevant data files from source to the work directory 
	ls -lrt /var/adm/sa/df_log."$ddmmyy"* | awk -v var="$HOSTNAME" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x
	
	## Assign a value to the SAMPLING variable which will be used to determine which script section to be executed at the next CASE statement
	SAMPLING=ALL
	
	## Assign a name to the TAG variable which will be used to rename the final report for easy identification
	TAG=$SAMPLING.For_the_date_$ddmmyy
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
2)
	# Section which is executed if a specific month is to be selected for reporting
	
	## Prompt user for input
	echo "Please enter the sample month in Mmm_YYYY (eg. May_2017) format:"
	
	## Read user's input to a variable
	read Mmm_YYYY
	echo $Mmm_YYYY
	
	## Check if user's input is valid (and exit script if input is invalid)
	ls -lrt /var/adm/sa/FS_monthly_report.${HOSTNAME}*"$Mmm_YYYY"* 
	if [ $? -ne 0 ]
	then
		echo "/var/adm/sa/FS_monthly_report.${HOSTNAME}."$Mmm_YYYY" cannot be found."
		exit 1
	fi
	
	## Copy the relevant data files from source to the work directory 
	ls -lrt /var/adm/sa/FS_monthly_report.${HOSTNAME}*"$Mmm_YYYY"* | awk -v var="$HOSTNAME" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x
	
	## Assign a value to the SAMPLING variable which will be used to determine which script section to be executed at the next CASE statement
	SAMPLING=ONCE_DAILY
	
	## Assign a name to the TAG variable which will be used to rename the final report for easy identification
	TAG=$SAMPLING.For_the_month_$Mmm_YYYY
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
3)
	# Section which is executed if the past 7 days is to be selected for reporting
	find /var/adm/sa -type f -mtime -7 -name "df_log.*" | awk -v var="$HOSTNAME" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x 
	SAMPLING=ALL
	TAG=$SAMPLING.Past_7_days_Until_$(date +%d%m%y)
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
4)
	# Section which is executed if the past 30 days is to be selected for reporting
	
	## Copy the relevant data files from source to the work directory 
	find /var/adm/sa -type f -mtime -30 -name "FS_monthly_report.*" | awk -v var="$HOSTNAME" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x 
	
	## Assign a value to the SAMPLING variable which will be used to determine which script section to be executed at the next CASE statement
	SAMPLING=ONCE_DAILY
	
	## Assign a name to the TAG variable which will be used to rename the final report for easy identification
	TAG=$SAMPLING.Past_1_month_Until_$(date +%d%m%y)
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
5)
	# Section which is executed if the past 180 days is to be selected for reporting 
	
	## Copy the relevant data files from source to the work directory 
	find /var/adm/sa -type f -mtime -180 -name "FS_monthly_report.*" | awk -v var="$HOSTNAME" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x 
	
	## Assign a value to the SAMPLING variable which will be used to determine which script section to be executed at the next CASE statement
	SAMPLING=ONCE_MONTHLY
	
	## Assign a name to the TAG variable which will be used to rename the final report for easy identification
	TAG=$SAMPLING.Past_6_months_Until_01$(date +%m%y)
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
6)
	# Section which is executed if the past 365 days is to be selected for reporting 
	
	## Copy the relevant data files from source to the work directory 
	find /var/adm/sa -type f -mtime -365 -name "FS_monthly_report.*" | awk -v var="$HOSTNAME" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x 
	
	## Assign a value to the SAMPLING variable which will be used to determine which script section to be executed at the next CASE statement
	SAMPLING=ONCE_MONTHLY
	
	## Assign a name to the TAG variable which will be used to rename the final report for easy identification
	TAG=$SAMPLING.Past_12_months_Until_01$(date +%m%y)
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
7)
	# Section which is executed if a specific start and end date is to be selected 
	
	## Prompt user for input for the Start Date
	echo "Please enter the Start date in ddmmyy (eg. 010918 for 01-Sep-2018) format:"
	read StartDate
	echo You have selected the Start date as: $StartDate
	echo
	## Prompt user for input for the End Date
	echo "Please enter the End date in ddmmyy (eg. 260918 for 26-Sep-2018) format:"
	read EndDate
	echo You have selected the End date as: $EndDate
	echo
	
	## Check if user's input is valid (and exit script if input is invalid)
	ls -lrt /var/adm/sa/df_log.* | awk "/$StartDate/,/$EndDate/"
	if [ $? -ne 0 ]
	then
		echo "There are no files found within the selected start and end dates."
		exit 1
	else	
		## Copy the relevant data files from source to the work directory 
		ls -lrt /var/adm/sa/df_log.* | awk "/${StartDate}/,/${EndDate}/" | awk -v var="${HOSTNAME}" '{print "cp -p",$NF,"/tmp/FS.REPORTS_"var}' | sh -x
	fi
		
	## Assign a value to the SAMPLING variable which will be used to determine which script section to be executed at the next CASE statement
	SAMPLING=ALL
	
	## Assign a name to the TAG variable which will be used to rename the final report for easy identification
	TAG=$SAMPLING.From_${StartDate}_to_${EndDate}
	echo SAMPLING=$SAMPLING
	echo TAG=$TAG
;;
*)
	## Exit the script if user input is invalid
	echo "Invalid choice. Please run script and select again."
	exit 1
;;
esac
## <End> - Inner case statement 2 - To select the specific date or range for reporting and copy the required souce files to the work directory


## Uncompress any gzip files in the work directory 
gunzip /tmp/FS.REPORTS_${HOSTNAME}/*.gz
ls -lrt /tmp/FS.REPORTS_${HOSTNAME}
cd /tmp/FS.REPORTS_${HOSTNAME}


## Define the intermediate output file
IOF="/tmp/FS.REPORTS_${HOSTNAME}/FS_report.${HOSTNAME}.Per_sampling_interval"
touch $IOF
ls -l $IOF
if [ $? -ne 0] 
then
	echo "Failed to create $IOF"
	echo "Please check if work directory exists or if directory permission is incorrect."
	exit 1
else
	echo "Initialise the intermediate output file"
	cat /dev/null > $IOF
	ls -l $IOF
fi


## <Start> - Inner case statement 3 - Generate the csv report based on earlier selections
case $SAMPLING in
"ALL")
	# Section which is executed if variable SAMPLING=ALL
	
	## Generate a list of df_log.* files in the work directory
	ls -lrt /tmp/FS.REPORTS_${HOSTNAME}/df_log.* | awk '{print $NF}' > /tmp/FS.REPORTS_${HOSTNAME}/filecol
	cat /tmp/FS.REPORTS_${HOSTNAME}/filecol

	## Generate a list of time stamps for each sample interval
	## (29 Jun 2017 - Added -e CST to cater for SCC servers)
	ls -lrt /tmp/FS.REPORTS_${HOSTNAME}/df_log.* | awk '{print "cat",$NF,"| grep -e SGT -e CST"}' | sh > /tmp/FS.REPORTS_${HOSTNAME}/datecol
	cat /tmp/FS.REPORTS_${HOSTNAME}/datecol

	## Populate the intermediate output file
	if [[ -n "$FS_selected" ]]
	then

		# Section which is executed if a specific FS was selected for reporting
		while read -r row
		do
		cat df_log.* | grep -v "#" | grep -p "$row" | egrep -w "Filesystem|SGT|CST|^$|$FS_selected" >> "$IOF"
		done < /tmp/FS.REPORTS_${HOSTNAME}/datecol
		
	else

		# Section which is executed if all FS are to be reported
		while read -r row
		do
		cat df_log.* | grep -p "$row" | grep -v "#" >> "$IOF"
		done < /tmp/FS.REPORTS_${HOSTNAME}/datecol
				
	fi
;;
"ONCE_DAILY")
	# Section which is executed if variable SAMPLING=ONCE_DAILY
	
	## Generate a listing of FS_monthly_report.* files in the directory
	ls -lrt /tmp/FS.REPORTS_${HOSTNAME}/FS_monthly_report.* | awk '{print $NF}' > /tmp/FS.REPORTS_${HOSTNAME}/filecol
	cat /tmp/FS.REPORTS_${HOSTNAME}/filecol

	## Generate a listing containing the first time stamp entry for each day
	## (29 Jun 2017 - Added -e CST to cater for SCC servers)
	ls -lrt /tmp/FS.REPORTS_${HOSTNAME}/FS_monthly_report.* | awk '{print "cat",$NF}' | sh | grep -e SGT -e CST > /tmp/FS.REPORTS_${HOSTNAME}/datecol
	cat /tmp/FS.REPORTS_${HOSTNAME}/datecol

	## Populate the intermediate output file
	if [[ -n "$FS_selected" ]]
	then

		# Section which is executed if a specific FS was selected for reporting
		while read -r row
		do
		cat FS_monthly_report.$HOSTNAME.* | grep -v "#" | grep -p "$row" | egrep -w "Filesystem|SGT|CST|^$|$FS_selected" >> "$IOF"
		done < /tmp/FS.REPORTS_${HOSTNAME}/datecol
		
	else

		# Section which is executed if all FS are to be reported
		while read -r row
		do
		cat FS_monthly_report.$HOSTNAME.* | grep -p "$row" >> "$IOF"
		done < /tmp/FS.REPORTS_${HOSTNAME}/datecol
				
	fi
;;
"ONCE_MONTHLY")
	# Section which is executed if variable SAMPLING=ONCE_MONTHLY

	## Generate a listing of FS_monthly_report.* files in the directory
	ls -lrt /tmp/FS.REPORTS_${HOSTNAME}/FS_monthly_report.* | awk '{print $NF}' > /tmp/FS.REPORTS_${HOSTNAME}/filecol
	cat /tmp/FS.REPORTS_${HOSTNAME}/filecol

	## Generate a listing containing the first time stamp entry for each month 
	ls -lrt /tmp/FS.REPORTS_${HOSTNAME}/FS_monthly_report.* | awk '{print "head -1",$NF}' | sh > /tmp/FS.REPORTS_${HOSTNAME}/datecol
	cat /tmp/FS.REPORTS_${HOSTNAME}/datecol

	## Populate the intermediate output file
	if [[ -n "$FS_selected" ]]
	then

		# Section which is executed if a specific FS was selected for reporting
		while read -r row
		do
		cat FS_monthly_report.$HOSTNAME.* | grep -v "#" | grep -p "$row" | egrep -w "Filesystem|SGT|CST|^$|$FS_selected" >> "$IOF"
		done < /tmp/FS.REPORTS_${HOSTNAME}/datecol
		
	else

		# Section which is executed if all FS are to be reported
		while read -r row
		do
		cat FS_monthly_report.$HOSTNAME.* | grep -p "$row" >> "$IOF"
		done < /tmp/FS.REPORTS_${HOSTNAME}/datecol
				
	fi
;;
esac
## <End> - Inner case statement 3 - Generate the csv report based on earlier selections

##################
# COMMON SECTION #
##################

## Display the contents of the intermediate output file on screen
cat "$IOF"
	
## Generate a list of directory mount points to be reported 
cat "$IOF" | grep "/dev/"  | awk '{print $NF}' | sort -k1 | uniq > /tmp/FS.REPORTS_${HOSTNAME}/fs_list
cat /tmp/FS.REPORTS_${HOSTNAME}/fs_list

## Generate a list of FS names to be reported 
cat "$IOF" | grep "/dev/"  | awk '{print $1}' | sort -k1 | uniq > /tmp/FS.REPORTS_${HOSTNAME}/lv_list
cat /tmp/FS.REPORTS_${HOSTNAME}/lv_list

## Initialise the final .csv output file
cat /dev/null > /tmp/FS.REPORTS_${HOSTNAME}/${HOSTNAME}.FS.history.$TAG.csv

## Dual loop execution
## Outer loop iterates through each FS entry, waits for the inner loop to complete execution on that entry, before proceeding to the next FS entry
while read -r LV
do
echo "" >> /tmp/FS.REPORTS_${HOSTNAME}/${HOSTNAME}.FS.history.$TAG.csv
		
## Determine the units used in FS reporting and store it in a variable 
UNITS=$(cat "$IOF" | grep Filesystem | awk '{print $2}' | uniq)
echo $UNITS

## Write the appropriate header details to the final .csv output file depending on the above variable
case "$UNITS" in
1024-blocks)
echo "Date,Filesystem,KB_allocated,KB_used,KB_free,%Used,Mountpoint" >> /tmp/FS.REPORTS_${HOSTNAME}/${HOSTNAME}.FS.history.$TAG.csv
;;
MB)
echo "Date,Filesystem,MB_allocated,MB_used,MB_free,%Used,Mountpoint" >> /tmp/FS.REPORTS_${HOSTNAME}/${HOSTNAME}.FS.history.$TAG.csv
;;
GB)
echo "Date,Filesystem,GB_allocated,GB_used,GB_free,%Used,Mountpoint" >> /tmp/FS.REPORTS_${HOSTNAME}/${HOSTNAME}.FS.history.$TAG.csv
;;
esac

## Inner loop iterates through each date entry and writes the statistics for the current selected FS to the .csv output file. 
while read -r DATE
do
## For each loop iteration, re-express the sampled time stamp as a single column and write the output to a temporary file.
echo "$DATE" | awk '{print $1"_"$2"_"$3"_"$4"_"$6}' > /tmp/CurrentSampleDate
			
## Check if any statistics was captured for the current iterated FS during the current interated time stamp
cat "$IOF" | grep -p "$DATE" | grep -w "$LV"

if [ $? -eq 0 ]
then
## If FS statistics were recorded during the current iterated time stamp, re-express the data as comma-delimited columns and write the output to a temporary file.
cat "$IOF" | grep -p "$DATE" | grep -w "$LV" | awk '{OFS=",";print $1,$2,$3,$4,$5,$6}' > /tmp/LV_show
else
## If no FS statistics were recorded (Eg. FS was not mounted or deleted) during the current iterated time stamp, write a 0 value to all data columns to the temporary file 
echo "0,0,0,0,0,0" > /tmp/LV_show
fi

## Combine the time stamp and data columns from both temporary files and write the output to the final .csv output file
paste /tmp/CurrentSampleDate /tmp/LV_show | awk '{print $1","$2}' >> /tmp/FS.REPORTS_${HOSTNAME}/${HOSTNAME}.FS.history.$TAG.csv
			
done < /tmp/FS.REPORTS_${HOSTNAME}/datecol

done < /tmp/FS.REPORTS_${HOSTNAME}/lv_list

## FTP a copy of the final .csv output file to PC	
cd /tmp/FS.REPORTS_${HOSTNAME}
/ftp2pc.sh ${HOSTNAME}.FS.history.$TAG.csv

;;
esac
## <End> - Outer case statement - To select script execution path based on OS

exit 0

