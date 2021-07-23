#!/bin/bash
# Example of a classic "netcat server"
# Illustrates the use of named pipes (FIFOs) and file descriptors

# See https://unix.stackexchange.com/questions/405439/bash-use-automatic-file-descriptor-creation-instead-of-fifo
startServer(){
    local connected=0 fd
    exec {fd}<> <(:)
    nc -q 0 -l -p "$PORT" <&$fd | 
    while read -r line
    do  if [ "$connected" == "0" ]
        then startServer $(($1+1)) &
             connected="1"
        fi
        echo server $1 logic goes here
    done >&$fd
    exec {fd}<&-
}

PORT="1234";

startServerOriginal(){
    fifo="fifo/$1";
    mkfifo "$fifo";

    connected="0";

    netcat -q 0 -l -p "$PORT" < "$fifo" | while read -r line; do
        if [ "$connected" == "0" ];then
            #listen for a new connection
            startServer $(($1+1))&
            connected="1";
        fi

        #server logic goes here

    done > "$fifo";

    rm "$fifo";
}

mkdir fifo;
startServerOriginal 0;
