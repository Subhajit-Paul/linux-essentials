#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Functions
echo "Starting system setup..."

update_system() {
    sudo apt update && sudo apt upgrade -y
}

install_basic_tools() {
    sudo apt install -y python3-venv python3-pip curl git zsh fzf bat ripgrep tmux caca-utils
}

prompt_install() {
    read -p "Do you want to install $1? (y/n) " choice
    [[ "$choice" == "y" ]] && return 0 || return 1
}

print_message() {
    echo "===================================="
    echo "$1"
    echo "===================================="
}

download_nerdfont() {
    echo "Select a Nerd Font to install (Use arrow keys):"
    options=("FiraCode" "Hack" "JetBrainsMono" "SourceCodePro" "DroidSansMono")
    selected=$(printf "%s\n" "${options[@]}" | fzf --preview "curl -sL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/{}.zip")
    if [[ -n "$selected" ]]; then
        mkdir -p ~/.local/share/fonts
        pushd ~/.local/share/fonts
        curl -fLo "${selected}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${selected}.zip"
        unzip "${selected}.zip" && rm "${selected}.zip"
        fc-cache -fv
        popd
    fi
}

choose_terminal_theme() {
    echo "Choose a terminal color scheme (Use arrow keys):"
    options=("Dracula" "Solarized Dark" "Solarized Light" "Gruvbox" "Nord")
    selected=$(printf "%s\n" "${options[@]}" | fzf --preview "curl -sL https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/screenshots/{}.png | img2txt -W 80")
    if [[ -n "$selected" ]]; then
        echo "You selected $selected. Apply it manually in your terminal settings."
    fi
}

install_ohmyzsh() {
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    if [ -f ~/.zshrc ]; then
        sed -i 's/ZSH_THEME=".*"/ZSH_THEME="agnoster"/' ~/.zshrc
    fi
    chsh -s $(which zsh)
}

setup_aliases() {
    echo "Setting up aliases..."
    cat <<EOL >> ~/.zshrc

# Custom Aliases
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
alias f="fzf --preview 'batcat --color=always --style=numbers --line-range=:500 {}'"
EOL
    source ~/.zshrc
}

interactive_git_setup() {
    echo "Setting up Git..."
    read -p "Enter your Git name: " git_name
    read -p "Enter your Git email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    echo "Git configured successfully!"
}

setup_ssh_keys() {
    echo "Setting up SSH keys for GitHub..."
    read -p "Enter your GitHub email: " github_email
    ssh-keygen -t ed25519 -C "$github_email"
    eval "$(ssh-agent -s)" >/dev/null 2>&1 || echo "Failed to start ssh-agent"
    ssh-add ~/.ssh/id_ed25519
    echo "Your SSH public key (add this to GitHub):"
    cat ~/.ssh/id_ed25519.pub
}

install_optional_software() {
    if prompt_install "Brave Browser"; then
        print_message "Installing Brave Browser..."
        curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt update
        sudo apt install -y brave-browser
        rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg
    fi
    
    if prompt_install "Chromium"; then
        print_message "Installing Chromium..."
        sudo apt install -y chromium-browser
    fi
    
    if prompt_install "Visual Studio Code"; then
        print_message "Installing Visual Studio Code..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
        rm -f packages.microsoft.gpg
        sudo apt update
        sudo apt install -y code
    fi
}

# Run functions
update_system
install_basic_tools
download_nerdfont
choose_terminal_theme
install_ohmyzsh
setup_aliases
interactive_git_setup
setup_ssh_keys
install_optional_software

echo "Setup complete! Please restart your terminal or log out and log back in."
