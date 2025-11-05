## Installation

Install dependencies (e.g. oh-my-zsh and related plugins), you can specify options to install specific programs: tmux, zsh, note that your dev-vm will already have tmux and zsh installed so you don't need to provide any options in this case, but you may need to provide these if you are installing locally. 

Installation on a mac machine requires homebrew so install this [from here](https://brew.sh/) first if you haven't already.

```bash
# Install just the dependencies (if on dev-vm)
./install.sh
# Install dependencies + tmux & zsh (if local or on linux without tmux or zsh)
./install.sh --tmux --zsh
```

Deploy (e.g. source aliases for .zshrc, apply oh-my-zsh settings etc..)
```bash
# Remote linux machine
./deploy.sh  
# Local mac machine
./deploy.sh --local   
# Include simple vimrc 
./deploy.sh --vim
```

This set of dotfiles uses the powerlevel10k theme for zsh, this makes your terminal look better and adds lots of useful features, e.g. env indicators, git status etc...

Note that as the provided powerlevel10k config uses special icons it is *highly recommended* you install a custom font that supports these icons. A guide to do that is [here](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k). Alternatively you can set up powerlevel10k to not use these icons (but it won't look as good!)

This repo comes with a preconfigured powerlevel10k theme in [`./config/p10k.zsh`](./config/p10k.zsh) but you can reconfigure this by running `p10k configure` which will launch an interactive window. 


When you get to the last two options below
```
Powerlevel10k config file already exists.
Overwrite ~/git/sm-dotfiles/config/p10k.zsh?
# Press y for YES

Apply changes to ~/.zshrc?
# Press n for NO 
```
