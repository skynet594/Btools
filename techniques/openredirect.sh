#!/bin/bash

cut -d '|' -f 2 $1 | grep "=http" >click-trackers-to-check.txt

sed 's/=http/=https\:\/\/example.com%23/g' click-trackers-to-check.txt >click-trackers-prepared.txt

ffuf -w click-trackers-prepared.txt -u FUZZ -r -mr "-apple-system, system-ui, BlinkMacSystemFont" -o click-trackers-tested.txt -of csv -timeout 2 -t 20
