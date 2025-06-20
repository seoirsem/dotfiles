#!/bin/bash

#!/bin/bash

# Input arguments
email=${1:-"murray@seoirse.net"}
name=${2:-"Seoirse Murray"}
github_url=${3:-""}

# 0) Setup git
git config --global user.email "$email"
git config --global user.name "$name"


# Add to your setup script
setup_ssh_access() {
    echo "🔒 Securing SSH access..."
    # Backup current keys
    cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup
    # Create new authorized_keys with only your keys
    cat > ~/.ssh/authorized_keys << 'EOF'
# Your SSH key (from runpod)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBTEPxGu3rom7b9jPh53v6ftHQQx97xmLEyOWXyEUgS3 murray@seoirse.net
# John's SSH key  
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDALrWAPgezK+pQSSpFT5KpeqAT5B9glizzHC5mpM0Zg jpl.hughes288@gmail.com
EOF
    # Set proper permissions
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    
    echo "✅ SSH access limited to specified keys"
}
setup_ssh_access

# 1) Setup SSH key
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "🔑 Generating SSH key..."
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
else
    echo "🔑 SSH key already exists"
fi

echo "📋 Your SSH public key:"
echo "----------------------------------------"
cat ~/.ssh/id_ed25519.pub
echo "----------------------------------------"
echo ""
echo "🌐 Add this key to GitHub: https://github.com/settings/ssh/new"
echo ""

read -p "Have you added the SSH key to GitHub? (y/Y/yes to continue): " response
while [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; do
    echo "Please add the SSH key to GitHub first, then continue."
    read -p "Type 'y', 'Y', or 'yes' after adding the SSH key: " response
done

# Test SSH connection
echo "🧪 Testing SSH connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection successful!"
else
    echo "❌ SSH connection failed. Please check your key setup."
    exit 1
fi
# 2) Project specific setup (if github_url is provided)
if [ -n "$github_url" ]; then
    git clone "$github_url"
    repo_name=$(basename "$github_url" .git)
    cd "$repo_name"
    uv pip install -r requirements.txt
fi