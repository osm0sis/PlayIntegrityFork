#!/system/bin/sh

# Written by Vagelis1608 @xda
# For PIFork by osm0sis @xda

# Set advanced settings in PIFork

# On error, exits with code:
# Not running as root: 1
# custom.pif.{prop|json} not found: 2
# Unknown PIF module: 3

# Main "global" variables
interactive=1
changed=0
ModuleDir="/data/adb/modules/playintegrityfix/" # Fallback
knownSettings=( spoofBuild,bool,1 \
				spoofProps,bool,1 \
				spoofProvider,bool,1 \
				spoofSignature,bool,0 \
				spoofVendingFinger,str,0 \
				spoofVendingSdk,int,0 \
				verboseLogs,int,0 ) # Name,type,default

function usage() {
	echo "Simple script to change the advanced settings in PIFork."
	echo "Root required!"
	echo ""
	echo "./${0##*\/} [-h] [-f] [-r] [-l] [setting[=value]]"
	echo "    -h|--help: Prints this help message and exits"
	echo "    -f|--force: ignore type checks of the setting to set, set it anyway"
	echo "    -r|--reset: Reset all settings to their default."
	echo "    -l|--list: List all current values and exit."
	echo "    Providing a Setting name without setting a value ( no = ) will take you to the interactive value selection."
	echo "    Empty value ( setting= ) resets the default value"
	echo "    Running without providing a setting triggers interactive mode, allowing you to select the setting you want from a list."
	printNames
}

function printNames() {
	echo ""
	echo "A script by Vagelis1608 @xda for PIFork by osm0sis @xda"
}

function errOut() { # <error code> <printed error>
	errCode="$1"
	shift

	echo "ERROR!"
	echo -e "$@"
	echo ""
	usage
	exit "$errCode"
}

function getSetting() { # setting
	if [[ "$mainFile" == *".prop" ]]; then
		echo $( grep "$1" "$mainFile" | cut -d= -f2 )
	else
		echo $( grep "$1" "$mainFile" | cut -d: -f2 | tr -d ' ",' )
	fi
}

function setSetting() { # setting value( empty for default )
	good=0
	for i in ${!knownSettings[@]}; do
		if [[ -n $( grep "$1" <<< "${knownSettings[$i]}" ) ]]; then good=1; break; fi
	done

	if [[ "$good" -ne 1 ]]; then
		echo "Warning: ignoring unknown setting: $1"
		echo ""
		return
	fi

	# PIFork is the only officially supported PIF module
	if [[ -z "$( grep 'osm0sis' ${mainFile%\/*}/module.prop )" ]]; then
		echo "Warning: Unknown PIF module found!"
		echo "PIFork by osm0sis is the only officially supported one."
		if [[ "$forceSet" -ne 1 ]]; then
			errOut 3 "You can use force mode (-f|--force) to write anyway.\nHowever, its extremely likely to break something."
		fi
	fi

	if [[ "$forceSet" -ne 1 && -n "$2" ]]; then # Force mode / type check
		if [[ "$( cut -d, -f2 <<< ${knownSettings[$i]} )" == "bool" && \
				-z "$( grep -x '^[0-1]$' <<< $2 )" ]]; then
			echo "$1 only accepts 0 or 1. Skipping..."
			echo ""
			return
		elif [[ "$( cut -d, -f2 <<< ${knownSettings[$i]} )" == "int" && \
				-z "$( grep -x -e '.[0-9]$' -e '^[0-9]$' <<< $2 )" ]]; then
			echo "$1 only accepts intergers. Skipping..."
			echo ""
			return
		fi
	fi

	if [[ -n "$2" ]]; then value="$2"
	else value="$( cut -d, -f3 <<< ${knownSettings[$i]} )"; fi

	echo "Setting $1 from $( getSetting $1 ) to $value in $mainFile"
	if [[ "$mainFile" == *".prop" ]]; then
		sed -i.old "/$1/s!=.*!=$value!g" "$mainFile"
	else
		sed -i.old "/$1/s!: \".*\"!: \"$value\"!g" "$mainFile"
	fi

	changed=1
}

# Root check
if [[ "$( whoami )" != "root" ]]; then errOut 1 "Must be run as root!"; fi

# Find custom.pif.{prop|json}
mainFile=""
for extension in prop json; do
	if [[ -e "${0%\/*}/custom.pif.${extension}" ]]; then
		mainFile="${0%\/*}/custom.pif.${extension}"
		break
	elif [[ -e "./custom.pif.${extension}" ]]; then
        mainFile="./custom.pif.${extension}"
        break
	elif [[ -e "${ModuleDir}/custom.pif.${extension}" ]]; then
        mainFile="${ModuleDir}/custom.pif.${extension}"
        break
	fi
done
if [[ -z "$mainFile" ]]; then errOut 2 "custom.pif.prop or .json not found!\nIs PIFork installed?"; fi

# Use migrate.sh -f -a to add missing advanced settings
for opt in ${knownSettings[@]}; do
	if [[ -z $( grep "$( cut -d, -f1 <<< $opt )" "$mainFile" ) ]]; then
		echo "One or more advanced options missing from $mainFile."
		echo "Executing migrate.sh -f -a to add them."
		sh "${mainFile%\/*}/migrate.sh" -f -a
		break
	fi
done

# Look for new/undefined Advanced Settings
if [[ -e "${mainFile%\/*}/example.pif.prop" ]]; then
	examplePif="${mainFile%\/*}/example.pif.prop"

	ePS=( $( tail -n $(( $( wc -l < "$examplePif" ) - \
				$( grep -n -m 1 'Advanced Settings' "$examplePif" | cut -d: -f1 ) )) \
				"$examplePif" ) )

	for opttest in ${ePS[@]}; do
		if [[ -z $( grep "$( cut -d= -f1 <<< $opttest )" <<< "${knownSettings[@]}" ) ]]; then
			knownSettings+=( "$( cut -d= -f1 <<< $opttest )"',unk,'"$( cut -d= -f2 <<< $opttest )" )
		fi
	done
elif [[ -e "${mainFile%\/*}/example.pif.json" ]]; then
	examplePif="${mainFile%\/*}/example.pif.json"

	ePS=( $( tail -n $(( $( wc -l < "$examplePif" ) - \
				$( grep -n -m 1 'Advanced Settings' "$examplePif" | cut -d: -f1 ) )) \
				"$examplePif" | cut -d: -f1 | tr -d ',\"\t ' ) )

	for opttest in ${ePS[@]}; do
		if [[ -z $( grep "$opttest" <<< "${knownSettings[@]}" ) ]]; then
			knownSettings+=( "$opttest"',unk,'$( grep $opttest $examplePif | \
									cut -d: -f2 | tr -d ',\"\t ' ) )
		fi
	done
fi

# Flag Handling
selection=()
while [[ -n "$1" ]]; do
	case "$1" in
		-h|--help)  usage; exit 0;;
		-f|--force) forceSet=1; shift;;
		-r|--reset)
			interactive=0
			for opt in ${knownSettings[@]}; do
				setSetting "$( cut -d, -f1 <<< $opt )"
			done
			shift;;
		-l|--list)
			for i in ${!knownSettings[@]}; do
				printSet="$( cut -d, -f1 <<< ${knownSettings[$i]} )"
				echo "$printSet"': '"$( getSetting $printSet )"
			done
			printNames
			exit 0;;
		'-'*) echo "Warning: Ignoring unknown flag: $1"; shift;;
		*'='*)
			interactive=0
			setSetting "${1%=*}" "${1#*=}"
			shift;;
		*)  selection+=( "$1" ); shift;;
	esac
done

if [[ "$interactive" -eq 1 ]]; then

if [[ $forceSet -eq 1 ]]; then echo "Force mode enabled."; fi

# Interactive Setting Selection
if [[ ${#selection[@]} -eq 0 ]]; then
	entered=""
	echo "Available advanced settings:"
	for i in ${!knownSettings[@]}; do
		printSet="$( cut -d, -f1 <<< ${knownSettings[$i]} )"
		echo "${i}"': '"$printSet"' ( current value: '"$( getSetting $printSet ) )"
	done
	echo "r: Reset all Advanced Settings to default values."
	echo "e: Exit script."
	echo ""

	while [[ -z "$entered" ]]; do
		echo -n 'Enter your selection [0-'"$i"', e, r]: '
		read entered

		# Reset mode
		if [[ -n $( grep -ix -e 'r' -e 'reset' <<< "$entered" ) ]]; then
			echo -ne "All advanced settings will be reset to their default values.\nAre you sure?(y/n) "
			read confirmReset
			if [[ -n $( grep -ix -e 'y' -e 'yes' <<< "$confirmReset" ) ]]; then
				for opt in ${knownSettings[@]}; do
                	setSetting "$( cut -d, -f1 <<< $opt )"
	            done
				echo "Done!"
			fi
			entered="e"
		fi

		# Exit
		if [[ -n $( grep -ix -e 'e' -e 'exit' <<< "$entered" ) ]]; then
			echo "Exiting..."
			entered="e"
			break
		fi

		if [[ -z $( grep -x -e '.[0-9]$' -e '^[0-9]$' <<< "$entered" ) || \
					$entered -lt 0 || $entered -gt $i ]]; then
			echo 'Invalid input, must be within [0-'"$i"', e, r]'
			echo ""
			entered=""
		fi
	done

	if [[ "$entered" != "e" ]]; then
		selection+=( "$( cut -d, -f1 <<< ${knownSettings[$entered]} )" )
	fi
fi

# Interactive Value Selection
for option in ${selection[@]}; do
	echo "$option selected ( current value: $( getSetting $option ), default: $( cut -d, -f3 <<< ${knownSettings[$entered]} ) )"
	echo -n "Enter new value ( empty to reset to default ): "
	read inputValue
	setSetting "$option" "$inputValue"
done

fi # Interactive mode

if [[ $changed -eq 1 ]]; then
	echo "Executing killpi.sh to apply changes"
	sh "${mainFile%\/*}/killpi.sh"
fi

printNames
