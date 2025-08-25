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
sampleInterval="30"                                           # Interval for taking samples in seconds
runningTime="1"                                               # Total running time in hours
workingDirectory="/Library/Mobidelio/Powermetrics/telemetry"  # Directory where script saves powermetrics results

sampler="tasks"                                               # tasks,battery,network,disk,int_sources,devices,interrupts,cpu_power,thermal,sfi,gpu_power,gpu_agpm_stats,smc,nvme_ssd,io_throttle_ssd
bufferSize="1"                                                # 0=None | 1=Line
sampleInterval="0"                                            # 0=disabled | default=5000ms
sampleCount="1"                                               # 0=infinite
powerAverage="1"                                              # Display poweravg every N samples (0=disabled) [default: 10]


#
# Begin Script

# Convert duration from hours to seconds
durationSeconds=$((runningTime * 3600))

# Capture the start time in seconds since epoch
startTime=$(date +%s)

# Calculate the end time
cutOffTime=$((startTime + durationSeconds))



# Check if the working directory already exists
if [ -d "$workingDirectory" ]; then
    # Already created
    echo "$(date) | Log directory already exists - $workingDirectory"
else
    # Creating Working directory
    echo "$(date) | creating log directory - $workingDirectory"
    mkdir -p "$workingDirectory"
fi

# Run powermetrics
while [ "$(date +%s)" -lt "$cutOffTime" ]; do
        /usr/bin/powermetrics -b "$bufferSize" -n "$sampleCount" -s "$sampler" --show-process-energy --show-process-io | sed -l "s/^/$(date +%Y-%m-%dT%H:%M:%S" "%Z) /" >> "$workingDirectory/$(date +%y-%m-%d-powermetrics.log)"
        sleep "$sampleInterval"
done

# Unload LaunchDaemon


exit 0
