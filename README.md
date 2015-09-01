# modarchive
Small Bash script to retrieve a play tunes from modarchive.org<br/>
This script is released under the terms of GNU GPL V3 License 

# Requirements
This script requires various tools to work.
* mikmod, opencp or audacious
* wget
* sed
* grep
* awk

# Configuration
This script uses mikmod to play tunes by default, but you can override this and other settings with a .modarchiverc file located in $HOME directory. This is an example of .modarchiverc file to use audacious instead mikmod.

```bash
#Where the song files will be downloaded
MODPATH='/home/user/Music/modarchive'

#The full path to player binary
PLAYER='/usr/bin/audacious'

#Player options. In this case, queue songs to audacious playlist
PLAYEROPTS='-e'

#If this is true, player will be run in background
PLAYERBG='true'
```

# Usage
Modarchive Jukebox can be used with one of the following options:
```
   -h : Show this help message

   -n <number>  Number of tracks to play
   -r           Shuffle playlist
   -p <player>  Select player profile: Supported players are: 
           mikmod     This is the default player. Runs in console and uses 
                      libmikmod to decode files  
           audacious  This is an X11 player. Uses modplug tu decode files
           opencp     This is Open Cubic Player, a console/x11 classic player. 
                      It's really buggy but, who cares?
         
   -s <section> Play from selected section: Can be one of this 
          uploads     This is a list of the recent member upload activity
          featured    These modules have been nominated by the crew for either 
                      outstanding quality, technique or creativity 
                      (or combination of).
          favourites  These modules have been nominated by the members via their
                      favourites. 
          downloads   The top 1000 most downloaded modules, recorded since circa
                      2002. 
          topscore    This chart lists the most revered modules on the archive.
          new         Same than uploads but using search engine
          random      Ramdom module from entire archive
   -a <artist>  Search in artist database
   -m <module>  Search in module database (Title and Filename)


Hint: Use + symbol instead blankspaces in search strings.
```
