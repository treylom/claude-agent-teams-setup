#!/bin/bash
# Claude Code Agent Teams - WSL 패키지 자동 설치 스크립트
# 사용법: bash setup-wsl.sh
#
# 설치 항목:
#   - tmux            (터미널 분할 / split pane)
#   - Oh My Tmux      (tmux 테마 + 마우스 지원)
#   - Claude Code     (네이티브 설치 — Node.js 불필요)
#   - (선택) nvm + Node.js — Claude Code엔 불필요, Node 도구가 필요한 사용자만

set -euo pipefail

echo "========================================="
echo " Claude Code Agent Teams - WSL Setup"
echo "========================================="
echo ""

# 1. 시스템 업데이트
echo "[1/5] 시스템 패키지 업데이트 중..."
# set -e 안전: && 한 줄로 묶으면 앞 명령(update) 실패가 가려질 수 있어 별도 라인으로 분리.
sudo apt update
sudo apt upgrade -y

# 2. 기본 패키지 설치 (tmux, git, curl)
echo "[2/5] tmux, git, curl 설치 중..."
if command -v tmux >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    echo "  → tmux, git, curl이 이미 설치되어 있습니다. 건너뜁니다."
else
    # apt install은 이미 설치된 패키지는 자동으로 무시하므로 전체 실행 안전
    sudo apt install -y tmux git curl
fi
echo "  → tmux $(tmux -V 2>/dev/null || echo '미설치')"

# 3. Claude Code 설치 (네이티브 — Node.js 불필요)
echo "[3/5] Claude Code (네이티브) 설치 중..."

# 3-0. PATH 영속성 — 네이티브 설치기는 ~/.local/bin 에 바이너리를 둔다.
#      ① ~/.bashrc 에 idempotent append(이미 있으면 skip) → 새 터미널에서 'claude' 인식.
#      ② claude 설치/검증 *전에* 현재 셸 PATH 에도 즉시 반영.
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -qsF "$PATH_LINE" "$HOME/.bashrc"; then
    {
        echo ""
        echo "# Claude Code (네이티브 설치) — ~/.local/bin 경로 추가 (setup-wsl.sh)"
        echo "$PATH_LINE"
    } >> "$HOME/.bashrc"
    echo "  → ~/.bashrc 에 ~/.local/bin PATH 추가"
fi
# 현재 셸에도 즉시 반영 (아래 command -v claude 검증이 새로 설치한 바이너리를 보도록).
export PATH="$HOME/.local/bin:$PATH"

if command -v claude >/dev/null 2>&1; then
    echo "  → Claude Code가 이미 설치되어 있습니다. 건너뜁니다. ($(claude --version 2>/dev/null))"
else
    # 공식 네이티브 설치기. 단일 바이너리를 ~/.local/bin/claude 에 설치하고 백그라운드 자동 업데이트.
    # 옛 npm 방식(npm install -g @anthropic-ai/claude-code)과 달리 Node.js가 필요 없음.
    # pipefail(상단 set -euo pipefail) 덕에 curl 다운로드 실패가 더 이상 가려지지 않는다.
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        echo "  ❌ Claude Code 설치기 실행 실패 (다운로드 또는 설치 단계). 네트워크/권한을 확인 후 재시도하세요." >&2
        exit 1
    fi
    # 새로 깐 바이너리가 현재 셸에서 즉시 잡히도록 PATH 재반영(설치기가 다른 위치를 쓸 수도 있어 안전망).
    export PATH="$HOME/.local/bin:$PATH"
    # 설치가 실제로 됐는지 검증 — 설치기가 조용히 실패하는 경우를 명확히 잡는다.
    if ! command -v claude >/dev/null 2>&1; then
        echo "  ❌ 설치기는 끝났으나 'claude' 명령을 찾을 수 없습니다." >&2
        echo "     새 터미널을 열어 'claude --version' 을 확인하거나, ~/.local/bin 설치 여부를 점검하세요." >&2
        exit 1
    fi
    echo "  → Claude Code 설치 완료 ($(claude --version 2>/dev/null || echo '버전 확인은 새 터미널에서'))"
fi

# 4. (선택) nvm + Node.js — Claude Code엔 불필요.
#    Claude Code 네이티브 설치는 Node.js가 필요 없다. 이 단계는 사용자가 별도의
#    Node 기반 도구(예: 프로젝트 빌드 도구)를 쓸 때만 필요하므로 선택 사항으로 둔다.
#    동작: Node 가 없으면 nvm/Node LTS 설치를 *자동 시도*하되, 어디서 실패하든
#    핵심 설치(tmux/oh-my-tmux/claude)를 막지 않도록 전부 비치명적(non-fatal)으로 처리한다.
#    (Claude Code 사용자는 이 단계를 건너뛰어도 무방하다.)
echo "[4/5] (선택) nvm + Node.js 설치 중... (Claude Code엔 불필요, 실패해도 무시)"
# nvm 설치/로딩은 비치명적이어야 한다. set -euo pipefail 환경에서 nvm.sh 소싱이
# 미설정 변수(set -u)나 중간 실패(set -e)로 스크립트 전체를 죽이지 않도록,
# 모든 nvm 작업을 set +u 서브셸 안에 격리하고 분기 끝에 `|| true` 로 마감한다.
install_node_via_nvm() {
    # 서브셸: set +u 로 nvm.sh 의 미설정 변수 참조를 허용하고, 실패해도 호출부로 비치명 전파.
    (
        set +u
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install --lts
    )
}

if command -v node >/dev/null 2>&1; then
    echo "  → Node.js가 이미 설치되어 있습니다. 건너뜁니다. ($(node --version 2>/dev/null))"
elif [ -d "$HOME/.nvm" ]; then
    echo "  → nvm이 이미 설치되어 있습니다. Node.js LTS 설치를 시도합니다."
    if install_node_via_nvm; then
        echo "  → Node.js LTS 설치 시도 완료"
    else
        echo "  ⚠️  Node.js 설치 실패(선택 단계라 무시). 새 터미널에서 'nvm install --lts'로 재시도하세요."
    fi
else
    # pipefail 환경: curl 다운로드 실패 시 install.sh 가 빈 입력으로 bash 에 들어가도 if 가 잡는다.
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash; then
        if install_node_via_nvm; then
            echo "  → Node.js $(node --version 2>/dev/null || echo '(새 터미널에서 확인)') 설치 완료"
        else
            echo "  ⚠️  Node.js 설치 실패(선택 단계라 무시). 새 터미널에서 'nvm install --lts'로 재시도하세요."
        fi
    else
        echo "  ⚠️  nvm 설치 실패(선택 단계라 무시). Claude Code 사용엔 영향 없습니다."
    fi
fi

# 5. Oh My Tmux 설치 (tmux 테마 + 마우스 지원)
#    idempotency: ~/.tmux 존재 여부로 전부 건너뛰면(coarse) 심링크/로컬설정이 깨져도 복구 안 됨.
#    → clone 만 [ -d ~/.tmux ] 로 가드하고, 심링크·로컬설정·마우스 옵션은 *항상* idempotent 보장.
echo "[5/5] Oh My Tmux 테마 설치 중..."

# (a) clone 은 없을 때만.
if [ -d "$HOME/.tmux" ]; then
    echo "  → ~/.tmux 가 이미 있습니다. clone 건너뜀(설정만 점검)."
else
    git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    echo "  → Oh My Tmux clone 완료."
fi

# (b) .tmux.conf 심링크는 항상 보장(-f 로 idempotent; 이미 올바르면 그대로 덮어씀).
ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"

# (c) .tmux.conf.local 은 없을 때만 복사(사용자 수정 보존).
if [ ! -f "$HOME/.tmux.conf.local" ]; then
    cp "$HOME/.tmux/.tmux.conf.local" "$HOME/"
    echo "  → .tmux.conf.local 복사 완료."
fi

# (d) 마우스 지원 활성화 — 이미 켜져 있으면 그대로(항상 idempotent 점검).
if [ -f "$HOME/.tmux.conf.local" ]; then
    grep -q '^set -g mouse on' "$HOME/.tmux.conf.local" 2>/dev/null || \
        sed -i 's/#set -g mouse on/set -g mouse on/' "$HOME/.tmux.conf.local" 2>/dev/null || true
fi
echo "  → Oh My Tmux 설치/점검 완료 (심링크·로컬설정·마우스 지원 보장)"

echo ""
echo "========================================="
echo " 설치 완료!"
echo ""
echo " 다음 단계:"
echo "   1. 새 터미널을 열거나 'source ~/.bashrc' 실행 (PATH 반영)"
echo "   2. claude        (실행 후 브라우저 안내로 로그인)"
echo "   3. bash setup-bashrc.sh <프로젝트경로>  (편의 함수 설치)"
echo "   4. ai            (tmux + Claude Code 시작!)"
echo "========================================="
