launch_or_switchto_chrome() {
	if wmctrl -lx | grep -q "google-chrome"; then
		wmctrl -xa "google-chrome"
		sleep 0.3
	else 
		#google-chrome
		
		# Start Chrome in background
		google-chrome --new-window &
		
		# Wait for a window with "Google Chrome" in the title appear
		until wmctrl -l | grep "Google Chrome" > /dev/null; do
			sleep 0.3
		done
		
		echo "Google Chrome window is available."
	fi
}

## Wait for the save dialog of Chrome browser to appear
wait_for_save_dialog() {
	WIN_TITLE="Save File"
	START_SEC=1
	TIMEOUT_SEC=600
	SLEEP_INTERVAL=2
	
	until (( START_SEC >= TIMEOUT_SEC )); do
		if xdotool search --onlyvisible --name --class "$WIN_TITLE" > /dev/null; then
			echo "The $WIN_TITLE dialog appeared"
			return 0
		fi
		
		echo "$WIN_TITLE dialog not shown yet, waiting... (elapsed: $START_SEC/$TIMEOUT_SEC)"
		sleep $SLEEP_INTERVAL
	done
	
	echo "ERROR: Timed out after $START_SEC seconds waiting for the $WIN_TITLE dialog." >&2
	exit 1
}

## Work only in Google Chrome
wait_for_page_loaded() {
	if [ -z "$1" ]; then
		echo "Error: No URL parameter provided"
		return 1
	fi
	
	URL="$1"
	FILENAME=$(echo $URL | sed -E "s/.*\/([a-zA-Z0-9_\-]+\.mp3)/\1/")
	echo "wait_for_page_loaded(): FILENAME=$FILENAME"
	
	while wmctrl -l | grep "$FILENAME - Google Chrome" > /dev/null; do
		sleep 0.5
	done
	sleep 2
}

download_audio() {
	if [ -z "$1" ]; then
		echo "Error: No URL parameter provided"
		return 1
	fi
	
	URL="$1"
	echo "Processing URL: $URL"
	
	# Set focus to browser's address bar
	xdotool key ctrl+l	
	sleep 0.3	# This prevents the below commands to run before the applications are ready
	
	# Enter the URL
	xdotool type "$URL"
	sleep 0.3
	xdotool key Return 
	#sleep 10 # Wait for the page to completely load
	wait_for_page_loaded $URL
	
	xdotool key ctrl+s	# Open the Download dialog
	wait_for_save_dialog

	xdotool key Return	# Click on the Save button in the Download dialog
	sleep 0.3
}

## Wait until a specified file exists or has been downloaded
wait_until_exists() {
	if [ -z "$1" ]; then
		echo "Error: No URL parameter provided"
		return 1
	fi
	
	FILE="$1"
	echo "Waiting for file to exists: $FILE"
	
	ELAPSED=0
	TIMEOUT_SEC=120 # sec
	SLEEP_INTERVAL=1
	
	while [[ ! -e "$FILE" ]] && (( ELAPSED < TIMEOUT_SEC )); do
		echo "File $FILE not found yet, waiting... (elapsed: $ELAPSED/$TIMEOUT sec)"
		sleep $SLEEP_INTERVAL
		ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
	done
	
	if [[ -e "$FILE" ]]; then
		echo "SUCCESS! File $FILE found after $ELAPSED seconds"
	else
		echo "FAILED! File $FILE not found after waiting" >$2
		exit
	fi
}

## The options specified when running the script must be passed as the last paramter of this function
## because they can't be found by the getopts command when it gets called within another function,
## not directly within the script itself.
## To call this funciton, for example, assign_opts "FROM_IDX" "TO_IDX" "$@". The "$@" is the options (e.g. -f and -t).
assign_opts() { 
	local -n REF_FROM="$1" 		# Create a reference to the global variable named "FROM_IDX"
	local -n REF_TO="$2"		# Create a reference to the global variable named "TO_IDX"
	local -n REF_FILENAME="$3"	# Create a reference to the global variable named "FILENAME"
	echo "assign_opts() called: REF_FROM=$1, REF_TO=$2, REF_FILENAME=$3"
		
	## The first 3 parameters passed to this function are just the names of global variables
	## (declared in the main script) which are used to create references to them,
	## and then assign values to them.
	## The getopts command will read the options passed from Terminal through the main script,
	## for example, -f 1 -t 30 -d bon_031b.mp3, not the names of the global variables.
	shift 3

	## Get the values of -f and -t options
	## "$@" tells getopts command to read from this function's parameters
	## instead of the options specified when running the script
	## because those options can't be found 
	## when calling getopts command from within a function, not directly in the script.
	while getopts "f:t:d:" opt "$@"; do 	
		case $opt in
			f) 
				REF_FROM="$OPTARG"
				;;
			t) 
				REF_TO="$OPTARG"
				;;
			d)
				REF_FILENAME="$OPTARG"
				;;
			\?) 
				echo "Invalid option: -$OPTARG" >&2
				exit 1
				;;
			:)
				echo "Option -$OPTARG requires an argument." >&2
				exit 1
				;;
		esac
			
	done

	if [[ -z "$REF_FROM" || -z "$REF_TO" || -z "$REF_FILENAME" ]]; then
		echo "Usage: $0 -f <start-number> -t <end-number> -d <downloading-filename>"
		echo "Example: $0 -f 11 -t 30 -d 'bon_028a.mp3'"
		exit 1
	fi
}


