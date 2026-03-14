#!/usr/bin/env bash
while :
do
        date +%s > /storage/keepalive.txt
        sync
        sleep 30
done

