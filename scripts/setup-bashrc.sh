#!/bin/bash
# Claude Code Agent Teams - Bash 편의 함수 설치
# 사용법: bash setup-bashrc.sh <프로젝트경로> [--with-auto-push]
#
# 필수 인자: 프로젝트 경로 (예: ~/my-project)
# 옵션: --with-auto-push → Claude Code 종료 시 자동 git push 활성화

# 인자 파싱
PROJECT_DIR=""
AUTO_PUSH=false

for arg in "$@"; do
    case "$arg" in
        --with-auto-push) AUTO_PUSH=true ;;
        -*) echo "알 수 없는 옵션: $arg"; exit 1 ;;
        *) PROJECT_DIR="$arg" ;;
    esac
done

if [ -z "$PROJECT_DIR" ]; then
    echo "========================================="
    echo " 오류: 프로젝트 경로를 지정해주세요"
    echo ""
    echo " 사용법:"
    echo "   bash setup-bashrc.sh ~/my-project"
    echo "   bash setup-bashrc.sh ~/my-project --with-auto-push"
    echo ""
    echo " --with-auto-push: Claude Code 종료 시 자동으로"
    echo "   git add → commit → pull --rebase → push 실행"
    echo "========================================="
    exit 1
fi

BASHRC="$HOME/.bashrc"
MARKER="# === Claude Code Agent Teams ==="

echo "========================================="
echo " Claude Code Agent Teams - Bash Setup"
echo "========================================="
echo ""
echo "프로젝트 경로: $PROJECT_DIR"
echo "자동 push: $([ "$AUTO_PUSH" = true ] && echo '활성화' || echo '비활성화')"
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

# 브랜치 자동 감지 함수 포함
if [ "$AUTO_PUSH" = true ]; then
    cat >> "$BASHRC" << 'BASHEOF'

# === Claude Code Agent Teams ===

# 프로젝트 경로 (setup-bashrc.sh에서 설정)
# AI_PROJECT_DIR은 아래에서 별도로 설정됨

# 현재 브랜치 자동 감지
_ai_branch() {
  git -C "${AI_PROJECT_DIR}" branch --show-current 2>/dev/null || echo "main"
}

# 내부: git 동기화 함수
_ai_sync() {
  local branch=$(_ai_branch)
  cd ${AI_PROJECT_DIR} && \
    git add -A && \
    git commit -m "WSL-sync: $(date +%Y-%m-%d\ %H:%M)" 2>/dev/null && \
    git pull origin "$branch" --rebase 2>/dev/null && \
    git push origin "$branch" 2>/dev/null
}

# 내부: 세션 시작 전 설정
_ai_setup() {
  local branch=$(_ai_branch)
  cd ${AI_PROJECT_DIR}
  git stash 2>/dev/null
  git pull origin "$branch" --rebase 2>/dev/null
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

# 기본 Claude Code 세션 시작 (auto-push 포함)
ai() {
  _ai_setup
  local proj="${AI_PROJECT_DIR}"
  local branch=$(_ai_branch)
  tmux new-session -s claude "bash -c 'cd $proj && claude; cd $proj && git add -A && git commit -m WSL-sync 2>/dev/null && git pull origin $branch --rebase 2>/dev/null && git push origin $branch 2>/dev/null; exec bash'"
}

# 이름 지정 세션 (tmux 안에서도 사용 가능, auto-push 포함)
ain() {
  local name="${1:-claude-$(date +%H%M)}"
  local proj="${AI_PROJECT_DIR}"
  local branch=$(_ai_branch)
  cd "$proj"
  local cmd="bash -c 'cd $proj && claude; cd $proj && git add -A && git commit -m WSL-sync 2>/dev/null && git pull origin $branch --rebase 2>/dev/null && git push origin $branch 2>/dev/null; exec bash'"
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
else
    cat >> "$BASHRC" << 'BASHEOF'

# === Claude Code Agent Teams ===

# 프로젝트 경로 (setup-bashrc.sh에서 설정)
# AI_PROJECT_DIR은 아래에서 별도로 설정됨

# 내부: 세션 시작 전 설정
_ai_setup() {
  cd ${AI_PROJECT_DIR}
  # teammateMode 자동 설정
  python3 -c "
import json, os
path = '.claude/settings.local.json'
d = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            d = json.load(f)
    except:
        pass
d['teammateMode'] = 'tmux'
d.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null
}

# 기본 Claude Code 세션 시작 (auto-push 없음)
ai() {
  _ai_setup
  local proj="${AI_PROJECT_DIR}"
  tmux new-session -s claude "bash -c 'cd $proj && claude; exec bash'"
}

# 이름 지정 세션 (tmux 안에서도 사용 가능, auto-push 없음)
ain() {
  local name="${1:-claude-$(date +%H%M)}"
  local proj="${AI_PROJECT_DIR}"
  cd "$proj"
  local cmd="bash -c 'cd $proj && claude; exec bash'"
  if [ -n "$TMUX" ]; then
    tmux new-window -n "$name" "$cmd"
  else
    _ai_setup
    tmux new-session -s "$name" "$cmd"
  fi
}

# === End Claude Code ===
BASHEOF
fi

# 프로젝트 경로 환경변수 추가
echo "export AI_PROJECT_DIR=\"$PROJECT_DIR\"" >> "$BASHRC"

echo ""
echo "설치 완료!"
echo ""
echo "사용 가능한 명령어:"
echo "  ai           → tmux + Claude Code 시작"
echo "  ain <이름>   → 이름 지정 세션 시작"
if [ "$AUTO_PUSH" = true ]; then
    echo "  ai-sync      → 수동 git 동기화"
    echo ""
    echo "  [auto-push 활성화]"
    echo "  Claude Code 종료 시 자동으로 git push됩니다."
fi
echo ""
echo "터미널을 재시작하거나 'source ~/.bashrc'를 실행하세요."
