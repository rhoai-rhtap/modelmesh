#!/bin/bash

echo ""
echo "#######################"
echo "# Merge driver called #"
echo "#######################"
echo ""

echo "ancestor: $1"
echo "---------"
cat $1
echo ""

echo " current: $2"
echo "---------"
cat $2
echo ""

echo "   other: $3"
echo "---------"
cat $3
echo ""

exit 0