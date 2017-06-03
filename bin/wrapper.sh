#!/bin/sh
##############################################################################
#
# @package Minecraft server controller
# @module  Server `start` command test wrapper.
# @version SVN: $Id: wrapper.sh 243 2017-06-03 15:03:50Z anrdaemon $
#
#HELP#########################################################################
#
# This script replaces server process normally started by the 'start' command.
# It lets you use "start" command quickly and safely while you're developing
# your own command or testing the launcher environment.
#
# To use: start the module with '--dummy' switch, i.e.:
#
#   mcsc.sh start --dummy
#.
##############################################################################
#
# This program is free software.
# It comes without any warranty, to the extent permitted by applicable law.
# You can redistribute it and/or modify it under the terms of the
#
#        Do What The Fuck You Want To Public License, Version 2,
#
# as published by Sam Hocevar.
# See http://www.wtfpl.net/ for more details.
#
##############################################################################

while read -rp "MCSC: " f; do
  printf '\033k%s\033\\' "$f"
  [ "$f" = "/stop" ] && exit
done
