#!/bin/bash

#########################################################################################################
# IMPORTANT:  This software is supplied to you by Mobidelio in
# consideration of your agreement to the following terms, and your use, installation,
# modification or redistribution of this Mobidelio software constitutes acceptance of these
# terms.  If you do not agree with these terms, please do not use or install this Mobidelio
# software.
#
# This script is licensed to you as part of the MobileNow Management subscription. Mobidelio
# grants you a non-transferable, non-exclusive license to use this script for the duration of the
# subscription. If you'd like updates or support sign up at https://www.mobidelio.com or
# email getsupport@mobidelio.com for more details
#
# You SHOULD NOT redistribute this source code with or without modification.
#
# The Mobidelio Software is provided by Mobidelio on an "AS IS" basis.  Mobidelio
# MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF
# NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE
# Mobidelio SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
#
# IN NO EVENT SHALL Mobidelio BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE,
# REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE Mobidelio SOFTWARE, HOWEVER CAUSED AND
# WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
# OTHERWISE, EVEN IF Mobidelio HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#########################################################################################################

# Copyright Mobidelio 2025. All Rights Reserved.
# Provide Feedback: feedback@mobidelio.com

#########################################################################################################
# Script uses powermetrics tool to capture performance data from a Mac computer.
#########################################################################################################

# Define variables
jamfProURL="$4"
jamfProUser="$5"
jamfProPassEnc="$6"
salt="$7"
passPhrase="$8"

#jamfProPass=$(echo "$jamfProPassEnc" | /usr/bin/openssl enc -aes256 -d -a -A -S "$salt" -k "$passPhrase")

# Commands to collect information
# This section includes all commands that can produce useful information from the Mac
# including processes, kernel, disk, network and file system information.
# Adds any additional commands you want to collect output from to the array below
clientCommandArray=(
"/bin/df -l -h"
"/bin/ls -alrt /Library/Receipts"
"/bin/ls -alrt /Library/LaunchDaemons"
"/bin/ls -alrt /Library/LaunchAgents"
"/bin/ps -auwww"
"/sbin/ifconfig"
"/usr/bin/top -ocpu -l5 -s2"
"/usr/bin/uname -a"
"/usr/bin/uptime"
"/usr/bin/zprint"
"/usr/sbin/diskutil list"
"/usr/sbin/ioreg"
"/usr/sbin/kextstat"
"/usr/sbin/lsof -nP"
"/usr/sbin/netstat -r"
"/usr/sbin/netstat -s"
"/usr/sbin/sysctl -a"
"/usr/bin/systemextensionsctl list"
"/usr/sbin/sysadminctl -filesystem status"
)

# System Log Files
# This section includes all log files that can produce useful information from the Mac
# including logs from the installer, system, file system, diagnostics and network services.
# Add any additional logs you want to collect to the array below
logsArray=(
"/private/var/log/install.log"
"/private/var/log/system.log"
"/private/var/log/fsck_apfs_error.log"
"/private/var/log/fsck_apfs.log"
"/private/var/log/fsck_hfs.log"
"/Library/Logs/DiagnosticReports"
"/private/var/log/wifi.log"
)

# System variables
mySerial=$(system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}')
currentUser=$(stat -f%Su /dev/console)
compHostName=$(scutil --get LocalHostName)
timeStamp=$(date '+%Y-%m-%d-%H-%M-%S')
sw_vers=$(sw_vers -productVersion)
sw_name=$(sw_vers -productName)
osMajor=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
osMinor=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $2}')

# Script variables
tmpFolder="/private/var/tmp/edc"
zipFileName="edc-$currentUser-$mySerial-$timeStamp.zip"

# Log Collector Log
scriptLog="$tmpFolder/edc-$mySerial.log"

# Third Party Log Files
microsoftLogs="/Library/Logs/Microsoft"

#
# Script functions

# This function will run through the commands array and execute each of the commands
# to collect the output.
commandsCapture() {
for commands in "${clientCommandArray[@]}"; do
    printf "\n" >> "$scriptLog"
    echo "Collecting $commands:" >> "$scriptLog"
    echo "===============================================" >> "$scriptLog"
    $commands >> "$scriptLog"
done
}

# This function will run through the log array and copy each of the log files.
logCapture() {
for logSource in "${logsArray[@]}"; do
    printf "\n" >> "$scriptLog"
    echo "Collecting: $logSource..." >> "$scriptLog"
    /bin/cp -Rp "$logSource"* "$tmpFolder/Logs/"
done
}

# This function will run the spindump utility and capture a system profile of the Mac
# during a time interval.
spinDumpCapture() {
echo "Collecting Spindump..." >> "$scriptLog"
/usr/sbin/spindump -o "$tmpFolder/Spindump.txt"
}

# This function will run the system profile utility to capture all system information
# from the Mac.
systemProfilerCapture() {
echo "Collecting System Information..." >> "$scriptLog"
/usr/sbin/system_profiler -detailLevel 1 -xml > "$tmpFolder/SystemProfiler.spx"
}

# This function will run the fs_usage command to capture samples of the file system
# activity.
fsUsageCapture() {
echo "Collecting File System Usage information..." >> "$scriptLog"
/usr/bin/fs_usage -e -t 30 > "$tmpFolder/fsUsage.txt"
}

# This function runs the powermetrics command to capture a sample of
# energy impact and process usage on the Mac for a specific interval
powermetricsCapture() {
echo "Collecting powermetric samples..." >> "$scriptLog"
/usr/bin/powermetrics -b 1 -n 10 -s tasks --show-process-energy --show-process-io | sed -l "s/^/$(date +%Y-%m-%dT%H:%M:%S" "%Z) /" >> "$tmpFolder/powermetrics.log"
}

# This function runs the wdutil command to run wireles diagnostics
# on the Mac.
# BEWARE: This function will collect about 700MBs of data.
wirelessDiagnostics() {
echo "Collecting powermetric samples..." >> "$scriptLog"
wdutil -q diagnose +dhcp +wifi +eapol +dns -f "$tmpFolder/"
}

# This function collects all Microsoft apps logs
microsoftLogCapture() {
echo "Collecting Microsoft Software Logs..." >> "$scriptLog"
if [ -d "$microsoftLogs" ]; then
    /bin/cp -Rp "$microsoftLogs" "$tmpFolder/Microsoft/"
fi
}

# As the name implies, this function will clean up all temp files and directories
# created by this script. This is done for security and privacy reasons.
CleanUp() {
    ## Cleanup
    echo "Cleaning up..." | tee -a "$scriptLog"
    rm -R /private/var/tmp/"$zipFileName" "$tmpFolder"
}

#
# Begin script

# Checking if Jamf Pro Tenant is reachable before proceeding...
httpResponseCode=$(curl --write-out '%{http_code}' --silent --output /dev/null -k -u "$jamfProUser":"$jamfProPass" "$jamfProURL/JSSResource/activationcode" )

if [ "$httpResponseCode" == "200" ]; then
    echo "Response Code: $httpResponseCode, MobileNow MDM Tenant found. Continuing..." | tee -a "$scriptLog"
else
    echo "Responde Code: $httpResponseCode, error connecting to MobileNow MDM Tenant. Exiting..." | tee -a "$scriptLog"
    exit 1
fi

# Create temporary folder structure to collect data

echo "Creating Temporary Folder Structure"
/bin/mkdir -p "$tmpFolder"

echo "Creating Collector log file"
/usr/bin/touch "$scriptLog"

echo "Creating Logs folder"
/bin/mkdir -p "$tmpFolder/Logs"

echo "Creating Microsoft logs folder"
/bin/mkdir -p "$tmpFolder/Microsoft"


# Enterprise Data Capture Log Header
echo "------------------------MobileNow Enterprise Data Capture-----------------------" >> "$scriptLog"
echo "--------------------------------------------------------------------------------" >> "$scriptLog"
printf "\n" >> "$scriptLog"

echo "-----------------------------------Preflight------------------------------------" >> "$scriptLog"
printf "\n" >> "$scriptLog"

echo "---------------------------------Client Capture---------------------------------" >> "$scriptLog"
echo "Current User: $currentUser" >> "$scriptLog"
echo "Hostname: $compHostName" >> "$scriptLog"
echo "Operating System: $sw_name $sw_vers" >> "$scriptLog"
echo "Computer Serial: $mySerial" >> "$scriptLog"
printf "\n" >> "$scriptLog"

# Call function to collect system profiler information
echo "Capturing System Profiler information"
systemProfilerCapture

# Call function to collect
echo "Collecting log files"
logCapture

# Call function to collect commands output
echo "Collecting commands output"
commandsCapture

# Call function to collect fs_usage information
echo "Collecting fs usage output"
fsUsageCapture

# Call function to collect Spindump information
echo "Capturing spindump sample"
spinDumpCapture

# Call function to collect Microsoft software logs
echo "Collecting Microsoft Logs"
microsoftLogCapture

# Call function to collect performance metric samples
echo "Collecting performance metrics samples"
powermetricsCapture

# Call function to perform and collect wifi diagnotics
# BEWARE: This function collects about 700MBs of information and makes it
#echo "Collection WiFi diagnostics information
#wirelessDiagnostics

echo "-----------------------------------Uploading------------------------------------" >> "$scriptLog"
printf "\n" >> "$scriptLog"


# Zip collected files and upload to MDM Tenant
echo "Zipping collected files" | tee -a "$scriptLog"
zip -vr /private/var/tmp/"$zipFileName" "$tmpFolder"

## Get user JAMF ID from MDM
if [[ "$osMajor" -eq 11 ]]; then
    jamfProID=$(curl -k -u "$jamfProUser":"$jamfProPass" "$jamfProURL/JSSResource/computers/serialnumber/$mySerial/subset/general" | xpath -e "//computer/general/id/text()" )
elif [[ "$osMajor" -eq 10 && "$osMinor" -gt 12 ]]; then
    jamfProID=$(curl -k -u "$jamfProUser":"$jamfProPass" "$jamfProURL/JSSResource/computers/serialnumber/$mySerial/subset/general" | xpath "//computer/general/id/text()" )
fi

echo "Jamf Computer ID is $jamfProID" | tee -a "$scriptLog"

## Upload zip file to MDM Console
echo "Uploading zip file to tenant $jamfProURL"
httpResponseCode=$(curl --write-out '%{http_code}' --silent --output /dev/null -k -u "$jamfProUser":"$jamfProPass" "$jamfProURL/JSSResource/fileuploads/computers/id/$jamfProID" -F "name=@/private/var/tmp/$zipFileName" -X POST)

echo "$httpResponseCode"

if [ "$httpResponseCode" == "200" ] || [ "$httpResponseCode" == "204" ]; then
    #DisplaySuccessDialogAndExit
    echo "Log files were uploaded successfully." | tee -a "$scriptLog"
    CleanUp
else
    #DisplayUnknownErrorDialog
    echo "Error uploading log files." | tee -a "$scriptLog"
    exit 1
fi

## Exit
echo "Exiting gracefully..." | tee -a "$scriptLog"
exit 0
