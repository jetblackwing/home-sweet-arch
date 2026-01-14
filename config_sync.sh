#!/bin/bash

# A simple script to sync configuration files with system directory

rm -rf ~/.config/StartupItems/*.*
cp -rv *.sh ~/.config/StartupItems/