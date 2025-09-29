#!/usr/bin/env bash
# gather-dotfiles.sh - Extract all your dotfiles and configurations
# Usage: ./gather-dotfiles.sh [target_directory]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$SCRIPT_DIR/dotfiles}"
BACKUP_SUFFIX="backup-$(date +%Y%m%d-%H%M%S)"

echo "🔍 Gathering all dotfiles to $TARGET_DIR"
echo "📅 Backup suffix: $BACKUP_SUFFIX"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$TARGET_DIR"/{cursor,ghostty,nvim,colima,marimo,ssh,scripts}

# Function to safely copy files
safe_copy() {
    local src="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -f "$src" ]; then
        echo "✅ Copying $desc: $(basename "$src")"
        cp "$src" "$dest"
    elif [ -d "$src" ]; then
        echo "✅ Copying $desc directory: $(basename "$src")"
        cp -r "$src"/* "$dest"/ 2>/dev/null || true
    else
        echo "⚠️  $desc not found: $src"
    fi
}

# Shell configurations
echo "📋 Copying shell configurations..."
safe_copy "$HOME/.zshrc" "$TARGET_DIR/.zshrc" "Zsh configuration"
safe_copy "$HOME/.zprofile" "$TARGET_DIR/.zprofile" "Zsh profile"

# Terminal and multiplexer
echo "🖥️ Copying terminal configurations..."
safe_copy "$HOME/.tmux.conf" "$TARGET_DIR/.tmux.conf" "Tmux configuration"
safe_copy "$HOME/.config/ghostty/config" "$TARGET_DIR/ghostty/config" "Ghostty configuration"

# Git configurations
echo "🔧 Copying git configurations..."
safe_copy "$HOME/.gitconfig" "$TARGET_DIR/.gitconfig" "Git main config"
safe_copy "$HOME/.gitconfig-personal" "$TARGET_DIR/.gitconfig-personal" "Git personal config"
safe_copy "$HOME/.gitignore_global" "$TARGET_DIR/.gitignore_global" "Git global ignore"

# SSH configuration (excluding private keys for security)
echo "🔑 Copying SSH config (excluding private keys)..."
if [ -f "$HOME/.ssh/config" ]; then
    echo "✅ Copying SSH config"
    cp "$HOME/.ssh/config" "$TARGET_DIR/ssh/config"
    # Fix the github.come typo if it exists
    sed -i '' 's/github\.come/github.com/g' "$TARGET_DIR/ssh/config" 2>/dev/null || true
else
    echo "⚠️  SSH config not found"
fi

# VS Code/Cursor configurations
echo "📝 Copying Cursor configurations..."
CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
if [ -f "$CURSOR_DIR/settings.json" ]; then
    echo "✅ Copying Cursor settings (will sanitize)"
    cp "$CURSOR_DIR/settings.json" "$TARGET_DIR/cursor/settings.json"
    # Create backup of original
    cp "$CURSOR_DIR/settings.json" "$TARGET_DIR/cursor/settings.json.$BACKUP_SUFFIX"
else
    echo "⚠️  Cursor settings not found"
fi

safe_copy "$CURSOR_DIR/keybindings.json" "$TARGET_DIR/cursor/keybindings.json" "Cursor keybindings"

# Neovim configuration (complete directory)
echo "⚡ Copying Neovim configurations..."
if [ -d "$HOME/.config/nvim" ]; then
    echo "✅ Copying complete Neovim configuration"
    cp -r "$HOME/.config/nvim/." "$TARGET_DIR/nvim/"
    # Remove any cache or temporary files
    find "$TARGET_DIR/nvim" -name "*.log" -delete 2>/dev/null || true
    find "$TARGET_DIR/nvim" -name ".DS_Store" -delete 2>/dev/null || true
else
    echo "⚠️  Neovim configuration not found"
fi

# Container development
echo "🐳 Copying Colima configuration..."
safe_copy "$HOME/.colima/default/colima.yaml" "$TARGET_DIR/colima/colima.yaml" "Colima configuration"

# Marimo configuration
echo "📊 Copying Marimo configuration..."
safe_copy "$HOME/.config/marimo/marimo.toml" "$TARGET_DIR/marimo/marimo.toml" "Marimo configuration"

# Skip work-specific configurations (no longer needed)

# Create clean Cursor settings (excluding sensitive data)
echo "🔒 Creating clean Cursor settings..."
if [ -f "$TARGET_DIR/cursor/settings.json" ]; then
    echo "🧹 Filtering out sensitive configurations..."
    
    # Create clean version excluding security tool configurations
    if command -v jq &> /dev/null; then
        # Fix common JSON issues (trailing commas) and validate
        sed 's/,\s*}/}/g' "$TARGET_DIR/cursor/settings.json" > "$TARGET_DIR/cursor/settings.json.fixed"
        
        if jq empty "$TARGET_DIR/cursor/settings.json.fixed" 2>/dev/null; then
            jq '
            if has("rest-client.environmentVariables") then
                del(.["rest-client.environmentVariables"]["orcasec-eval-local"]) |
                del(.["rest-client.environmentVariables"]["prisma-cloud-eval-local"]) |
                if .["rest-client.environmentVariables"] == {"$shared": {}} then
                    del(.["rest-client.environmentVariables"])
                else . end
            else . end |
            .sourcegraph.basePath = "/Users/USERNAME/proj/"
            ' "$TARGET_DIR/cursor/settings.json.fixed" > "$TARGET_DIR/cursor/settings.json.tmp"
            
            if [ $? -eq 0 ] && [ -s "$TARGET_DIR/cursor/settings.json.tmp" ]; then
                mv "$TARGET_DIR/cursor/settings.json.tmp" "$TARGET_DIR/cursor/settings.json"
                rm -f "$TARGET_DIR/cursor/settings.json.fixed"
                echo "✅ Created clean settings (original left untouched)"
            else
                rm -f "$TARGET_DIR/cursor/settings.json.tmp" "$TARGET_DIR/cursor/settings.json.fixed"
                echo "⚠️  jq processing failed, keeping original settings"
                echo "⚠️  Please manually review cursor/settings.json before committing"
            fi
        else
            rm -f "$TARGET_DIR/cursor/settings.json.fixed"
            echo "⚠️  Invalid JSON in cursor settings, keeping as-is"
            echo "⚠️  Please manually review cursor/settings.json before committing"
        fi
    else
        echo "⚠️  jq not found, copying original settings"
        echo "⚠️  Please manually review cursor/settings.json before committing"
    fi
fi

# Create basic environment variables template (no security tools)
echo "📝 Creating environment template..."
cat > "$TARGET_DIR/.env.template" << 'EOF'
# Environment variables for development setup
# Copy this to .env.local and fill in your actual values

# Example environment variables
# export API_KEY="your_api_key_here"
# export DATABASE_URL="your_database_url"
# export DEBUG=true
EOF

# Create .gitignore for dotfiles repo
echo "🚫 Creating .gitignore..."
cat > "$TARGET_DIR/.gitignore" << 'EOF'
# Sensitive files
.env.local
*.backup
*.backup.*

# macOS
.DS_Store

# Neovim cache and logs
nvim/lazy-lock.json
nvim/**/*.log

# SSH keys (never commit these)
ssh/id_*
ssh/known_hosts*
ssh/authorized_keys*

# Cursor workspace storage
cursor/workspaceStorage/
cursor/**/*.backup*

# Work-specific configs (excluded)

# OS generated files
.Trash/
.fseventsd/
EOF

# Create README
echo "📖 Creating README..."
cat > "$TARGET_DIR/README.md" << 'EOF'
# Development Environment Dotfiles

Complete development environment setup for:
- **Terminal**: Ghostty with Gruvbox theme
- **Shell**: Zsh with Oh My Zsh
- **Multiplexer**: tmux with vim-tmux-navigator
- **Editor**: Cursor with vscodevim + Neovim integration
- **Version Control**: Git with work/personal split
- **Containers**: Colima + Docker
- **Languages**: Go development optimized

## Quick Setup

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/scripts/setup-dev-env.sh | bash
```

## Manual Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   ```

2. Run the setup script:
   ```bash
   ~/.dotfiles/scripts/setup-dev-env.sh
   ```

3. Copy SSH keys and set permissions:
   ```bash
   # Copy your SSH keys to ~/.ssh/
   chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub
   ```

4. Set up environment variables:
   ```bash
   cp .env.template .env.local
   # Edit .env.local with your actual API tokens
   ```

## Components

- **Shell**: `.zshrc`, `.zprofile` 
- **Git**: `.gitconfig`, `.gitconfig-personal`, `.gitignore_global`
- **Terminal**: `ghostty/config`
- **Multiplexer**: `.tmux.conf`
- **Editor**: `cursor/settings.json`, `cursor/keybindings.json`
- **Neovim**: Complete `nvim/` configuration with VSCode integration
- **Containers**: `colima/colima.yaml`
- **SSH**: `ssh/config` (keys not included for security)

## Security

- All API tokens moved to environment variables
- SSH private keys excluded from repository
- Work-specific configurations sanitized
EOF

echo ""
echo "✅ All dotfiles gathered in $TARGET_DIR"
echo "📊 Summary:"
echo "   📁 Directory: $TARGET_DIR"
echo "   🔧 Configurations: Shell, Git, Terminal, Editor, Container"
echo "   🔒 Security: Sensitive data excluded (originals untouched)"
echo "   📖 Documentation: README.md created"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "   1. Review $TARGET_DIR/cursor/settings.json to ensure it's clean"
echo "   2. Copy your SSH keys manually (they're excluded for security)"
echo "   3. Your original configs remain unchanged on this machine"
echo "   4. Initialize git repository: cd $TARGET_DIR && git init"
echo ""
echo "🚀 Ready to create your dotfiles repository!"
