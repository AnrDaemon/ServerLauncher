@ECHO OFF
REM ############################################################################
REM
REM @package Minecraft server controller
REM @module  Jconsole helper script.
REM @version $Id: jconsole.cmd 69 2016-04-01 21:55:58Z anrdaemon $
REM
REM ############################################################################
REM
REM This program is free software.
REM It comes without any warranty, to the extent permitted by applicable law.
REM You can redistribute it and/or modify it under the terms of the
REM
REM        Do What The Fuck You Want To Public License, Version 2,
REM
REM as published by Sam Hocevar.
REM See http://www.wtfpl.net/ for more details.
REM
REM ############################################################################
ECHO Start your Java application with settings:
ECHO.
ECHO -Djava.rmi.server.hostname=localhost
ECHO -Dcom.sun.management.jmxremote.port=6506
ECHO -Dcom.sun.management.jmxremote.rmi.port=6506
ECHO -Dcom.sun.management.jmxremote.authenticate=false
ECHO -Dcom.sun.management.jmxremote.ssl=false
ECHO.
ECHO Proxy port localhost:6506 to the remote server running your Java application.
ECHO Then connect the console.
START "" "jconsole.exe" -interval=5 -notile service:jmx:rmi:///jndi/rmi://localhost:6506/jmxrmi
