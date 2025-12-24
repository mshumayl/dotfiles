# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start (Fresh MacOS)

```bash
curl -fsSL https://raw.githubusercontent.com/mshumayl/dotfiles/main/install.sh | bash
```

Or manually:

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install chezmoi
brew install chezmoi

# Initialize and apply
chezmoi init --apply mshumayl/dotfiles
```

## What's Included

### Configs
- **zsh** - Oh My Zsh with candy-custom theme, zsh-autosuggestions
- **tmux** - vim-tmux-navigator, tpm plugins, custom prefix (`C-\`)
- **neovim** - Managed as [separate repo](https://github.com/mshumayl/nvim)
- **git** - Conditional includes for personal projects
- **ghostty** - Gruvbox Material Dark theme

### Packages (via Brewfile)
- Core: tmux, git, zsh, neovim, go, jq, curl, wget
- Apps: ghostty, marimo

## After Installation

1. **SSH Keys** - Copy to `~/.ssh/` and set permissions:
   ```bash
   chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub
   ```

2. **tmux plugins** - Start tmux, press `prefix + I`

3. **Neovim** - Open nvim to trigger plugin installation

## Day-to-Day Usage

```bash
# Edit a dotfile
chezmoi edit ~/.zshrc

# See pending changes
chezmoi diff

# Apply changes
chezmoi apply

# Pull and apply updates
chezmoi update

# Navigate to source directory
chezmoi cd
```

## Adding New Files

```bash
# Add a file to chezmoi
chezmoi add ~/.some-config

# Add as template (for machine-specific values)
chezmoi add --template ~/.some-config
```

## Archive

Previous bash-based setup preserved in `archive/pre-chezmoi` branch.
