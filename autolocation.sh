#!/bin/bash
# 默认位置
default="Automatic"
# WiFi 设备
device="en0"
# 当前连接的 WiFi 名称
SSID=`networksetup -getairportnetwork $device|awk -F : '{print $2}'|sed 's/[[:space:]]//g'`
# 当前位置
current=`networksetup -getcurrentlocation`
# plist
plist="$HOME/Library/LaunchAgents/autolocation.plist"

function println() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t$@" > $HOME/.autolocation/run.log
}

function switchtolocation() {
  networksetup -switchtolocation $1 
}

function switching(){
    println "Current location: $current"
    println "Current SSID: $SSID"
    if [ "$SSID" == "$current" ]; then
        println "Already in $SSID"
    else 
        switchtolocation $SSID
        if [ $? -ne 0 ]; then 
            println "Location $SSID not found, switching to $default"
            switchtolocation $default
        else 
            println "Switched to $SSID Successfully"
        fi
    fi
}

case $1 in
    "install")
        echo "Installing..."
        cat > $plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>autolocation</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/autolocation</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WatchPaths</key>
    <array>
        <string>/Library/Preferences/SystemConfiguration/com.apple.wifi.message-tracer.plist</string>
    </array>
</dict>
</plist>
EOF
        cp $0 /usr/local/bin/autolocation
        chmod +x /usr/local/bin/autolocation
        launchctl load -w $plist
        mkdir $HOME/.autolocation  2&>1 > /dev/null
        ;;
    "uninstall")
        echo "Uninstalling..."
        launchctl unload -w $plist
        rm $plist
        rm /usr/local/bin/autolocation
        ;;
    "load")
        echo "Loading..."
        launchctl load -w $plist
        ;;
    "unload")
        echo "Unloading..."
        launchctl unload -w $plist
        ;;
    *)
        switching
        ;;
esac