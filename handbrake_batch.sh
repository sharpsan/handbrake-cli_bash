#!/bin/bash
# small script for batch processing a folder of files using handbrake-cli
# for official documentation on handbrake-cli https://handbrake.fr/docs/

#variables
IFE=mkv     #Input File Extension
ONA=_[x265] #Output Name Addition
OFE=.mkv    #Output File Extension
PIF=/your_location/exported_handbrake_profiles.json #Preset Import File
PIN=Specific_Profile_Name #Preset Import Name

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
echo "*"

read -p "* press y to continue, any other key to abort " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "*"
    echo -e "* ${red}aborted${endcolor}"
    echo "*"
    exit
fi

#here we go
#loop
for i in *.$IFE; do
    SFN=${i%%.*} #strip the extension off the file being processed
    HandBrakeCLI --preset-import-file $PIF -Z "$PIN" -i $i -o $SFN$ONA$OFE
done

#exit
exit
