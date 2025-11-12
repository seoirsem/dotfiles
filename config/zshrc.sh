CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$CONFIG_DIR/../

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
