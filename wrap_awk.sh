#!/bin/bash
if [ $1 != ${1%.$OLD_OBJC_H_EXT} ]
then
    echo "Processing header:" $1 " ..."
fi
if [ $1 != ${1%.$OLD_OBJC_M_EXT} ]
then
    echo "Processing source:" $1 " ..."
fi

awk -f objc2cpp.awk -v OLDOBJCHEXT=$OLD_OBJC_H_EXT -v OLDOBJCMEXT=$OLD_OBJC_M_EXT -v NEWCPPEXT=NEW_CPP_EXT -v NEWHPPEXT=NEW_HPP_EXT $1 > $1.tmp

if [ -n "$DIFF_TOOL" ]
then
    $DIFF_TOOL $1.tmp $1
fi

if [ $1 != ${1%.$OLD_OBJC_H_EXT} ]
then
    mv $1.tmp ${1%.$OLD_OBJC_H_EXT}.$NEW_HPP_EXT
fi
if [ $1 != ${1%.$OLD_OBJC_M_EXT} ]
then
    mv $1.tmp ${1%.$OLD_OBJC_M_EXT}.$NEW_CPP_EXT
fi
