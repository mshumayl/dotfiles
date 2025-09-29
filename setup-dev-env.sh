#!/usr/bin/env bash
# setup-dev-env.sh - Complete development environment setup
# Usage: ./setup-dev-env.sh [dotfiles_repo_url]

set -euo pipefail

# Configuration
DEFAULT_REPO_URL="https://github.com/yourusername/dotfiles.git"
REPO_URL="${1:-$DEFAULT_REPO_URL}"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_SUFFIX="backup-$(date +%Y%m%d-%H%M%S)"

echo "🚀 Setting up complete development environment..."
echo "📦 Repository: $REPO_URL"
echo "📁 Target: $DOTFILES_DIR"

# Function to backup existing files
backup_file() {
    local file="$1"
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "💾 Backing up $(basename "$file")"
        mv "$file" "${file}.$BACKUP_SUFFIX"
    fi
}

# Function to create symlink safely
safe_symlink() {
    local src="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -e "$src" ]; then
        backup_file "$dest"
        echo "🔗 Linking $desc: $(basename "$dest")"
        ln -sf "$src" "$dest"
    else
        echo "⚠️  Source not found for $desc: $src"
    fi
}

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew already installed"
fi

# Install development tools
echo "🛠️ Installing development tools..."

# Core development tools
brew install --quiet tmux git zsh neovim go jq curl wget

# Applications
echo "📱 Installing applications..."
brew install --cask --quiet ghostty cursor

# Container development (optional)
if ! command -v colima &> /dev/null; then
    echo "🐳 Installing container tools..."
    brew install --quiet colima docker
fi

# Python tools (if Marimo is used)
if ! command -v marimo &> /dev/null; then
    echo "📊 Installing Marimo..."
    brew install --cask --quiet marimo || echo "⚠️  Marimo installation failed, continuing..."
fi

# Clone or update dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📂 Cloning dotfiles repository..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
else
    echo "📂 Updating existing dotfiles repository..."
    cd "$DOTFILES_DIR"
    git pull origin main || git pull origin master || echo "⚠️  Failed to update repository"
    cd - > /dev/null
fi

# Verify dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "❌ Failed to clone dotfiles repository"
    echo "Please check the repository URL: $REPO_URL"
    exit 1
fi

# Create all necessary directories
echo "📁 Creating configuration directories..."
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/marimo"
# Skip work-specific directories
mkdir -p "$HOME/.colima/default"
mkdir -p "$HOME/Library/Application Support/Cursor/User"
mkdir -p "$HOME/.ssh"

# Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Installing Oh My Zsh..."
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "✅ Oh My Zsh already installed"
fi

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "🔌 Installing tmux plugin manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
    echo "✅ tmux plugin manager already installed"
fi

# Create symlinks for all configurations
echo "🔗 Creating configuration symlinks..."

# Shell configurations
safe_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" "Zsh configuration"
safe_symlink "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile" "Zsh profile"

# Git configurations
safe_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig" "Git main config"
safe_symlink "$DOTFILES_DIR/.gitconfig-personal" "$HOME/.gitconfig-personal" "Git personal config"
safe_symlink "$DOTFILES_DIR/.gitignore_global" "$HOME/.gitignore_global" "Git global ignore"

# Terminal and multiplexer
safe_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf" "tmux configuration"
safe_symlink "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config" "Ghostty configuration"

# SSH configuration
safe_symlink "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config" "SSH configuration"

# Editor configurations
safe_symlink "$DOTFILES_DIR/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json" "Cursor settings"
safe_symlink "$DOTFILES_DIR/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json" "Cursor keybindings"

# Neovim setup (symlink entire directory)
if [ -d "$DOTFILES_DIR/nvim" ]; then
    backup_file "$HOME/.config/nvim"
    echo "🔗 Linking Neovim configuration"
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# Container development setup
safe_symlink "$DOTFILES_DIR/colima/colima.yaml" "$HOME/.colima/default/colima.yaml" "Colima configuration"

# Additional tools
safe_symlink "$DOTFILES_DIR/marimo/marimo.toml" "$HOME/.config/marimo/marimo.toml" "Marimo configuration"

# Install Cursor extensions
echo "🧩 Installing Cursor extensions..."
if command -v cursor &> /dev/null; then
    cursor --install-extension vscodevim.vim || echo "⚠️  Failed to install vscodevim.vim"
    cursor --install-extension ms-vscode.go || echo "⚠️  Failed to install ms-vscode.go"
    cursor --install-extension asvetliakov.vscode-neovim || echo "⚠️  Failed to install vscode-neovim"
    
    # Additional useful extensions
    cursor --install-extension bradlc.vscode-tailwindcss || true
    cursor --install-extension esbenp.prettier-vscode || true
    cursor --install-extension ms-python.python || true
else
    echo "⚠️  Cursor not found, skipping extension installation"
fi

# Set up environment variables (basic template only)
echo "📝 Setting up environment variables..."
if [ -f "$DOTFILES_DIR/.env.local" ]; then
    echo "✅ Found .env.local, environment variables will be available"
    # Add sourcing to shell profiles if not already present
    if ! grep -q "source.*\.env\.local" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Load local environment variables" >> "$HOME/.zshrc"
        echo "[ -f \$HOME/.dotfiles/.env.local ] && source \$HOME/.dotfiles/.env.local" >> "$HOME/.zshrc"
    fi
else
    echo "ℹ️  No .env.local found. You can create one from .env.template if needed"
fi

# Set proper SSH permissions if SSH keys exist
if ls "$HOME/.ssh/id_"* >/dev/null 2>&1; then
    echo "🔑 Setting SSH key permissions..."
    chmod 600 "$HOME/.ssh/id_"* 2>/dev/null || true
    chmod 644 "$HOME/.ssh/"*.pub 2>/dev/null || true
    chmod 700 "$HOME/.ssh"
fi

# Start Colima if not running
if command -v colima &> /dev/null; then
    if ! colima status >/dev/null 2>&1; then
        echo "🐳 Starting Colima..."
        colima start || echo "⚠️  Failed to start Colima, you can start it manually later"
    else
        echo "✅ Colima already running"
    fi
fi

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "📋 Manual steps remaining:"
echo "   1. 🔑 SSH Keys:"
echo "      - Copy your SSH private keys to ~/.ssh/"
echo "      - Run: chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub"
echo ""
echo "   2. 🔒 Environment Variables (optional):"
if [ ! -f "$DOTFILES_DIR/.env.local" ]; then
echo "      - Copy: cp $DOTFILES_DIR/.env.template $DOTFILES_DIR/.env.local"
echo "      - Edit .env.local with any environment variables you need"
fi
echo ""
echo "   3. 🔄 Shell Restart:"
echo "      - Restart your terminal or run: exec zsh"
echo ""
echo "   4. 🔌 tmux Plugins:"
echo "      - Start tmux and press prefix + I to install plugins"
echo "      - Default prefix is Ctrl-b"
echo ""
echo "   5. ⚡ Neovim Setup:"
echo "      - Open Neovim, it will automatically install plugins"
echo "      - Wait for initial setup to complete"
echo ""
echo "🎉 Your development environment is ready!"
echo "🔧 All configurations are symlinked - changes to dotfiles repo will apply immediately"
echo ""
echo "📚 Useful commands:"
echo "   - tmux: terminal multiplexer"
echo "   - colima start: start Docker environment"
echo "   - cursor: VS Code-compatible editor with AI"
echo "   - nvim: Neovim editor"
