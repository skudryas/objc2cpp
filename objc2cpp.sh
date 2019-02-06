#!/bin/bash
export OLD_OBJC_M_EXT=m
export OLD_OBJC_H_EXT=h
export NEW_CPP_EXT=cc
export NEW_HPP_EXT=hh
export DIFF_TOOL=meld
FIND_PATH=$1
ADDITIONAL_ACTION=
FIND_PATTERN=".*\.($OLD_OBJC_H_EXT|$OLD_OBJC_M_EXT)$"
find $FIND_PATH -regextype awk -regex $FIND_PATTERN -exec 'sh' 'wrap_awk.sh' '{}' ';' $ADDITIONAL_ACTION
