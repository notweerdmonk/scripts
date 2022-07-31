if [[ $(wmname) != "i3" ]]; then
  MY_EUID=$(id --real --user)
  GNOME_SESSION_PID=$(pgrep --euid $MY_EUID gnome-session | sed -n '1p')
  export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$GNOME_SESSION_PID/environ|cut -d= -f2- | tr -d '\0')
fi

n=$(shuf -i 1-$(ls ${HOME}/Pictures | wc -l) -n 1);i=0
for path in ${HOME}/Pictures/*.jpg
do
  if [ $((i++)) -eq ${n} ]; then
    if [[ $(wmname) == "i3" ]]; then
      feh --bg-fil ${path}
    else
      gsettings set org.gnome.desktop.background picture-uri file:///${path};
    fi
  fi
done
