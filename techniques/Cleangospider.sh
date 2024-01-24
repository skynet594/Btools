#!/bin/bash

clean_result=cleanGospider.txt
for i in {3..7}; do
    cat $1 | awk '{print $'$i'}' | grep -E 'http[s]?://' | grep "http[s]\?://.*\\$2.*" | tee -a $clean_result
done

cat $clean_result | grep '.js' | tee -a jsResult.txt
cat $clean_result | grep '.json' | tee -a jsResult.txt
cat $clean_result | grep '.txt' | tee -a txtResult.txt
cat $clean_result | grep '.php' | tee -a phpResult.txt
