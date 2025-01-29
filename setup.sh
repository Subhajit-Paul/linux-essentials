#!/bin/bash

# Function to print colorful messages
print_message() {
    echo -e "\e[1;34m===> $1\e[0m"
}

print_error() {
    echo -e "\e[1;31m===> ERROR: $1\e[0m"
}

print_warning() {
    echo -e "\e[1;33m===> WARNING: $1\e[0m"
}

# Check if script is run with sudo
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Detect OS and version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    print_error "Cannot detect OS version"
    exit 1
fi

print_message "Detected OS: $OS $VER"

# Update and upgrade system
print_message "Updating and upgrading system packages..."
apt update && apt upgrade -y

# Install required packages
print_message "Installing required packages..."
apt install -y curl wget git unzip build-essential

# Install Nerd Fonts
print_message "Installing Nerd Fonts..."
mkdir -p ~/.local/share/fonts
cd /tmp
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# Install Zsh
print_message "Installing Zsh..."
apt install -y zsh

# Install Oh My Zsh
print_message "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set Zsh as default shell
print_message "Setting Zsh as default shell..."
chsh -s $(which zsh) $USER

# Install and configure Zsh plugins
print_message "Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Update .zshrc with plugins
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting python)/' ~/.zshrc

# Configure Oh My Zsh theme
print_message "Configuring Oh My Zsh with Agnoster theme..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

# Install additional tools
print_message "Installing additional tools..."
apt install -y fzf bat ripgrep tree htop neofetch tldr ncdu

# Create useful aliases
echo "# Custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='netstat -tulanp'
alias mem='free -h'
alias df='df -h'
alias cls='clear'
alias b='batcat'
alias -g -- -h='-h 2>&1 | batcat --language=help --style=plain'
alias -g -- --help='--help 2>&1 | batcat --language=help --style=plain'
alias f=\"fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}'\" 
" >> ~/.zshrc

# Create bat alias if batcat is the command
if command -v batcat &> /dev/null; then
    echo "alias bat='batcat'" >> ~/.zshrc
fi

# Function to prompt yes/no questions
prompt_install() {
    while true; do
        read -p "Do you want to install $1? (y/n) " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Optional Development Tools
if prompt_install "Docker"; then
    print_message "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
    rm get-docker.sh
fi

if prompt_install "Node.js (via nvm)"; then
    print_message "Installing Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
fi

if prompt_install "Python development tools"; then
    print_message "Installing Python tools..."
    apt install -y python3-pip python3-venv
fi

# Optional GUI applications
if prompt_install "Brave Browser"; then
    print_message "Installing Brave Browser..."
    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
    apt update
    apt install -y brave-browser
fi

if prompt_install "Chromium"; then
    print_message "Installing Chromium..."
    apt install -y chromium-browser
fi

if prompt_install "Visual Studio Code"; then
    print_message "Installing Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list
    rm -f packages.microsoft.gpg
    apt update
    apt install -y code
fi

# Setup Git configuration
if prompt_install "Configure Git"; then
    print_message "Configuring Git..."
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
    git config --global core.editor "nano"
fi

print_message "Installation complete! Please log out and log back in for all changes to take effect."
