#!/bin/bash

#########################################################################################################
# License Information
#
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

# Code by Professional Services, Mobidelio
# Created: 
# Changelog: 
# Support: macOS 13.x and later

# Usage: Script
# Description: Script to rename a Mac based on Model,serial and processor type

# Get the full hardware model name (e.g., "MacBook Air", "MacBook Pro", etc.)
mac_model=$(system_profiler SPHardwareDataType | awk -F': ' '/Model Name/ {print $2}')

# Determine Mac type abbreviation
case "$mac_model" in
  "MacBook Air")
    mac_type="MB"
    ;;
  "MacBook Pro")
    mac_type="MB"
    ;;
  "MacBook")
    mac_type="MB"
    ;;
  "iMac")
    mac_type="IM"
    ;;
  "Mac mini")
    mac_type="MM"
    ;;
  "Mac Studio")
    mac_type="MS"
    ;;
  "Mac Pro")
    mac_type="MP"
    ;;
  *)
    mac_type="XX"  # Fallback for unknown types
    ;;
esac

# Get processor string
cpu_brand=$(sysctl -n machdep.cpu.brand_string)

# Determine Apple Silicon or Intel
if [[ "$cpu_brand" == *"M1"* ]]; then
  processor="M1"
elif [[ "$cpu_brand" == *"M2"* ]]; then
  processor="M2"
elif [[ "$cpu_brand" == *"M3"* ]]; then
  processor="M3"
else
  processor="INTEL"
fi

# Get Serial Number
serial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $NF}')

# Construct the final device name
device_name="L${mac_type}${processor}${serial}"

echo "$device_name"
