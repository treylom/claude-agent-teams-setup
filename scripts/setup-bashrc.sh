#!/bin/bash
# Claude Code Agent Teams - Bash 편의 함수 설치
# 사용법: bash setup-bashrc.sh [프로젝트경로]
#
# 기본 프로젝트 경로: ~/AI

PROJECT_DIR="${1:-$HOME/AI}"
BASHRC="$HOME/.bashrc"
MARKER="# === Claude Code Agent Teams ==="

echo "========================================="
echo " Claude Code Agent Teams - Bash Setup"
echo "========================================="
echo ""
echo "프로젝트 경로: $PROJECT_DIR"
echo ""

# 이미 설치된 경우 확인
if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    echo "이미 설치되어 있습니다. 덮어쓸까요? (y/N)"
    read -r answer
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        echo "취소되었습니다."
        exit 0
    fi
    # 기존 블록 제거
    sed -i "/$MARKER/,/# === End Claude Code ===/d" "$BASHRC"
fi

cat >> "$BASHRC" << 'BASHEOF'

# === Claude Code Agent Teams ===

# 내부: git 동기화 함수
_ai_sync() {
  cd ${AI_PROJECT_DIR:-~/AI} && \
    git add -A && \
    git commit -m "WSL-sync: $(date +%Y-%m-%d\ %H:%M)" 2>/dev/null && \
    git pull origin master --rebase 2>/dev/null && \
    git push origin master 2>/dev/null
}

# 내부: 세션 시작 전 설정
_ai_setup() {
  cd ${AI_PROJECT_DIR:-~/AI}
  git stash 2>/dev/null
  git pull origin master --rebase 2>/dev/null
  git stash pop 2>/dev/null
  # teammateMode 자동 설정
  python3 -c "
import json, os, subprocess
path = '.claude/settings.local.json'
d = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            d = json.load(f)
    except:
        try:
            o = subprocess.check_output(['git','show','HEAD:' + path]).decode()
            d = json.loads(o)
        except:
            pass
d['teammateMode'] = 'tmux'
d.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null
}

# 기본 Claude Code 세션 시작
ai() {
  _ai_setup
  local proj="${AI_PROJECT_DIR:-$HOME/AI}"
  tmux new-session -s claude "bash -c 'cd $proj && claude; cd $proj && git add -A && git commit -m WSL-sync 2>/dev/null && git pull origin master --rebase 2>/dev/null && git push origin master 2>/dev/null; exec bash'"
}

# 이름 지정 세션 (tmux 안에서도 사용 가능)
ain() {
  local name="${1:-claude-$(date +%H%M)}"
  local proj="${AI_PROJECT_DIR:-$HOME/AI}"
  cd "$proj"
  local cmd="bash -c 'cd $proj && claude; cd $proj && git add -A && git commit -m WSL-sync 2>/dev/null && git pull origin master --rebase 2>/dev/null && git push origin master 2>/dev/null; exec bash'"
  if [ -n "$TMUX" ]; then
    tmux new-window -n "$name" "$cmd"
  else
    _ai_setup
    tmux new-session -s "$name" "$cmd"
  fi
}

# 수동 동기화
alias ai-sync='_ai_sync'

# === End Claude Code ===
BASHEOF

# 프로젝트 경로가 기본값이 아닌 경우 환경변수 추가
if [ "$PROJECT_DIR" != "$HOME/AI" ]; then
    echo "export AI_PROJECT_DIR=\"$PROJECT_DIR\"" >> "$BASHRC"
fi

echo ""
echo "설치 완료!"
echo ""
echo "사용 가능한 명령어:"
echo "  ai           → tmux + Claude Code 시작"
echo "  ain <이름>   → 이름 지정 세션 시작"
echo "  ai-sync      → 수동 git 동기화"
echo ""
echo "터미널을 재시작하거나 'source ~/.bashrc'를 실행하세요."
