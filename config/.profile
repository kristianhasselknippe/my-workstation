xset r rate 200 25

xrandr --output DP-2 --left-of HDMI-0 --rotate left
xrandr --output HDMI-0 --primary --rotate normal
xrandr --output DP-0 --right-of HDMI-0 --rotate right

setxkbmap -layout "us,no"
xmodmap ~/.Xmodmap

export PATH="$HOME/.local/bin:$PATH"

# neovim
export PATH="$PATH:/opt/nvim-linux64/bin"

# cargo installed binaries
export PATH="$PATH:$HOME/.cargo/bin"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
