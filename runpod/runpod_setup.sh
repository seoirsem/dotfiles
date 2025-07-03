#!/bin/bash

# 1) Setup linux dependencies
su -c 'apt-get update && apt-get install -y sudo'
sudo apt-get install -y less nano htop ncdu nvtop lsof rsync btop jq less vim xclip

# 2) Setup virtual environment
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
# Add uv to PATH permanently
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
uv python install 3.11
uv venv
source .venv/bin/activate
uv pip install ipykernel simple-gpu-scheduler # very useful on runpod with multi-GPUs https://pypi.org/project/simple-gpu-scheduler/
python -m ipykernel install --user --name=venv # so it shows up in jupyter notebooks within vscode

# Install Claude Code
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
# Add nvm to zsh config permanently
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
\. "$HOME/.nvm/nvm.sh"
nvm install 22
node -v # Should print "v22.17.0".
nvm current # Should print "v22.17.0".
npm -v # Should print "10.9.2".

npm install -g @anthropic-ai/claude-code

# 3) Setup dotfiles and ZSH
mkdir git && cd git
git clone https://github.com/seoirsem/dotfiles.git
cd dotfiles
./install.sh --zsh --tmux
chsh -s /usr/bin/zsh
./deploy.sh
#use ssh - better for later
git remote set-url origin git@github.com:seoirsem/dotfiles.git
cd ..

# Add CUDA environment to zsh config
echo "export CUDA_VISIBLE_DEVICES=all" >> ~/.zshrc
zsh

# 4) Setup github
echo "To setup github auth, run:"
echo ./scripts/setup_github.sh "murray@seoirse.net" "Seoirse Murray"
