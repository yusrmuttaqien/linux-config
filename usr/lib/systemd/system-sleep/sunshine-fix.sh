#!/bin/bash
case $1/$2 in
  pre/*)
    # Stops Sunshine before going to sleep
    su - yusrmuttaqien -c "XDG_RUNTIME_DIR=/run/user/$(id -u yusrmuttaqien) systemctl --user stop sunshine"
    ;;
  post/*)
    # Starts Sunshine after waking up
    su - yusrmuttaqien -c "XDG_RUNTIME_DIR=/run/user/$(id -u yusrmuttaqien) systemctl --user start sunshine"
    ;;
esac
