-XX:+UseG1GC
  - slightly less CPU
  - slightly more memory

-XX:+UseConcMarkSweepGC
  - slightly more CPU
  - slightly less memory

df -lB1m / /home | awk '2{print $1 " " $4}' | while read i; do echo $i $j; done

_dp0 - script installation directory.
_mcr - MC server home directory.

_mcr search order:

1. $MCSC_DIR if "$MCSC_DIR/launcher.properties" exists
2. $_dp0 if "$_dp0/launcher.properties" exists.
3. $HOME if "$HOME/launcher.properties" exists.

`exit 2` if unable to find the launcher properties file in either location.

eval set -- $(getopt ... -- "$@")
  Else you get all your parameters wrapped in quotes.

#HELP indicates the start of a help article. The line itself is not printed,
  anything beyond these five letters is ignored.
#. force stop help parser. If not found, reader will stop at first non-comment line.
Do note that help reader will strip one leading space after hash mark.

$MC_VERBOSE is either unset/empty or "-v", which is a "verbose" switch for
  majority of tools. You may use the variable directly. F.e.

    mv $MC_VERBOSE -bt ...

  or incorporate in a test:

    sometool ${MC_VERBOSE:+--verbose=3}
