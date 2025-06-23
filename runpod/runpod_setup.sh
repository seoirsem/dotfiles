#!/bin/bash

# 1) Setup linux dependencies
su -c 'apt-get update && apt-get install -y sudo'
sudo apt-get install -y less nano htop ncdu nvtop lsof rsync btop jq less vim

# 2) Setup virtual environment
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
uv python install 3.11
uv venv
source .venv/bin/activate
uv pip install ipykernel simple-gpu-scheduler # very useful on runpod with multi-GPUs https://pypi.org/project/simple-gpu-scheduler/
python -m ipykernel install --user --name=venv # so it shows up in jupyter notebooks within vscode

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

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

zsh
export CUDA_VISIBLE_DEVICES=all

# 4) Setup github
echo "To setup github auth, run:"
echo ./scripts/setup_github.sh "murray@seoirse.net" "Seoirse Murray"