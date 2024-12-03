#!/usr/bin/env bash
set -euo pipefail

# Disable screen lock and screen saver
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.session idle-delay 0

# Check for essential dependencies first
if ! command -v sudo >/dev/null; then
  echo "sudo is required but not installed"
  exit 1
fi

# Install basic dependencies
echo "Installing basic dependencies..."
sudo apt update -y
sudo apt install -y git zsh curl

# Prompt for password
read -s -p "Enter password for secrets.zip: " SECRETS_PASSWORD
echo

# Use password to unzip
echo "Unzipping secrets.zip..."
if ! unzip -P "$SECRETS_PASSWORD" ./secrets.zip; then
  echo "Failed to unzip secrets.zip - incorrect password?"
  exit 1
fi

# Move secrets to home directory
echo "Installing ssh keys..."
mkdir -p "$HOME/.ssh"
if ! cp -rf ./secrets/.ssh/* "$HOME/.ssh/"; then
  echo "Failed to install ssh keys"
  exit 1
fi

# Copy config files
cp -r ./config/lazyvim ~/.config/nvim
cp -r ./config/lazygit ~/.config/lazygit
cp -r ./config/i3 ~/.config/i3
cp -r ./config/Cursor ~/.config/Cursor
cp -r ./config/.profile ~/.profile
cp -r ./config/.Xmodmap ~/.Xmodmap

# Move ./secrets/kristian.conf to /etc/wireguard/kristian.conf
echo "Installing wireguard config..."
sudo mkdir -p /etc/wireguard
if ! sudo cp -f ./secrets/kristian.conf /etc/wireguard/kristian.conf; then
  echo "Failed to install wireguard config"
  exit 1
fi

# Getting ready
if ! sudo apt update; then
  echo "Failed to update package lists"
  exit 1
fi

# curl
echo "Installing curl..."
if ! sudo apt install curl -y; then
  echo "Failed to install curl"
  exit 1
fi

# i3
echo "Installing i3..."
if ! /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2024.03.04_all.deb keyring.deb SHA256:f9bb4340b5ce0ded29b7e014ee9ce788006e9bbfe31e96c09b2118ab91fca734; then
  echo "Failed to download i3 keyring"
  exit 1
fi
if ! sudo apt install ./keyring.deb -y; then
  rm keyring.deb
  echo "Failed to install i3 keyring"
  exit 1
fi
echo "deb http://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
sudo apt update
sudo apt install i3 -y
mkdir -p ~/.config/i3
if [ ! -f "./config/i3/config" ]; then
  echo "i3 config file missing"
  exit 1
fi
cp "./config/i3/config" "$HOME/.config/i3/config"
sudo apt install i3blocks -y
sudo apt-get update && sudo apt-get install rofi

# neovim
echo "Installing neovim..."
if ! curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz; then
  echo "Failed to download neovim"
  exit 1
fi
if ! sudo rm -rf /opt/nvim; then
  echo "Failed to remove old neovim installation"
  exit 1
fi
if ! sudo tar -C /opt -xzf nvim-linux64.tar.gz; then
  echo "Failed to extract neovim"
  rm nvim-linux64.tar.gz
  exit 1
fi
export PATH="$PATH:/opt/nvim-linux64/bin"
if ! command -v nvim >/dev/null; then
  echo "Failed to add neovim to PATH"
  exit 1
fi
rm nvim-linux64.tar.gz
echo 'export PATH="/opt/nvim-linux64/bin:$PATH"' >>~/.profile

# lazyvim < neovim
echo "Installing lazyvim..."
mkdir -p ~/.config/nvim
cp -r ./config/lazyvim/nvim/* ~/.config/nvim/

# rust
echo "Installing rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
echo 'source "$HOME/.cargo/env"' >>~/.profile

# Source rustup
. "$HOME/.cargo/env"

# Install build-essential
if ! sudo apt install build-essential -y; then
  echo "Failed to install build-essential"
  exit 1
fi

# ripgrep
echo "Installing ripgrep..."
if ! cargo install ripgrep; then
  echo "Failed to install ripgrep"
  exit 1
fi

# clang
echo "Installing clang..."
if ! sudo apt install clang -y; then
  echo "Failed to install clang"
  exit 1
fi
sudo update-alternatives --set c++ /usr/bin/clang++

# fd
echo "Installing fd..."
if ! sudo apt install fd-find -y; then
  echo "Failed to install fd"
  exit 1
fi

# difftastic < rust
echo "Installing difftastic..."
if ! cargo install --locked difftastic; then
  echo "Failed to install difftastic"
  exit 1
fi

# alacritty
echo "Installing alacritty..."
if ! sudo apt install cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 -y; then
  echo "Failed to install alacritty dependencies"
  exit 1
fi
echo "Installing Alacritty, this might take a while..."
if ! cargo install alacritty; then
  echo "Failed to install alacritty"
  exit 1
fi

# node
echo "Installing node..."
export NVM_DIR="$HOME/.nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
# Source nvm immediately
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# Add a small delay to ensure NVM is ready
sleep 2
nvm install --lts
echo 'export NVM_DIR="$HOME/.nvm"' >>~/.profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >>~/.profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>~/.profile

# pnpm
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >>~/.profile
echo 'export PATH="$PNPM_HOME:$PATH"' >>~/.profile

# wireguard
echo "Installing wireguard..."
if ! sudo apt install -y wireguard; then
  echo "Failed to install wireguard"
  exit 1
fi

# jujutsu (jj)
echo "Installing jujutsu dependencies..."
if ! sudo apt-get install libssl-dev openssl pkg-config build-essential -y; then
  echo "Failed to install jujutsu dependencies"
  exit 1
fi
echo "Installing jujutsu..."
if ! cargo install --locked --bin jj jj-cli; then
  echo "Failed to install jujutsu"
  exit 1
fi

# docker
# Add Docker's official GPG key:
sudo sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

echo "Installing docker..."
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
  echo "Failed to install docker and its components"
  exit 1
fi

echo "Installing lazydocker..."
if ! curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash; then
  echo "Failed to install lazydocker"
  exit 1
fi

echo "Installing bun..."
if ! curl -fsSL https://bun.sh/install | bash; then
  echo "Failed to install bun"
  exit 1
fi
echo 'export BUN_INSTALL="$HOME/.bun"' >>~/.profile
echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >>~/.profile
source ~/.bashrc

# lazygit
echo "Installing lazygit..."
if ! LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*'); then
  echo "Failed to get latest lazygit version"
  exit 1
fi
if ! curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"; then
  echo "Failed to download lazygit"
  exit 1
fi
if ! tar xf lazygit.tar.gz lazygit; then
  echo "Failed to extract lazygit"
  exit 1
fi
if ! sudo install lazygit -D -t /usr/local/bin/; then
  echo "Failed to install lazygit"
  exit 1
fi

# pkg-config
echo "Installing pkg-config..."
if ! sudo apt-get install -y pkg-config; then
  echo "Failed to install pkg-config"
  exit 1
fi

# tracy profiler dependencies
## dbus
echo "Installing dbus..."
if ! sudo apt-get install -y dbus-x11; then
  echo "Failed to install dbus"
  exit 1
fi

## libxxkbcommon, wayland, wayland-protocols, libglvnd
echo "Installing libxxkbcommon, wayland, wayland-protocols, libglvnd..."
if ! sudo apt install libxkbcommon-x11-0 wayland-protocols -y; then
  echo "Failed to install libxxkbcommon, wayland, wayland-protocols, libglvnd"
  exit 1
fi

## capstone, glfw, freetype
echo "Installing capstone, glfw, freetype..."
if ! sudo apt install libcapstone-dev libglfw3-dev libfreetype-dev -y; then
  echo "Failed to install capstone, glfw, freetype"
  exit 1
fi

# gtk3
echo "Installing libgtk-3-dev..."
if ! sudo apt-get install libgtk-3-dev -y; then
  echo "Failed to install libgtk-3-dev"
  exit 1
fi

# tracy profiler
# git clone git@github.com:wolfpld/tracy.git
# cd tracy
# cmake -B profiler/build -S profiler -DCMAKE_BUILD_TYPE=Release -DLEGACY=ON -DGTK_FILESELECTOR=ON
# cmake --build profiler/build --config Release --parallel
# cd ..

## move binaries to ~/bin
# mkdir -p ~/bin
# mv tracy/profiler/build/Tracy* ~/bin
# echo 'export PATH="$HOME/bin:$PATH"' >>~/.profile

# xserver utils
echo "Installing xserver utils..."
if ! sudo apt install -y x11-xserver-utils; then
  echo "Failed to install xserver-utils"
  exit 1
fi

# steam
echo "Installing steam..."
if ! sudo snap install steam; then
  echo "Failed to install steam"
  exit 1
fi

# wget
echo "Installing wget..."
if ! sudo apt install -y wget; then
  echo "Failed to install wget"
  exit 1
fi

# chrome
echo "Installing chrome..."
if ! wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
  echo "Failed to download Chrome .deb package"
  exit 1
fi

if ! sudo dpkg -i google-chrome-stable_current_amd64.deb; then
  echo "Failed to install Chrome .deb package"
  exit 1
fi

# zoxide
echo "Installing zoxide..."
if ! curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
  echo "Failed to install zoxide"
  exit 1
fi
echo 'eval "$(zoxide init zsh)"' >>~/.zshrc

# git butler
echo "Downloading git butler..."
if ! wget https://releases.gitbutler.com/releases/release/0.14.1-1533/linux/x86_64/GitButler_0.14.1_amd64.deb; then
  echo "Failed to download git butler"
  exit 1
fi
echo "Installing git butler..."
if ! sudo dpkg -i GitButler_0.14.1_amd64.deb; then
  echo "Failed to install git butler"
  exit 1
fi

# rust rover
echo "Installing rust rover..."
if ! sudo snap install rustrover --classic; then
  echo "Failed to install rust rover"
  exit 1
fi

# cursor
mkdir ./cursor
cd ./cursor
echo "Installing cursor..."
if ! wget https://downloader.cursor.sh/linux/appImage/x64; then
  echo "Failed to download cursor"
  exit 1
fi
if ! sudo mv ./x64 /usr/bin/cursor; then
  echo "Failed to move cursor to /usr/bin"
  exit 1
fi
if ! sudo chmod +x /usr/bin/cursor; then
  echo "Failed to make cursor executable"
  exit 1
fi
cd ..

# slack
echo "Installing slack..."
if ! sudo snap install slack; then
  echo "Failed to install slack"
  exit 1
fi

# discord
echo "Installing discord..."
if ! wget https://stable.dl2.discordapp.net/apps/linux/0.0.76/discord-0.0.76.deb; then
  echo "Failed to download discord"
  exit 1
fi
if ! sudo dpkg -i discord-0.0.76.deb; then
  echo "Failed to install discord"
  exit 1
fi

# FUSE
echo "Installing fuse..."
if ! sudo apt install fuse -y; then
  echo "Failed to install fuse"
  exit 1
fi

# bacon
echo "Installing bacon..."
if ! cargo install bacon; then
  echo "Failed to install bacon"
  exit 1
fi

# doppler
# Debian 11+ / Ubuntu 22.04+
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install doppler

echo 'export PATH="$HOME/.cargo/bin:$PATH"' >>~/.profile

# deactivate apparmor thingy which causes problems with launching AppImages
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

# post install verification
echo "Verifying installations..."
if ! command -v i3 >/dev/null; then echo "i3 not installed"; fi
if ! command -v nvim >/dev/null; then echo "Neovim not installed"; fi
if ! command -v rustc >/dev/null; then echo "Rust not installed"; fi
if ! command -v cargo >/dev/null; then echo "Cargo not installed"; fi
if ! command -v alacritty >/dev/null; then echo "Alacritty not installed"; fi
if ! command -v node >/dev/null; then echo "Node not installed"; fi
if ! command -v pnpm >/dev/null; then echo "pnpm not installed"; fi
if ! command -v jj >/dev/null; then echo "jujutsu not installed"; fi
if ! command -v wg >/dev/null; then echo "wireguard not installed"; fi
if ! command -v bun >/dev/null; then echo "bun not installed"; fi
if ! command -v docker >/dev/null; then echo "docker not installed"; fi
if ! command -v cursor >/dev/null; then echo "Note: Cursor was not installed by this script"; fi
if ! command -v bun >/dev/null; then echo "Note: Bun was not installed by this script"; fi
if ! command -v node >/dev/null; then echo "Note: Node was not installed by this script"; fi
if ! command -v pnpm >/dev/null; then echo "Note: pnpm was not installed by this script"; fi
if ! command -v lazygit >/dev/null; then echo "Note: lazygit was not installed by this script"; fi
if ! command -v lazydocker >/dev/null; then echo "Note: lazydocker was not installed by this script"; fi
if ! command -v steam >/dev/null; then echo "Note: steam was not installed by this script"; fi
if ! command -v git-butler >/dev/null; then echo "Note: git-butler was not installed by this script"; fi
if ! command -v discord >/dev/null; then echo "Note: discord was not installed by this script"; fi
# add applications

## Alacritty
cat <<EOF >~/.local/share/applications/Alacritty.desktop
[Desktop Entry]
Version=1.0
Name=Alacritty
Comment=Edit text files
Exec=alacritty
Terminal=false
Type=Application
Icon=alacritty
Categories=Utilities;TerminalEmulator;
StartupNotify=false
EOF

## Tracy profiler
cat <<EOF >~/.local/share/applications/Tracy.desktop
[Desktop Entry]
Version=1.0
Name=Tracy
Comment=Tracy profiler
Exec=TRACY_DPI_SCALE=1.5 ~/bin/Tracy-release
Terminal=false
Type=Application
Icon=tracy
Categories=Development;
StartupNotify=false
EOF

## Chrome
cat <<EOF >~/.local/share/applications/Chrome.desktop
[Desktop Entry]
Version=1.0
Name=Chrome
Comment=Google Chrome
Exec=google-chrome
Terminal=false
Type=Application
Icon=google-chrome
Categories=Network;WebBrowser;
StartupNotify=false
EOF

# Cursor
cat <<EOF >~/.local/share/applications/Cursor.desktop
[Desktop Entry]
Version=1.0
Name=Cursor
Comment=Cursor
Exec=cursor
Terminal=false
Type=Application
Icon=cursor
Categories=Development;
StartupNotify=false
EOF

# make sure .zshrc and .bashrc exist
touch ~/.zshrc
touch ~/.bashrc

# add necessary config to .zshrc
echo "source ~/.profile" >>~/.zshrc
echo "source ~/.Xmodmap" >>~/.zshrc

# add necessary config to .bashrc
echo "source ~/.profile" >>~/.bashrc
echo "source ~/.Xmodmap" >>~/.bashrc

# Add this near the end of your script
echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.profile

# Add these to ~/.zshrc
echo '# Load completions' >>~/.zshrc
echo 'autoload -Uz compinit' >>~/.zshrc
echo 'compinit' >>~/.zshrc

# Add specific tool completions
echo 'source <(jj completion zsh)' >>~/.zshrc

# re-enable screen lock and screen saver
gsettings set org.gnome.desktop.screensaver lock-enabled true
gsettings set org.gnome.desktop.session idle-delay 300

echo "Installing oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
    echo "Failed to install oh-my-zsh"
    exit 1
  fi
else
  echo "oh-my-zsh is already installed"
fi

if ! command -v zsh >/dev/null; then echo "zsh not installed"; fi
