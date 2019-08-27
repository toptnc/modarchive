#!/bin/bash


###############################################################################
#                        MODARCHIVE JUKEBOX SCRIPT
#	
#  Made by: Fernando Sancho AKA 'toptnc'
#  email: toptnc@gmail.com
#
#  This script plays mods from http://modarchive.org in random order
#  It can fetch files from various categories
#
#  This script is released under the terms of GNU GPL License 
#
###############################################################################

MODPATH='/tmp/modarchive'
SHUFFLE=
PLAYLISTFILE='modarchive.url'
RANDOMSONG=
PAGES=
MODLIST=
PL_AGE="3600"

PLAYER='/usr/bin/mikmod'
PLAYEROPTS='-i -X --surround --hqmixer -f 48000 -X'
PLAYERBG='false'

TRACKSNUM=0


#Configuration file overrides defaults
if [ -f $HOME/.modarchiverc ];
then
    source $HOME/.modarchiverc
fi

usage()
{
    cat << EOF
usage: $0 [options]

Modarchive Jukebox can be used with one of the following options:
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
          featured    These modules have been nominated by the crew for either 
                      outstanding quality, technique or creativity 
                      (or combination of).
          favourites  These modules have been nominated by the members via their
                      favourites. 
          downloads   The top 1000 most downloaded modules, recorded since circa
                      2002. 
          topscore    This chart lists the most revered modules on the archive.
          newadd      New additions by Date
	  newratings  Recent rated modules
          random      Ramdom module from entire archive
   -a <artist>  Search in artist database
   -m <module>  Search in module database (Title and Filename)


Hint: Use + symbol instead blankspaces in search strings.


EOF
}


create_playlist()
{
    PLAYLIST=""
    
    if [ ! -e "$MODPATH/$MODLIST" ] || [ "$(( $(date +"%s") - $(stat -c "%Y" "${MODPATH}/${MODLIST}") ))" -gt $PL_AGE ];
    then
	if [ ! -z $PAGES ];
	then
            PLAYLIST=$(curl -s "${MODURL}" | grep href | sed 's/href=/\n/g' | sed 's/>/\n/g' | grep downloads.php | sed 's/\"//g' | sed 's/'\''//g'|cut -d " " -f 1| uniq)
	else
	    PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
	    echo "Need to download ${PAGES} pages of results. This may take a while..."
            for (( PLPAGE = 1; PLPAGE <= PAGES; PLPAGE ++ ))
            do
		(( PERCENT = PLPAGE * 100 / PAGES ))
		echo -ne "${PERCENT}% completed\r"
		PLPAGEARG="&page=$PLPAGE";
		LIST=$(curl -s "${MODURL}${PLPAGEARG}"| grep href | sed 's/href=/\n/g' | sed 's/>/\n/g' | grep downloads.php | sed 's/\"//g' | sed 's/'\''//g'|cut -d " " -f 1| uniq )
		PLAYLIST=$(printf "${PLAYLIST}\n${LIST}")
            done
	fi
	echo ""
	echo "$PLAYLIST" | sed '/^$/d' > "$MODPATH/$MODLIST"
    fi     

    
    if [ -z $SHUFFLE ];
    then
        cat "$MODPATH/$MODLIST" > "$MODPATH/$PLAYLISTFILE"
    else
        cat "$MODPATH/$MODLIST" | awk 'BEGIN { srand() } { print rand() "\t" $0 }' | sort -n | cut -f2- > "$MODPATH/$PLAYLISTFILE"
    fi
}


while getopts "hrm:a:s:n:p:" OPTION
do
    case $OPTION in
	h)
	    usage
	    exit 0;
	    ;;   
	s)
            case $OPTARG in
		featured)
    		    MODURL="http://modarchive.org/index.php?request=view_chart&query=featured"
		    MODLIST="list.featured"
		    #PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
		    ;;		
		favourites)
		    MODURL="http://modarchive.org/index.php?request=view_top_favourites"
		    MODLIST="list.favourites"
		    #PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
		    ;;
		downloads)
		    MODURL="http://modarchive.org/index.php?request=view_chart&query=tophits"
		    MODLIST="list.downloads"
		    #PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
		    ;;
		topscore)
		    MODURL="http://modarchive.org/index.php?request=view_chart&query=topscore"
		    MODLIST="list.topscore"
		    #PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
		    ;;
		newadd)
                    MODURL="http://modarchive.org/index.php?request=view_actions_uploads"
		    MODLIST="list.newadd"
		    PAGES='0'
                    ;;
		newratings)
		    MODURL="http://modarchive.org/index.php?request=view_actions_ratings"
		    MODLIST="list.newratings"
		    PAGES='0'
		    ;;
		
		random)
		    RANDOMSONG="true"
		    MODURL="http://modarchive.org/index.php?request=view_random"
		    PAGES='0'
		    ;;
		?)
                usage
                exit 1
                ;;
            esac
            ;;
	
	a)
	    QUERY=$(echo ${OPTARG} | sed 's/\ /\+/g')
            QUERYURL="http://modarchive.org/index.php?query=$QUERY&submit=Find&request=search&search_type=search_artist"
	    ARTISTNO=$(curl -s $QUERYURL | grep -A 10 "Search Results" | grep member.php | sed 's/>/>\n/g' | head -1 | cut -d "?" -f 2 | cut -d "\"" -f 1)
	    if [ -z $ARTISTNO ];
	    then
		echo "The query returned no results"
		exit 1
	    fi
	    
	    MODURL="http://modarchive.org/index.php?request=view_artist_modules&query=${ARTISTNO}"
	    MODLIST="artist.${OPTARG}"
	    #PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
            ;;
	
	m) 
            MODURL="http://modarchive.org/index.php?request=search&query=${OPTARG}&submit=Find&search_type=filename_or_songtitle"
	    MODLIST="search.${OPTARG}"
            #PAGES=$(curl -s $MODURL | html2text | grep "Jump" | sed 's/\//\n/g' | tail -1 | cut -d "]" -f1)
            ;;
	
	r)
	    SHUFFLE="true"
	    ;;
	n)	
	    
	    expr $OPTARG + 1 > /dev/null
	    if [ $? = 0 ];
	    then
		TRACKSNUM=${OPTARG};
	    else
		echo "ERROR -n requires a number as argument"
		usage
		exit 1
	    fi		
	    ;;

	p)
	    case $OPTARG in 
		audacious)
		    PLAYER='/usr/bin/audacious'
		    PLAYEROPTS='-e'
		    PLAYERBG='true'
		    ;;
		
		mikmod)
		    PLAYER='/usr/bin/mikmod'
		    PLAYEROPTS='-i -X --surround --hqmixer -f 48000 -X'
		    PLAYERBG='false'
		    ;;
		opencp)
		    PLAYER='/usr/bin/ocp'
		    PLAYEROPTS='-p'
		    PLAYERBG='false'
		    ;;
		
		?)
		echo "ERROR: ${OPTARG} player is not supported."
		echo ""
		usage
		exit 1
		;;
	    esac
	    ;;
	?)
	usage
	exit 1
	;;
    esac
done

if [ ! -e $PLAYER ];
then
    echo "This scripts needs $PLAYER to run. Please install it or change the script"
    usage
    exit 1
fi

if [ ${PLAYERBG} = "true" ] && [ -z $(pidof $PLAYER) ];
then
    echo "$PLAYER isn't running. Please, launch it first"
    usage
    exit 1
fi

if [ -z $MODURL ];
then
    usage
    exit 1
fi

echo "Starting Modarchive JukeBox Player"
mkdir -p $MODPATH
LOOP="true"

if [ -z $RANDOMSONG ];
then
    echo "Creating playlist"
    create_playlist
    
    TRACKSFOUND=$(wc -l "$MODPATH/$PLAYLISTFILE" | cut -d " " -f 1)
    echo "Your query returned ${TRACKSFOUND} results"
fi

COUNTER=1
while [ $LOOP = "true" ]; do
    if [ -z $RANDOMSONG ];
    then
	SONGURL=$(cat "$MODPATH/$PLAYLISTFILE" | head -n ${COUNTER} | tail -n 1)
	let COUNTER=$COUNTER+1
	if [ $TRACKSNUM -gt 0 ]; 
	then
	    if [ $COUNTER -gt $TRACKSNUM ] || [ $COUNTER -gt $TRACKSFOUND ]; 
	    then
		LOOP="false"
	    fi
	elif [ $COUNTER -gt $TRACKSFOUND ]; 
	then
	    LOOP="false"
	fi
    else	
	SONGURL=$(curl -s "$MODURL" | sed 's/href=\"/href=\"\n/g' | sed 's/\">/\n\">/g' | grep downloads.php | head -n 1);
	let COUNTER=$COUNTER+1
	if [ $TRACKSNUM -gt 0 ] && [ $COUNTER -gt $TRACKSNUM ]; 
	then
	    LOOP="false"
	fi
    fi

    MODFILE=$(echo "$SONGURL" | cut -d "#" -f 2)
    if [ ! -e "${MODPATH}/${MODFILE}" ]; then
	echo "Downloading $SONGURL to $MODPATH/$MODFILE";
	curl -s -o "${MODPATH}/${MODFILE}" "$SONGURL";
    fi
    if [ -e "${MODPATH}/${MODFILE}" ];then
	$PLAYER $PLAYEROPTS "${MODPATH}/${MODFILE}";
    fi
done

