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
git clone https://github.com/treylom/claude-agent-teams-setup.git
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

# Oh My Tmux
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

## 설치 내용

| 구성 요소 | 설명 |
|-----------|------|
| WSL2 + Ubuntu | Windows에서 Linux 환경 제공 |
| tmux | 터미널 분할 (split pane) |
| Oh My Tmux | tmux 테마 + 마우스 지원 |
| Node.js (nvm) | Claude Code 실행 환경 |
| Claude Code CLI | AI 에이전트 실행 |
| ai()/ain() 함수 | 원클릭 세션 시작 + 자동 git sync |

## 편의 함수

설치 후 WSL에서 사용할 수 있는 함수:

```bash
ai              # tmux + Claude Code 시작 (기본)
ain my-task     # 이름 지정 세션 시작
ain             # tmux 안에서 새 창으로 열기
ai-sync         # 수동 git push
```

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
- GitHub 계정 (저장소 클론용, 선택)

## 파일 구조

```
claude-agent-teams-setup/
├── CLAUDE.md              ← Claude Code 자동 설정 가이드
├── README.md              ← 이 파일
├── scripts/
│   ├── setup-wsl.sh       ← WSL 패키지 자동 설치
│   ├── setup-bashrc.sh    ← 편의 함수 자동 설치
│   └── setup-scheduler.ps1← Windows 자동 동기화 설정
└── LICENSE
```

## FAQ

**Q: macOS에서도 사용할 수 있나요?**
macOS는 기본적으로 tmux를 지원합니다. `brew install tmux`만 하면 됩니다. 이 가이드는 Windows + WSL2 환경 전용입니다.

**Q: VS Code에서 split pane이 안 보여요.**
VS Code 통합 터미널은 tmux split pane을 지원하지 않습니다. WSL Ubuntu 터미널에서 `ai` 명령어로 실행하세요.

**Q: 기존 프로젝트 설정을 가져올 수 있나요?**
네. git clone으로 기존 프로젝트를 WSL에 복사하면 `.claude/` 폴더의 모든 설정(agents, skills, commands)이 자동으로 적용됩니다.

## License

MIT
