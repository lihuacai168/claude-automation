#!/bin/bash
# deploy-claude-automation.sh

echo "=== Claude Code 24小时自动化系统一键部署 ==="

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}请使用root用户运行此脚本${NC}"
   exit 1
fi

# 创建脚本目录
mkdir -p /tmp/claude-automation
cd /tmp/claude-automation

# 创建各个子脚本
cat > install-dependencies.sh << 'EOF'
#!/bin/bash
echo "=== 系统依赖安装脚本 ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y tmux screen curl wget git vim htop
echo "系统依赖安装完成！"
EOF

cat > install-nodejs.sh << 'EOF'
#!/bin/bash
echo "=== 安装Node.js 22 ==="
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
echo "Node.js 22安装完成！"
EOF

cat > install-claude-code.sh << 'EOF'
#!/bin/bash
echo "=== 离线安装Claude Code ==="
wget -q https://pub-7c3a1b7d65a64aa2bcea1b0eedd6d63a.r2.dev/anthropic-ai-claude-code-1.0.31.tgz
npm install -g anthropic-ai-claude-code-1.0.31.tgz
rm anthropic-ai-claude-code-1.0.31.tgz
claude --version
echo "Claude Code安装完成！"
EOF

cat > setup-github.sh << 'EOF'
#!/bin/bash
echo "=== 配置GitHub集成 ==="
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install -y gh
echo "GitHub CLI安装完成！"
EOF

# 设置执行权限
chmod +x *.sh

# 执行安装
echo -e "${GREEN}开始安装系统依赖...${NC}"
./install-dependencies.sh

echo -e "${GREEN}开始安装Node.js...${NC}"
./install-nodejs.sh

echo -e "${GREEN}开始安装Claude Code...${NC}"
./install-claude-code.sh

echo -e "${GREEN}开始配置GitHub...${NC}"
./setup-github.sh

# 创建用户
echo -e "${GREEN}创建用户cc...${NC}"
useradd -m -s /bin/bash cc
echo "请设置用户cc的密码："
passwd cc

# 切换到cc用户并配置
echo -e "${GREEN}配置用户环境...${NC}"
su - cc << 'EOF'
# 生成SSH密钥
ssh-keygen -t ed25519 -C "claude-automation@example.com" -f ~/.ssh/github_key -N 
