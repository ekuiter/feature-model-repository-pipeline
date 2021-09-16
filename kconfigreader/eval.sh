#!/bin/bash

for tag in $(git -C linux tag | grep -v rc | grep -v tree); do ./run.sh $tag x86; done
