# handbrake-cli_bash
simple bash script to streamline batch processing of files using handbrake-cli

after fussing with this for some time, i've got my setup streamlined, and i'm seeing ~90% overall CPU saturation on my server, so i'm 
pretty satisfied with the efficiency. 


i wasn't able to find many answers for what i wanted to do, so i figured i'd write up a guide to help anyone else out there who 
is looking to do the same thing. i'm sure there are better methods, but at least this might be a useful starting point for you :)


assumptions :

1. you're running proxmox, and have a computer with +6 CPUs, and trying to use handbrake to do some batch encoding. this 6 CPU "limit" is where handbrake advises their program efficiency begins to decline https://handbrake.fr/docs/en/1.0.0/technical/video-encoding-performance.html

2. you have your files on a different machine than you'll be doing the encoding from. i suppose they could all be the same physical machine, but part of this guide will be about getting the shares mounted, and symlinking the profiles, so ignore what isn't applicable for you. 

3. you have already got some profiles set up in handbrake, that you'd like to be able to apply to convert batches of files, without having to tinker with the settings and make sure that all your settings actually stay in place. i've found the "add to queue" function in the GUI version of handbrake often fails to preserve my audio settings, and it's tedious to have to add each file manually to the queue. 

4. this guide is written having used default template of ubuntu 22.04 for the containers. 



the setup :

  1.0 proxmox containers

  1.1 proxmox considers threads as "CPU"s, so base your resource CPU count on available threads

  1.2 handbrake-cli doesn't need much memory; my containers have 3GB each and rarely get close to 50% usage

  1.3 containers must be privileged

  1.4 containers must have the "feature" of *nesting=1* enabled (this must be enabled after creation, under "options")

  1.5 do your math to figure out how many containers you will make, to provide 8-10 CPUs per container, *but only make the first one*.

 
 
  2.0 updating and software for containers

  2.1 assuming you'll using the `console` function from proxmox to get a terminal into your first container, you'll be logged in as 
      root by default. start by running `apt update && apt upgrade -y` to get your packages current.

  2.2 if you want to be remoting in to control the encoding, you should probably add a non-root user. you can do with with 
      `adduser username` where *username* is your desired username. you'll be prompted for password.

  2.3 enable ssh and make the firewall allowances with `systemctl enable ssh && ufw allow ssh`

  2.4 now install handbrake-cli with `apt install handbrake-cli -y`. yes, i am aware that handbrake declares the apt version of handbrake as non-compliant and wants you to compile it yourself... i'm too lazy... https://handbrake.fr/docs/en/1.2.0/get-handbrake/download-and-install.html

  2.5 make a folder for your smb share mount point, for example, `/mnt/media`

  2.6 close the terminal, and shut down the container in proxmox

  2.7 replicate the container as needed for your total count
  


  3.0 mapping your network-accessible media files

  3.1 open a terminal on your proxmox host, and navigate to `/etc/pve/nodes/<hostname>/lxc/`

  3.2 each of your LXC has a configuration file, edit them and between the line that begins with "memory" and the line that begins with "net 0" you need to add a new line of text, `mp0: <path to hosted SMB share>,mp=<path to SMB mount point on container>` write the changes to the .conf file and close it. when you restart your LXC the share will be mounted. 



  4.0 profiles and bash script

  4.1 make sure your handbrake *Preset* is configured correctly (i had trouble with the audio and subtitle options, which need to be set using the "Selection Behavior" buttons within the "Manage Presets" screen) and export the file to where it will be accessible on your SMB share. 

  4.2 i uploaded the bash script here : https://github.com/imaginarycheetah/handbrake-cli_bash either download it or copy the text and paste it into a new .sh file, it needs to be saved where it will be accessible on your SMB share. be sure to `chmod +x <file.sh>` so that it can execute.

  4.3 open a terminal for each LXC and make a symlink to the handbrake-batch.sh file `ln -s /<mounted SMB share>/bash.sh /bin/handbrake-batch`pay attention to the omission of the .sh file extension on the created symlink. this allows the script to be invoked as you would a normal program. 



  5.0 script variables to modify (only make modifications to the actual bash.sh script, not the symlinks)

  5.1 IFE is for the extension of the files *to be processed*

  5.2 ONA is the text that will be appended to the end of the processed file names

  5.3 OFE is the file extension of the output files, this may actually be ignored by handbrake, i'm not sure

  5.4 PIF is the *full path* to the exported JSON file from handbrake

  5.5 PIN is the name of the profile to be used from the JSON file



application :

1. all this work is to leverage the *aggregate* processing power of your server onto a bunch of files. so split up your files into a few 
   sub-folders, probably one folder per LXC. 

2. start your LXC, open a terminal, navigate to the appropriate sub-folder where your files are

3. type name of the bash file, for example `handbrake-batch`

4. you should be prompted with a screen that confirms the values of the variables, and prompts you to press the 'y' key to being processing

5. repeat for all of your LXCs
