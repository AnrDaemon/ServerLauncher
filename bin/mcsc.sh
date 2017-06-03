#!/bin/sh
##############################################################################
#
# @package Minecraft server controller
# @module  Core script.
# @version $Id: mcsc.sh 243 2017-06-03 15:03:50Z anrdaemon $
#
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

# FIX major version number goes here.
MC_VER='$Version: 0.1 $.$Rev: 243 $'

## Check getopt package availability.
getopt --test
if [ $? -ne 4 ]; then
	echo "Enhanced 'getopt' package required." >&2
	exit 4
fi

# Reset base variables
unset _mcr _mc_safe _mc_verbose cmd

# Self-reference
_mcsc="$(basename "$0")"

## Locate base directories.
eval "$(
  _dp0="$(dirname "$(cygpath -au "$0" 2> /dev/null || readlink -en "$0")")"
  if [ "$MCSC_DIR" ] && [ -f "$MCSC_DIR/launcher.properties" ]; then
    _mcr="$MCSC_DIR"
  elif [ -f "$_dp0/launcher.properties" ]; then
    _mcr="$_dp0"
  elif [ -f "$HOME/launcher.properties" ]; then
    _mcr="$HOME"
  else
    echo "Unable to locate launcher configuration." >&2
    echo cmd=help
  fi
  echo _mcr="$_mcr"
  echo _dp0="$_dp0"
)"

## Version string.
mc_version()
{
  echo "Minecraft server controller, rev. ${MC_VER}"
}

## Command call wrapper.
#
# Use
#   mc_call <cmd> [ arguments ]
#
# Do NOT source commands manually, unless you 100% know what you are doing.
mc_call()
{
  (
  set -e
  cmd="$1"; shift

  if [ -f "$_dp0/${cmd}.mcsc" ]; then
    is_debug && set -x
    . "$_dp0/${cmd}.mcsc"
  else
    {
      echo "Command not recognized."
      echo "Try '$_mcsc --help' to see the list of available commands."
      return 1
    } >&2
  fi
  )
}

## Safety lock.
#
# Exits with status 99 to indicate the command should run exclusively.
# Use form 2 when inside a subshell.
# Or 'set -e' for subshell (recommended, see mc_call for an example).
#
#   -v - allow verbose reporting (global verbosity level also honored)
#
# Use
#   mc_safe [-v]
#   mc_safe [-v] || exit 99
#
mc_safe()
{
  # If session is "already safe"?
  [ "$_mc_safe" ] && return 0

  # If another command is running?
  [ "$(cat "$_lock")" ] && {
    [ "$1$_mc_verbose" ] && echo "The '$(cat "$_lock")' command is already running."
    return 99
  }

  # Server is running under GNU screen?
  mc_remote && {
    [ "$1$_mc_verbose" ] && echo "The server is already running. Try '$_mcsc attach' to attach to the console."
    return 99
  }

  # Set current running command.
  mc_verbose "Safeguarding current session."
  printf "%s" "$cmd" >&9
  _mc_safe=safe
}

## Test if a system is set for remote control
#
#   -v - allow verbose reporting (global verbosity level also honored)
#
# Use
#   mc_remote [-v]
#
# Exits with:
#   0 - system is set for remote control and server is currently running
#   1 - system is not set for remote control
#   2 - system is set for remote control but no running server is found
#
mc_remote()
{
  if [ "$SESSION" ]; then
    if screen -S "$SESSION" -p "$_mc_window:" -Q title > /dev/null; then
      return 0
    else
      [ "$1$_mc_verbose" ] && echo Server is not running.
      return 2
    fi
  else
    [ "$1$_mc_verbose" ] && echo Server is not configured to allow remote control.
    return 1
  fi >&2
}

## Test if we are in debug mode.
#
# Use
#   is_debug && do something... || do something else...
#
is_debug()
{
  [ "$_mc_debug" ]
}

## Test if we are in verbose mode.
#
# Use
#   is_verbose && do something... || do something else...
#
is_verbose()
{
  [ "$_mc_verbose" ]
}

## Verbose mode helper.
#
# Use
#   mc_verbose message [...]
#
# Each message will be printed to STDOUT as a separate line.
# If you want an "error" message, redirect the call yourself.
#
mc_verbose()
{
  [ "$_mc_verbose" ] && printf "%s\n" "$@" || true
}

eval set -- $(getopt --name "$_mcsc" -o '+HtvV' --longoptions 'debug,help,test,verbose,version' --shell sh -- "$@")
for i; do
  case $i in
    --debug)
      _mc_debug=debug
      shift
      ;;
    -H|--help)
      cmd=help
      shift
      ;;
    -t|--test)
      echo 'Test request.'
      exit 0
      ;;
    -v|--verbose)
      _mc_verbose="verbose"
      shift
      ;;
    -V|--version)
      cmd=version
      shift
      ;;
    --)
      shift
      break
      ;;
  esac
done

[ "$cmd" ] && set -- "$cmd" "$@"
if [ "$1" = "help" ] || [ -z "$1" ]; then
# No more parameters? Ok, you need to learn something.
  mc_call help
  exit 0
elif [ "$1" = "version" ]; then
  mc_version
  exit 0
fi

cd "$_mcr"

## Read launcher configuration.
unset TAR_SUFFIX DAEMON OPTIONS _java SESSION
while read -r opt; do
  [ "${opt%%#*}" ] || continue
  case "${opt%%=*}" in
    backup-suffix)
      TAR_SUFFIX="${opt#*=}"
      ;;
    daemon)
      DAEMON="$(readlink -en "${opt#*=}")"
      [ -f "$DAEMON" ] && [ -r "$DAEMON" ] || {
        echo "Unable to find server jar file." >&2
        exit 2
      }
      [ "$(uname -o)" = "Cygwin" ] && DAEMON="$(/usr/bin/cygpath -alw "$DAEMON")"
      ;;
    daemon-options)
      OPTIONS="${opt#*=}"
      ;;
    java)
      _java="$(readlink -en "${opt#*=}")"
      ;;
    session)
      if [ "$(which screen)" ]; then
        SESSION="${opt#*=}"
        _mc_window="< $SESSION >"
      fi
      ;;
  esac
done < "$_mcr/launcher.properties" || true

# Notify the user, if GNU screen is not used.
[ "$SESSION" ] || mc_verbose "Warning: Server session name is not set." \
    "The server will be started in bare console and no remote control will be possible." >&2

# Make some coffee.
JAVA="${_java:-/usr/bin/java}"

[ -x "$JAVA" ] && [ ! -d "$JAVA" ] || {
  echo "Unable to find Java executable." >&2
  exit 2
}

# Notify if using default values.
[ "$_java" ] || mc_verbose "Warning: Using default Java executable from \`$JAVA'." \
    "This may or may not be what you are looking for." \
    "You can avoid this message by setting \`java=<path>' in launcher config." >&2

if [ "${1#-}" = "$1" ]; then
# The command word is given, pass the rest of the command to the callback.
  _lock="$_mcr/console-session.lock"
  trap "rm '$_lock'" EXIT HUP INT QUIT ABRT TERM
  mc_call "$@" 9>> "$_lock"
  _err=$?
  if [ $_err -eq 99 ]; then
    #echo "The $(cat "$_lock") command is running already." >&2
    exit 3
  fi
  exit $_err
else
# An unrecognized option given before command.

  echo "ERROR: Unrecognized option '$1'." >&2
  exit 1

fi
