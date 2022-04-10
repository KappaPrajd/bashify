#!/bin/bash

SEARCH_TRACK_URL='https://46.101.210.150/search'

SPOTIFY_DBUS_SERVICE='org.mpris.MediaPlayer2.spotify'
PLAYER_OBJECT_PATH='/org/mpris/MediaPlayer2'
PLAYER_INTERFACE='org.mpris.MediaPlayer2.Player'

print_help() {
    echo 'Bashify - Simple command line interface for Spotify'
    echo ''
    echo 'Usage: bashify [help] [play] [pause] [skip]'
    echo 'Options:'
    echo '  play [song] - Resume playing or play a song if passed'
    echo '  pause - Pause playing'
    echo '  skip - Play the next queued song'
    echo '  help - Print this help'
}

# Send D-BUS signal to the Spotify player interface
send_signal() {
    dbus-send --print-reply --dest=$SPOTIFY_DBUS_SERVICE $PLAYER_OBJECT_PATH $PLAYER_INTERFACE.$* 1>/dev/null
}

play_song() {
    # Format the search query param
    param=$*
    query="${param// /%20}"

    # Send HTTP request to find the best match
    response=$(curl -s -X GET $SEARCH_TRACK_URL'?q='$query)
    
    # Parse response
    is_valid=$(echo $response | jq 'has("song_uri")')
    
    if [ $is_valid == false ]
    then
        error=$(echo $response | jq -r '.error')
        echo $error
    else
        song_uri=$(echo $response | jq -r '.song_uri')
        send_signal 'OpenUri string:'$song_uri
    fi
}

# Check if Spotify is running
if ! pgrep -x 'spotify' > /dev/null
then
    echo 'Spotify is not running.'
    exit
fi

# Parse arguments
if [ $# -eq 0 ]
then
    echo 'No arguments were passed'
elif [ $1 == 'play' ]
then
    if [ -z $2 ]
    then
        send_signal 'Play'
    else
        play_song ${@:2}
    fi 
elif [ $1 == 'skip' ]
then
    send_signal 'Next'
elif [ $1 == 'pause' ]
then
    send_signal 'Pause'
else
    print_help
fi