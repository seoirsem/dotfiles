#!/bin/bash

# 1) Setup linux dependencies
su -c 'apt-get update && apt-get install -y sudo'
sudo apt-get install -y less nano htop ncdu nvtop lsof rsync btop jq less vim xclip

# 2) Setup virtual environment
# Use /workspace-vast for cluster-wide access if it exists
if [ -d "/workspace-vast/$(whoami)" ]; then
    export UV_INSTALL_DIR="/workspace-vast/$(whoami)/.local/bin"
    mkdir -p "$UV_INSTALL_DIR"
else
    export UV_INSTALL_DIR="$HOME/.local/bin"
fi
curl -LsSf https://astral.sh/uv/install.sh | sh
source $UV_INSTALL_DIR/env
# Add uv to PATH permanently
echo "export PATH=\"$UV_INSTALL_DIR:\$PATH\"" >> ~/.zshrc
export PATH="$UV_INSTALL_DIR:$PATH"
uv python install 3.11
uv venv
source .venv/bin/activate
uv pip install ipykernel simple-gpu-scheduler # very useful on runpod with multi-GPUs https://pypi.org/project/simple-gpu-scheduler/
python -m ipykernel install --user --name=venv # so it shows up in jupyter notebooks within vscode

# Install Claude Code
# Use /workspace-vast for cluster-wide access if it exists
if [ -d "/workspace-vast/$(whoami)" ]; then
    export NVM_DIR="/workspace-vast/$(whoami)/.nvm"
else
    export NVM_DIR="$HOME/.nvm"
fi
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
# Add nvm to zsh config permanently
echo "export NVM_DIR=\"$NVM_DIR\"" >> ~/.zshrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
\. "$NVM_DIR/nvm.sh"
nvm install 22
node -v # Should print "v22.17.0".
nvm current # Should print "v22.17.0".
npm -v # Should print "10.9.2".

npm install -g @anthropic-ai/claude-code

# 3) Setup dotfiles and ZSH
# Use /workspace-vast for cluster-wide access if it exists
if [ -d "/workspace-vast/$(whoami)" ]; then
    DOTFILES_DIR="/workspace-vast/$(whoami)/git/dotfiles"
else
    DOTFILES_DIR="$HOME/git/dotfiles"
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    mkdir -p $(dirname "$DOTFILES_DIR")
    git clone https://github.com/seoirsem/dotfiles.git "$DOTFILES_DIR"
else
    echo "Dotfiles already exist at $DOTFILES_DIR, skipping clone..."
fi
cd "$DOTFILES_DIR"
./install.sh --zsh --tmux
chsh -s /usr/bin/zsh
./deploy.sh
#use ssh - better for later
git remote set-url origin git@github.com:seoirsem/dotfiles.git
cd ..

git config pull.rebase true

# Add CUDA auto-detection and editor config to zsh config
cat >> ~/.zshrc << 'EOF'
# Auto-detect available GPUs and set CUDA_VISIBLE_DEVICES
if command -v nvidia-smi &> /dev/null; then
    export CUDA_VISIBLE_DEVICES=$(nvidia-smi --list-gpus | awk '{print NR-1}' | paste -sd,)
fi
export EDITOR=vim
EOF
zsh

# 4) Setup github
git config pull.rebase true
echo "To setup github auth, run:"
echo ./scripts/setup_github.sh "murray@seoirse.net" "Seoirse Murray"
