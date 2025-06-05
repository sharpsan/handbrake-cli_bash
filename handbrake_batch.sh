#!/bin/bash
# small script for batch processing a folder of files using handbrake-cli
# for official documentation on handbrake-cli https://handbrake.fr/docs/

#variables
IFE=mkv     #Input File Extension
ONA="_[x265]" #Output Name Addition
OFE=.mkv    #Output File Extension
PIF=/your_location/exported_handbrake_profiles.json #Preset Import File
PIN="Specific Profile Name " #Preset Import Name

red="\e[31m"      #color text
green="\e[32m"    #color text
endcolor="\e[0m"  #end color

#sanity check
#confirm handbrake works in this location
if ! command -v HandBrakeCLI &> /dev/null 
then
    echo "*"
    echo -e "* ${red}abort:${endcolor} HandBrakeCLI could not be found"
    echo "*"
    exit
fi

#sanity check
#confirm exported template .json file exists in expected location
if [[ ! -f $PIF ]] ;
then
    echo "*"
    echo -e "* ${red}abort:${endcolor} $PIF could not be found"
    echo "*"
    exit
fi

#sanity check
#chance to abort
clear
echo "*"
echo -e "* loop will process all files in this folder with ${green}.$IFE${endcolor} file extension."
echo -e "* handbrake profile named "${green}$PIN${endcolor}", from ${green}$PIF${endcolor}."
echo -e "* processed files will have \"${green}$ONA${endcolor}\" appended to their name."
echo -e "* processed files will have ${green}.$OFE${endcolor} file extension."
echo -e "*"
echo -e "* usage: ${green}$0 [-recursive] [-dryrun]${endcolor}"
echo -e "*   -recursive : process files in all subdirectories recursively"
echo -e "*   -dryrun    : show what would be processed, but do not run HandBrakeCLI"
echo -e "*"
echo -e "* switch status:"
echo -e "*   RECURSIVE: $( [ "$RECURSIVE" = true ] && echo "${green}active${endcolor}" || echo "${red}inactive${endcolor}" )"
echo -e "*   DRYRUN:    $( [ "$DRYRUN" = true ] && echo "${green}active${endcolor}" || echo "${red}inactive${endcolor}" )"
echo "*"

read -p "* press y to continue, any other key to abort " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "*"
    echo -e "* ${red}aborted${endcolor}"
    echo "*"
    exit
fi

# check for switches
RECURSIVE=false
DRYRUN=false
for arg in "$@"; do
    if [[ "$arg" == "-recursive" ]]; then
        RECURSIVE=true
    elif [[ "$arg" == "-dryrun" ]]; then
        DRYRUN=true
    fi
done

LOGFILE="handbrake_batch_processed.log"
: > "$LOGFILE"  # Truncate log file at start

#here we go
#loop
if [ "$RECURSIVE" = true ]; then
    # Recursively find files with the specified extension
    find . -type f -name "*.$IFE" | sort | while read -r i; do
        DIRNAME=$(dirname "$i")
        BASENAME=$(basename "$i")
        SFN="${BASENAME%.*}" # strip the extension
        OUTPUT="$DIRNAME/$SFN$ONA$OFE"
        if [ "$DRYRUN" = true ]; then
            echo "[DRYRUN] Would process: $i -> $OUTPUT"
        else
            HandBrakeCLI --preset-import-file "$PIF" -Z "$PIN" -i "$i" -o "$OUTPUT"
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') | INPUT: $i | OUTPUT: $OUTPUT" >> "$LOGFILE"
    done
else
    for i in *.$IFE; do
        [ -e "$i" ] || continue
        SFN="${i%.*}" #strip the extension off the file being processed
        OUTPUT="$SFN$ONA$OFE"
        if [ "$DRYRUN" = true ]; then
            echo "[DRYRUN] Would process: $i -> $OUTPUT"
        else
            HandBrakeCLI --preset-import-file "$PIF" -Z "$PIN" -i "$i" -o "$OUTPUT"
        fi
        echo "$(date '+%Y-%m-%d %H:%M:%S') | INPUT: $i | OUTPUT: $OUTPUT" >> "$LOGFILE"
    done
fi

# Logging summary
mapfile -t PROCESSED_FILES < <(awk -F'OUTPUT: ' '{print $2}' "$LOGFILE")

echo "*"
if [ "$DRYRUN" = true ]; then
    echo -e "* ${green}Dry run complete. No files were actually processed.${endcolor}"
else
    echo -e "* ${green}Processing complete.${endcolor}"
fi
echo -e "* Files processed: ${green}${#PROCESSED_FILES[@]}${endcolor}"
if [ "${#PROCESSED_FILES[@]}" -gt 0 ]; then
    echo -e "* Output files (also saved to ${green}$LOGFILE${endcolor}):"
    for f in "${PROCESSED_FILES[@]}"; do
        echo -e "*   ${green}$f${endcolor}"
    done
    echo -e "*"
    echo -e "* Log entries include date/time, original input, and output file."
else
    echo -e "* ${red}No files were processed.${endcolor}"
fi

#exit
exit
