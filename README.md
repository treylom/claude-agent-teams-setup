# Claude Code Agent Teams - Windows Setup

Windows에서 Claude Code의 **Agent Teams (swarm) 모드**와 **tmux split pane**을 설정하는 자동화 가이드입니다.

## Agent Teams란?

Claude Code의 Agent Teams는 여러 AI 에이전트가 동시에 협업하는 모드입니다. tmux split pane을 통해 각 에이전트의 작업을 실시간으로 볼 수 있습니다.

```
┌──────────────────┬──────────────────┐
│ @team-lead       │ @researcher      │
│ Planning...      │ Searching...     │
│                  │                  │
├──────────────────┼──────────────────┤
│ @coder           │ @tester          │
│ Writing code...  │ Running tests... │
│                  │                  │
└──────────────────┴──────────────────┘
```

## 빠른 시작

### Claude Code로 자동 설정 (권장)

```bash
git clone <this-repo-url>
cd claude-agent-teams-setup
claude
# → "설정 시작해줘"라고 입력
```

Claude Code가 CLAUDE.md를 읽고 단계별로 안내합니다. 사용자 조작이 필요한 부분에서는 친절하게 안내 후 대기합니다.

### 수동 설치

<details>
<summary>수동으로 설치하려면 클릭</summary>

#### 1. WSL2 설치 (관리자 PowerShell)
```powershell
wsl --install
# 재부팅 후 Microsoft Store에서 Ubuntu 설치
```

#### 2. WSL Ubuntu에서 실행
```bash
# 기본 패키지
sudo apt update && sudo apt install -y tmux git curl

# Node.js (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# 터미널 재시작 후:
nvm install --lts

# Claude Code
npm install -g @anthropic-ai/claude-code
claude auth login

# Oh My Tmux (선택)
cd ~ && git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
```

#### 3. teammateMode 설정
```bash
cd ~/your-project
mkdir -p .claude
echo '{"teammateMode":"tmux","env":{"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS":"1"}}' > .claude/settings.local.json
```

#### 4. 실행
```bash
tmux new-session -s claude
claude
# Agent Teams 실행 시 자동 split pane!
```

</details>

---

## Core Setup (필수)

자동 설치 시 Claude Code가 수행하는 핵심 단계입니다:

| 단계 | 내용 | 실행 |
|------|------|------|
| WSL2 + Ubuntu | Windows에서 Linux 환경 제공 | 사용자 |
| tmux | 터미널 분할 (split pane) | 자동 |
| Oh My Tmux | tmux 테마 + 마우스 지원 | 자동 |
| Node.js (nvm) | Claude Code 실행 환경 | 자동 |
| Claude Code CLI | AI 에이전트 실행 | 자동 |
| teammateMode 설정 | split pane 활성화 | 자동 |

이것만으로 Agent Teams + split pane이 완전히 작동합니다.

---

## Optional Features (선택)

설치 과정에서 Claude Code가 각 기능을 사용할지 물어봅니다. 필요한 것만 선택하세요.

### 프로젝트 복제 (git clone)

기존 프로젝트(Claude Code 설정, 코드 등)를 WSL 환경으로 가져옵니다.

- **무엇을**: git 저장소를 WSL Ubuntu에 clone
- **왜**: Windows에서 사용하던 `.claude/` 설정(agents, skills, commands)을 WSL에서도 사용하기 위해
- **언제 필요**: 이미 Claude Code 프로젝트가 있는 경우

### ai()/ain() 편의 함수

tmux + Claude Code를 한 번에 시작하는 bash 함수입니다.

- **무엇을**: `~/.bashrc`에 `ai`, `ain` 함수 추가
- **왜**: 매번 `tmux new-session → cd project → claude` 를 입력하지 않아도 됨
- **사용법**:
  ```bash
  ai              # tmux + Claude Code 시작 (기본)
  ain my-task     # 이름 지정 세션 시작
  ain             # tmux 안에서 새 창으로 열기
  ```
- **auto-push 옵션**: `--with-auto-push` 플래그로 설치하면, Claude Code 종료 시 자동으로 `git add → commit → pull --rebase → push`를 실행합니다.

### Windows 자동 동기화 (Task Scheduler)

Windows에서 주기적으로 git pull + push를 실행하여 WSL과 Windows 간 파일을 자동으로 동기화합니다.

- **무엇을**: Windows Task Scheduler에 30분 간격 자동 실행 작업 등록
- **왜**: WSL에서 작업한 내용(git push)을 Windows에서 자동으로 받아오고(git pull), Windows에서 변경된 내용도 자동으로 push
- **동작 흐름**:
  ```
  WSL (exit 시) → git push → GitHub → (30분 주기) git pull → Windows
  Windows (auto-push.ps1) → git push → GitHub → (ai 시작 시) git pull → WSL
  ```
- **언제 필요**: Windows와 WSL 양쪽에서 같은 프로젝트를 작업하는 경우

---

## tmux 키 바인딩

| 키 조합 | 동작 |
|---------|------|
| `Ctrl+B` → 방향키 | 다른 pane으로 이동 |
| `Ctrl+B` → `z` | 현재 pane 전체화면 |
| `Ctrl+B` → `o` | 다음 pane으로 순환 |

## 요구 사항

- Windows 10/11
- 인터넷 연결
- Anthropic 계정 (Claude Code 인증용)

## 파일 구조

```
claude-agent-teams-setup/
├── CLAUDE.md              ← Claude Code 자동 설정 가이드
├── README.md              ← 이 파일
├── scripts/
│   ├── setup-wsl.sh       ← WSL 패키지 자동 설치
│   ├── setup-bashrc.sh    ← 편의 함수 설치 (선택)
│   └── setup-scheduler.ps1← Windows 자동 동기화 설정 (선택)
└── LICENSE
```

## FAQ

**Q: macOS에서도 사용할 수 있나요?**
macOS는 기본적으로 tmux를 지원합니다. `brew install tmux`만 하면 됩니다. 이 가이드는 Windows + WSL2 환경 전용입니다.

**Q: VS Code에서 split pane이 안 보여요.**
VS Code 통합 터미널은 tmux split pane을 지원하지 않습니다. WSL Ubuntu 터미널에서 실행하세요.

**Q: 자동 동기화 없이 사용할 수 있나요?**
네. Core Setup만으로 Agent Teams + split pane이 완전히 작동합니다. 자동 동기화는 Windows와 WSL 양쪽에서 같은 프로젝트를 작업할 때만 필요한 선택 기능입니다.

**Q: 기존 프로젝트를 꼭 가져와야 하나요?**
아닙니다. 프로젝트 없이도 새 디렉토리에서 Claude Code를 시작할 수 있습니다. 설치 과정에서 프로젝트 경로를 물어볼 때 "없음"이라고 답하면 됩니다.

## License

MIT
