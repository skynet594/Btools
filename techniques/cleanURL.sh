#!/bin/bash

clean_result=cleanURL.txt

cat $1 | grep "http[s]\?://.*\\$2.*" | tee -a $clean_result

cat $clean_result | grep '.js' | tee -a jsResult.txt
cat $clean_result | grep '.json' | tee -a jsResult.txt
cat $clean_result | grep '.txt' | tee -a txtResult.txt
cat $clean_result | grep '.php' | tee -a phpResult.txt
