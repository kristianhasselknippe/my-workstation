xset r rate 200 25

xrandr --output DP-2 --left-of HDMI-0 --rotate left
xrandr --output HDMI-0 --primary --rotate normal
xrandr --output DP-0 --right-of HDMI-0 --rotate right

setxkbmap -layout "us,no"
xmodmap ~/.Xmodmap
