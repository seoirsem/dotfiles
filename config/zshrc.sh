CONFIG_DIR=$(dirname $(realpath ${(%):-%x}))
DOT_DIR=$CONFIG_DIR/../

ZSH_DISABLE_COMPFIX=true
ZSH_THEME="powerlevel10k/powerlevel10k"
ZSH=$HOME/.oh-my-zsh

plugins=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)

source $ZSH/oh-my-zsh.sh
source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/p10k.zsh
source $CONFIG_DIR/extras.sh

# UV configuration
export PATH="$HOME/.local/bin:$PATH"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
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
