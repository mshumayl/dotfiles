# Shumayl Dotfiled

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
