#!/bin/bash

# --------------------------------
# xcode-plugin-updater.sh
# The MIT License (MIT)
#
# Copyright (c) 2015 DynamicDust s.r.o.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --------------------------------
# CONSTANTS
# --------------------------------

PLIST="/usr/libexec/PlistBuddy"

# Xcode constants
X_APP_DIR_GLOBAL="/Applications"
X_APP_DIR_USER="${HOME}/Applications"
X_APP_FILE_BASE_NAME="Xcode*.app"
X_UUID_REGEX="[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
X_UUID_PLIST_KEY="DVTPlugInCompatibilityUUID"

# Plugin constants
P_PLUGIN_DIR="${HOME}/Library/Application Support/Developer/Shared/Xcode/Plug-ins"
P_UUID_PLIST_KEY="DVTPlugInCompatibilityUUIDs"

# Colors
COLOREND=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)	
UNDER=$(tput smul)
BOLD=$(tput bold)

# --------------------------------
# VARIABLES
# --------------------------------

XCODE_UUID=""

# --------------------------------
# FUNCTIONS
# --------------------------------

function start
{
	echo ""
	echo "${BOLD}${UNDER}${GREEN}xcode-plugin-updater.sh${COLOREND}"
}

function end
{
	echo ""
	echo "${BOLD}Done, all plugins updated.${COLOREND}"
}

# --------------------------------

function usage
{
	echo "usage: xcode-plugin-updater.sh [-u UUID] [help] [print]"
}

# --------------------------------

function dependencyIsMissing
{
	if [[ $# == 1 ]]; then
		echo "Dependency (${1}) is missing. Please install it - preferably into /usr/bin."
	fi
	exit 1
}

# --------------------------------

function validateUUID
{
	# Ignore case
	shopt -s nocasematch;

	if ! [[ "$XCODE_UUID" =~ ^${X_UUID_REGEX}$ ]]; then
		echo "Incorrect format of UUID. Please provide 128bit hex number in 8-4-4-4-12 format."
		exit 1
	fi
}

# --------------------------------

function updatePlugins
{
	validateUUID
	
	echo "${BOLD}Updating plugins...${COLOREND}"
	echo ""

	# Iterate through the plugins in the plugin folder
	while read -rd $'\0' plugin; do
	    
	    P_PLIST="${plugin}/Contents/Info.plist"
		if [[ ! -e ${P_PLIST} ]]; then
			echo "${RED}✗ [$(basename "${plugin}")]${COLOREND} Plugin update failed, corrupted or missing Info.plist file."
			continue
		fi

		P_UUID_ARRAY=$(${PLIST} -c "Print :${P_UUID_PLIST_KEY}:" "${P_PLIST}")

		if [[ $P_UUID_ARRAY == *"${XCODE_UUID}"* ]]; then
			echo "${GREEN}✓ [$(basename "${plugin}")]${COLOREND} Plugin already contains this UUID, no need to update."	
			continue;
		fi

		# Add the new UDID to the array
		${PLIST} -c "Add :${P_UUID_PLIST_KEY}: string ${XCODE_UUID}" "${P_PLIST}"

		# Done
		echo "${GREEN}✓ [$(basename "${plugin}")]${COLOREND} Plugin updated successfully."

	done < <(find "${P_PLUGIN_DIR}" -maxdepth 1 -name "*.xcplugin" -print0)
}

# --------------------------------

function getUUID
{
	# Check user and global application directory for Xcode (and Xcode-beta)
	X_VER_1=$(find ${X_APP_DIR_GLOBAL} -maxdepth 1 -name ${X_APP_FILE_BASE_NAME})
	X_VER_2=$(find ${X_APP_DIR_USER} -maxdepth 1 -name ${X_APP_FILE_BASE_NAME})

	if [[ $X_VER_1 == "" ]]; then 
		X_VER_1_COUNT=0
	else
		X_VER_1_COUNT=$(wc -l <<< "${X_VER_1}")
	fi

	if [[ $X_VER_2 == "" ]]; then 
		X_VER_2_COUNT=0
	else
		X_VER_2_COUNT=$(wc -l <<< "${X_VER_2}")
	fi

	# Number of versions in total
	X_VERSION_COUNT=$(($X_VER_1_COUNT+$X_VER_2_COUNT))

	if (( $X_VER_1_COUNT >= 1 && $X_VER_2_COUNT >= 1 )); then
		# IMPORTANT! 
		# New line is added in between both find results here
		X_VERSIONS="$X_VER_1
		$X_VER_2"
	elif (( $X_VER_1_COUNT >= 1 && $X_VER_2_COUNT == 0 )); then
		X_VERSIONS="${X_VER_1}"
	else
		X_VERSIONS="${X_VER_2}"
	fi

	# Final version which we will get the UUID from
	X_VERSION=""

	# If more than one version, prompt the user to choose
	# else get the UUID of the current version
	if (( $X_VERSION_COUNT > 1 )); then
		
		# Notify
		echo "Multiple versions of Xcode found. Which one do you want to use?"

		echo ""
		i=0

		# List all the options
		while read -rd $'\0' file; do
	    	echo "${BOLD}[$i]${COLOREND} $file"
	    	i=$((i+1))
		done < <(find ${X_APP_DIR_GLOBAL} ${X_APP_DIR_USER} -maxdepth 1 -name ${X_APP_FILE_BASE_NAME} -print0)

		i=$((i-1))
		echo ""

		# Ask the user which version he wants to use
		while true; do
		    read -p "Your choice: " choice
		    case $choice in
		        [0-$i]* ) break;;
		        * ) echo "Please answer in range 0 - $i."; echo;;
		    esac
		done

		# Resets
		i=0
		echo ""

		# Enumerate again and get the Xcode version chosen by user
		for ver in ${X_VERSIONS}; do
			if [[ $i == $choice ]]; then
				X_VERSION=$ver;
				break;
			fi
			i=$((i+1))
		done
	else

		# Get the first (and only) version
		for ver in ${X_VERSIONS}; do
			X_VERSION=$ver;
			break;
		done

	fi

	# Check if the Info.plist file exists
	X_PLIST="${X_VERSION}/Contents/Info.plist"
	if [[ ! -e ${X_PLIST} ]]; then
		echo "This Xcode version is corrupted and is missing the Info.plist file."
		exit 1
	fi

	# Now get the UUID from the version chosen
	XCODE_UUID=$(${PLIST} -c "Print ${X_UUID_PLIST_KEY}" "${X_PLIST}")
}

# --------------------------------

function printUUID
{
	start

	# Check if PlistBuddy is available
	command -v "$PLIST" > /dev/null || dependencyIsMissing "PlistBuddy"

	# Get the UUID
	getUUID

	# Copy to the clipboard
	echo "${XCODE_UUID}" | pbcopy

	# Print it
	echo "${BOLD}Xcode UUID:${COLOREND} ${XCODE_UUID}"
	echo "(copied to your clipboard)"
	echo ""
}

# --------------------------------
# MAIN
# --------------------------------

if [[ $# == 1 ]]; then

	# Handle just one argument
	if [[ "$1" == "help" ]]; then
		usage
		exit 0
	elif [[ "$1" == "print" ]]; then
		printUUID
		exit 0
	else
		echo "Unkown argument $1."
		usage
		exit 1;
	fi

elif [[ $# == 2 ]]; then
	start
	echo ""

	# Handle two arguments
	if [[ "$1" == "-u" ]]; then
		XCODE_UUID="${2}"
		updatePlugins
		end
		exit 0
	else
		echo "Unkown argument $1."
		usage
		exit 1;
	fi

else
	start
	echo ""

	# Check if PlistBuddy is available
	command -v "$PLIST" > /dev/null || dependencyIsMissing "PlistBuddy"

	# If no argument passed, then find all Xcode versions and get the UUID
	getUUID

	# If the UUID is ready, update the plugins
	updatePlugins

	end 

	exit 0
fi

# --------------------------------