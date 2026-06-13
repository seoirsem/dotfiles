CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$CONFIG_DIR/../

# Set GITDIR for cluster-wide access
if [ -d "/workspace-vast/$(whoami)/git" ]; then
    export GITDIR="/workspace-vast/$(whoami)/git"
else
    export GITDIR="$HOME/git"
fi

ZSH_DISABLE_COMPFIX=true
ZSH_THEME="powerlevel10k/powerlevel10k"
# Use /workspace-vast for cluster-wide access if it exists
if [ -d "/workspace-vast/$(whoami)/.oh-my-zsh" ]; then
    ZSH=/workspace-vast/$(whoami)/.oh-my-zsh
else
    ZSH=$HOME/.oh-my-zsh
fi

plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)

source $ZSH/oh-my-zsh.sh
source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/p10k.zsh
source $CONFIG_DIR/extras.sh

# UV configuration
# Use /workspace-vast for cluster-wide access if it exists
if [ -d "/workspace-vast/$(whoami)/.local/bin" ]; then
    export PATH="/workspace-vast/$(whoami)/.local/bin:$PATH"
else
    export PATH="$HOME/.local/bin:$PATH"
fi

# NVM configuration
# Use /workspace-vast for cluster-wide access if it exists
if [ -d "/workspace-vast/$(whoami)/.nvm" ]; then
    export NVM_DIR="/workspace-vast/$(whoami)/.nvm"
else
    export NVM_DIR="$HOME/.nvm"
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Option+Arrow word navigation. iTerm2 emits 1;3 (Left Option = "Esc+") or 1;9
# ("Natural Text Editing" preset) for Opt+arrow; neither was bound, so the keys
# did nothing. Bind both forms so Opt+<-/-> jump words regardless of iTerm2 setting.
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey "^[[1;9C" forward-word
bindkey "^[[1;9D" backward-word

# Option+Backspace = delete previous word. "^[^?" (Meta-DEL) and "^W" are bound
# by default; "^[^H" covers terminals whose Backspace sends ^H (BS) not ^? (DEL).
bindkey "^[^?" backward-kill-word
bindkey "^[^H" backward-kill-word

# Fighter jet ASCII art
echo "                             |"
echo "                       --====|====--"
echo "                             |"
echo ""
echo "                         .-\"\"\"\"\"-."
echo "                       .'_________'."
echo "                      /_/_|__|__|_\_\\"
echo "                     ;'-._       _.-';"
echo ",--------------------|    \`-. .-'    |--------------------,"
echo " \`\`\"\"--..__    ___   ;       '       ;   ___    __..--\"\"\`\`"
echo "           \`\"-// \\\\\\.._\\             /_..// \\\\\\\\-\"\`"
echo "              \\\\\\_//    '._       _.'    \\\\\\_//"
echo "               \`\"\`        \`\`---\`\`        \`\"\`"
echo ""
echo ""
echo ""
