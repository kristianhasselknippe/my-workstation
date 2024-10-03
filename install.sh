# Getting ready
sudo apt update

# curl
echo "Installing curl..."
sudo apt install curl -y

# i3
echo "Installing i3..."
if ! /usr/lib/apt/apt-helper download-file https://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2024.03.04_all.deb keyring.deb SHA256:f9bb4340b5ce0ded29b7e014ee9ce788006e9bbfe31e96c09b2118ab91fca734; then
  echo "Failed to download i3 keyring"
  exit 1
fi
sudo apt install ./keyring.deb -y
rm keyring.deb
echo "deb http://debian.sur5r.net/i3/ $(grep '^DISTRIB_CODENAME=' /etc/lsb-release | cut -f2 -d=) universe" | sudo tee /etc/apt/sources.list.d/sur5r-i3.list
sudo apt update
sudo apt install i3 -y
cp ./i3/config ~/.config/i3/config
sudo apt install i3blocks -y

# neovim
echo "Installing neovim..."
sudo apt-get install neovim -y

# lazyvim < neovim
echo "Installing lazyvim..."
cp ./lazyvim/nvim ~/.config/nvim

# rust
echo "Installing rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# difftastic < rust
echo "Installing difftastic..."
cargo install --locked difftastic

# alacritty
echo "Installing alacritty..."
sudo apt install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 -y
echo "Installing Alacritty, this might take a while..."
sudo cargo install alacritty

# node
echo "Installing node..."
## installs nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
## download and install Node.js (you may need to restart the terminal)
nvm install 22
## verifies the right Node.js version is in the environment
node -v # should print `v22.9.0`
## verifies the right npm version is in the environment
npm -v # should print `10.8.3`

# pnpm
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | sh -
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# post install verification
echo "Verifying installations..."
if ! command -v i3 >/dev/null; then echo "i3 not installed"; fi
if ! command -v nvim >/dev/null; then echo "Neovim not installed"; fi
if ! command -v rustc >/dev/null; then echo "Rust not installed"; fi
if ! command -v cargo >/dev/null; then echo "Cargo not installed"; fi
if ! command -v alacritty >/dev/null; then echo "Alacritty not installed"; fi
