EUID=$(id --real --user)
PID=$(pgrep --euid $EUID gnome-session)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ|cut -d= -f2-)
n=$(shuf -i 1-$(ls /home/weerdmonk/Pictures | wc -l) -n 1);i=0
for path in /home/weerdmonk/Pictures/*.jpg
do
  if [ $((i++)) -eq ${n} ]; then
    gsettings set org.gnome.desktop.background picture-uri file:///${path};
  fi
done
