#!/bin/bash
# Bootstrap script for fresh MacOS installation
# Usage: curl -fsSL https://raw.githubusercontent.com/mshumayl/dotfiles/main/install.sh | bash

set -euo pipefail

echo "Bootstrapping development environment..."

# Install Xcode Command Line Tools if needed
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode installation and re-run this script."
    exit 1
fi

# Install Homebrew if needed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Install chezmoi
brew install chezmoi

# Initialize and apply chezmoi
chezmoi init --apply mshumayl/dotfiles

echo ""
echo "Bootstrap complete!"
echo ""
echo "Manual steps remaining:"
echo "  1. Copy SSH keys to ~/.ssh/ and set permissions:"
echo "     chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub"
echo "  2. Restart terminal or run: exec zsh"
echo "  3. Start tmux and press prefix + I to install plugins"
echo "  4. Open Neovim to trigger plugin installation"
