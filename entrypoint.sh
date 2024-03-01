#!/bin/bash

set -ex

x11_tech=$1

# Setup headless X11

# use xvfb
if [ "$x11_tech" = "xvfb" ]; then
  Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +extension RANDR +extension RENDER +render -noreset &
  export DISPLAY=:0
fi

# use xorg
if [ "$x11_tech" = "xorg" ]; then
  Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile ./10.log -config /etc/X11/xorg.conf :10 &
  export DISPLAY=:10
fi

wine /usr/local/bin/d3d11-triangle/d3d11-triangle.exe
