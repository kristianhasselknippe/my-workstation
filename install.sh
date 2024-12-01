#!/usr/bin/env bash
set -euo pipefail

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
sudo apt install curl -y

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
if [ ! -f "./i3/config" ]; then
    echo "i3 config file missing"
    exit 1
fi
cp "./i3/config" "$HOME/.config/i3/config"
sudo apt install i3blocks -y

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

# lazyvim < neovim
echo "Installing lazyvim..."
mkdir -p ~/.config/nvim
cp -r ./lazyvim/nvim/* ~/.config/nvim/

# rust
echo "Installing rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

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
sudo update-alternatives --config c++

# fd
echo "Installing fd..."
if ! sudo apt install fd-find -y; then
    echo "Failed to install fd"
    exit 1
fi

# difftastic < rust
echo "Installing difftastic..."
cargo install --locked difftastic


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

# pnpm
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

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
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo "Installing docker..."
if ! sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    echo "Failed to install docker and its components"
    exit 1
fi

echo "Installing bun..."
if ! curl -fsSL https://bun.sh/install | bash; then
    echo "Failed to install bun"
    exit 1
fi
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

cp -r ./lazyvim ~/.config/nvim
cp -r ./lazygit ~/.config/lazygit
cp -r ./i3 ~/.config/i3
cp -r ./Cursor ~/.config/Cursor

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

# add applications
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


# zsh
echo "Installing zsh..."
if ! command -v zsh >/dev/null; then
    if ! sudo apt install zsh -y; then
        echo "Failed to install zsh"
        exit 1
    fi
else
    echo "zsh is already installed"
fi

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