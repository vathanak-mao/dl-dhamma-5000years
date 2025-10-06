
#######################################  README  ###########################################
##
## 1). 	Go to https://5000-years.org/kh and look for the category (e.g. Sampovmeas) to download
##		then note down the total number of audio files within that category.
## 2).	Download an audio file then note down its URL 
## 2). 	Copy the file name which should be at the end of the URL, 
##		then paste it as the value of -d option in the command below:
## 		
##		$ ./dl_dhama_akpithom.sh -f 1 -t 30 -d "bsv_027a.mp3"
## 			
##		- '-d': Downloading file name. It's used to construct the names of other audio files 
##				within the same folder/category as they are only different in their indices.
##
############################################################################################

source ./dl_dhamma_libs.sh

FROM_IDX=-1
TO_IDX=-1

## As the downloading audio files in the same category are only different in index numbers,
## this downloading filename allows this script 
## to construct the names of other audio files with from and to indices.
FILENAME=  # Downloading file name. This 

## The assign_opts() function is included from another script,
## and it calls the built-in getopts command to 
## read all options (e.g. -f and -t) passed from Terminal.
## However, the getopts command won't be able to find the options and will fail 
## when it's called from within another function, not directly from this script.
## The solution is to pass those options from Terminal as arguments to the assign_opts() function,
## then let the getopts command read the options from the function's parameters instead.
## 
## The first 3 arguments are the names of declared global variable above,
## which are required to create references to them inside the function,
## and then their values (options passed from Terminal) will be assigned using the references.
## This is an alternative to passing object by reference in Java.
assign_opts "FROM_IDX" "TO_IDX" "FILENAME" "$@"


while (( $FROM_IDX <= $TO_IDX )); do
	BASE_URL="https://5000-years.org/media"
	PADDING_NUM=$(printf "%03d" $FROM_IDX)
	echo "Padding number: $PADDING_NUM"
	
	## If the specified file name contains 'a' or 'b', it has two parts.
	if [[ $FILENAME =~ [0-9]+[ab] ]]; then
		echo "Filename: $FILENAME has two parts."
		
		NEW_FILENAME_PART1="$(echo $FILENAME | sed -E "s/(.+_)[0-9]+[ab]?(\.mp3)/\1${PADDING_NUM}a\2/")"
		NEW_FILENAME_PART2="$(echo $FILENAME | sed -E "s/(.+_)[0-9]+[ab]?(\.mp3)/\1${PADDING_NUM}b\2/")"
		
		## Download the first part
		launch_or_switchto_chrome
		download_audio "$BASE_URL/$NEW_FILENAME_PART1"
		wait_until_exists "$NEW_FILENAME_PART1"
		
		## Download the second part
		launch_or_switchto_chrome
		download_audio "$BASE_URL/$NEW_FILENAME_PART2"
		wait_until_exists "$NEW_FILENAME_PART2"
	else 
		echo "Filename: $FILENAME has only one part."
				
		NEW_FILENAME=$(echo $FILENAME | sed -E "s/(.+_)[0-9]+(\.mp3)/\1${PADDING_NUM}\2/")
		launch_or_switchto_chrome
		download_audio "$BASE_URL/$NEW_FILENAME"
		wait_until_exists "$NEW_FILENAME"
	fi
		
	((FROM_IDX++))
done





