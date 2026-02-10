#!/bin/bash
# Claude Code Agent Teams - WSL 패키지 자동 설치 스크립트
# 사용법: bash setup-wsl.sh

set -e

echo "========================================="
echo " Claude Code Agent Teams - WSL Setup"
echo "========================================="
echo ""

# 1. 시스템 업데이트
echo "[1/5] 시스템 패키지 업데이트 중..."
sudo apt update && sudo apt upgrade -y

# 2. 기본 패키지 설치
echo "[2/5] tmux, git, curl 설치 중..."
sudo apt install -y tmux git curl

# 3. nvm 설치
echo "[3/5] nvm (Node Version Manager) 설치 중..."
if [ -d "$HOME/.nvm" ]; then
    echo "  → nvm이 이미 설치되어 있습니다. 건너뜁니다."
else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# nvm 로드
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 4. Node.js LTS 설치
echo "[4/5] Node.js LTS 설치 중..."
nvm install --lts
echo "  → Node.js $(node --version) 설치 완료"

# 5. Claude Code 설치
echo "[5/5] Claude Code 설치 중..."
npm install -g @anthropic-ai/claude-code
echo "  → Claude Code $(claude --version 2>/dev/null || echo '설치 완료') "

# Oh My Tmux 설치
echo ""
echo "[선택] Oh My Tmux 테마 설치 중..."
if [ -d "$HOME/.tmux" ]; then
    echo "  → Oh My Tmux가 이미 설치되어 있습니다."
else
    cd ~ && git clone https://github.com/gpakosz/.tmux.git
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
    # 마우스 지원 활성화
    sed -i 's/#set -g mouse on/set -g mouse on/' ~/.tmux.conf.local 2>/dev/null
    echo "  → Oh My Tmux 설치 완료 (마우스 지원 활성화)"
fi

echo ""
echo "========================================="
echo " 설치 완료!"
echo ""
echo " 다음 단계:"
echo "   1. claude auth login  (인증)"
echo "   2. bash setup-bashrc.sh  (편의 함수 설치)"
echo "   3. ai  (Claude Code 시작!)"
echo "========================================="
