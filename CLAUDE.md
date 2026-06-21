# Claude Code Agent Teams + Split Pane 자동 설정 가이드

이 프로젝트는 **Windows에서 Claude Code Agent Teams의 split pane 모드를 설정**하는 자동화 가이드입니다.
사용자가 "설정 시작해줘"라고 하면, 아래 절차를 순서대로 실행합니다.

---

## 핵심 원칙

### 환경 감지 우선 (CRITICAL)

**모든 단계에서 먼저 이미 설치/설정되어 있는지 확인하고, 되어 있으면 건너뜁니다.**
건너뛸 때는 사용자에게 "[Step N/9] {항목}이 이미 설치되어 있습니다. 건너뜁니다. ✅" 안내.

### 실행 유형 — 반드시 구분하세요 (CRITICAL)

이 가이드에는 두 종류의 코드 블록이 있습니다. **절대 혼동하지 마세요.**

| 표시 | 의미 | Claude 행동 |
|------|------|------------|
| `🤖 실행:` 뒤의 bash 블록 | Claude Code가 직접 실행할 명령어 | Bash 도구로 실행 |
| `📋 사용자에게 전달:` 뒤의 텍스트 블록 | 사용자에게 보여줄 안내문 | AskUserQuestion으로 텍스트 전달만. **절대 실행하지 마세요** |

**⚠️ "📋 사용자에게 전달:" 블록 안의 명령어(wsl --install, 로그인용 claude 실행 등)는 사용자가 직접 입력할 명령어입니다. Claude Code가 실행하면 안 됩니다.**

### 안내 메시지 톤
- 한국어 존댓말, 친근하고 명확
- 단계 번호와 현재 진행 상황 표시
- 구체적으로 무엇을 해야 하는지 설명
- 완료 확인 방법 안내

### 선택 기능 처리 (CRITICAL)
- Optional 단계 진입 전 AskUserQuestion으로 "이 기능을 설정하시겠습니까?" 질문
- **사용자가 질문에 답하지 않는 모드(dontAsk, bypassPermissions 등)를 사용 중이라면, 선택 단계를 건너뛰고 필수 단계만 완료하세요**
- 각 선택 기능이 무엇이고 왜 유용한지 간단히 설명한 후 질문

---

## 시작: 환경 스캔

사용자가 설정을 요청하면, **먼저 현재 환경을 전체 스캔**합니다.

**🤖 아래 명령어들을 순서대로 실행하세요 (실행):**
```bash
# 1. 플랫폼 확인
# process.platform === "win32" 인지 확인
# → Windows가 아니면: "이 가이드는 Windows 전용입니다" 안내 후 중단

# 2. WSL2 확인
wsl --status

# 3. Ubuntu 확인
wsl -d Ubuntu -- echo "ok" 2>/dev/null

# 4. 기본 패키지 확인 (Ubuntu가 있을 때만)
wsl -d Ubuntu -- bash -c "tmux -V 2>/dev/null; git --version 2>/dev/null; curl --version 2>/dev/null | head -1"

# 5. Claude Code 확인 (네이티브 설치 = ~/.local/bin/claude)
wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\"; claude --version 2>/dev/null"

# 6. Node.js 확인 (선택 — Claude Code엔 불필요)
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" 2>/dev/null; node --version 2>/dev/null"

# 7. Oh My Tmux 확인
wsl -d Ubuntu -- bash -c "test -d ~/.tmux && echo 'installed' || echo 'not found'"

# 8. teammateMode 확인
wsl -d Ubuntu -- bash -c "cat ~/.claude/settings.local.json 2>/dev/null || find ~ -maxdepth 3 -path '*/.claude/settings.local.json' -exec cat {} \; 2>/dev/null | head -1"
```

스캔 결과를 사용자에게 보고:

```
환경 스캔 결과:

  WSL2:          ✅ 설치됨 / ❌ 미설치
  Ubuntu:        ✅ 설치됨 / ❌ 미설치
  tmux:          ✅ x.x / ❌ 미설치
  git:           ✅ x.x / ❌ 미설치
  Claude Code:   ✅ x.x.x / ❌ 미설치  (네이티브 설치, Node.js 불필요)
  Node.js:       ✅ vXX.x.x / ⏭️ 선택 (Claude Code엔 불필요)
  Oh My Tmux:    ✅ 설치됨 / ❌ 미설치
  teammateMode:  ✅ tmux / ❌ 미설정

→ Step {첫 번째 미설치 항목}부터 진행합니다.
```

이미 모든 항목이 설치된 경우 → "모든 Core Setup이 완료되어 있습니다!" 안내 후 Part 2로 바로 진행.

---

## Part 1: Core Setup (필수)

이 단계들만으로 Agent Teams + split pane이 완전히 작동합니다.

### Step 1: WSL2 설치 (👤 사용자 조작 필요)

**🤖 환경 감지 (실행):**
```bash
wsl --status
```
- 정상 출력 (기본 버전, 커널 버전 등 표시) → **건너뛰기** ✅
- 에러 또는 미설치 → 아래 진행

**이 단계는 관리자 권한이 필요합니다. Claude Code가 직접 실행할 수 없습니다.**

**📋 사용자에게 전달 (실행 금지 — AskUserQuestion으로 텍스트만 전달):**

```
[Step 1/9] WSL2를 설치해야 합니다.

아래 단계를 따라주세요:

1. Windows 검색창에 "PowerShell" 입력
2. "Windows PowerShell"을 우클릭 → "관리자로 실행"
3. 열린 창에 아래 명령어를 붙여넣고 Enter:

   wsl --install

4. 설치가 완료되면 컴퓨터를 재부팅해주세요

5. ⚠️ 재부팅 후 두 가지 경우가 있습니다:

   [경우 A] Ubuntu 설정 화면이 자동으로 나타나는 경우:
   → 사용자 이름(영문 소문자)과 비밀번호를 설정하세요
   → 설정 완료 후 그 창은 닫아도 됩니다

   [경우 B] 아무 화면도 안 나타나는 경우:
   → 정상입니다! 다음 단계에서 Ubuntu를 별도로 설치합니다

6. 재부팅 후 터미널에서 아래 명령어로 이 세션을 이어서 진행할 수 있습니다:

   claude --resume

7. 세션이 복구되면 "완료"라고 알려주세요
```

**🤖 사용자가 완료를 알리면 (실행):** `wsl --status`로 WSL 설치 확인 후 다음 단계.

---

### Step 2: Ubuntu 설치 (👤 사용자 조작 필요)

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- echo "ok" 2>/dev/null
```
- `ok` 출력 → **건너뛰기** ✅
- 에러 → 아래 진행

**이 단계는 Microsoft Store에서 수동 설치가 필요합니다. Claude Code가 직접 실행할 수 없습니다.**

**📋 사용자에게 전달 (실행 금지 — AskUserQuestion으로 텍스트만 전달):**

```
[Step 2/9] Ubuntu를 설치합니다.

wsl --install로 Ubuntu가 자동 설치되지 않았으므로, Microsoft Store에서 직접 설치합니다.

1. Microsoft Store를 열어주세요 (시작 메뉴에서 검색)
2. "Ubuntu"를 검색하세요
3. "Ubuntu" (숫자 없는 최신 버전)을 선택 → "설치" 클릭
4. 설치 완료 후 "열기"를 클릭하세요
5. 사용자 이름과 비밀번호를 설정하세요
   - 사용자 이름: 영문 소문자만 (예: myname)
   - 비밀번호: 간단하게 (매번 sudo 시 입력)
6. 설정이 완료되면 "완료"라고 알려주세요
```

**🤖 사용자가 완료를 알리면 (실행):**
```bash
wsl -d Ubuntu -- echo "Ubuntu OK: $(whoami)"
```
사용자 이름 확인 후 다음 단계.

---

### Step 3: 기본 패키지 설치 (🤖 자동 실행)

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "tmux -V 2>/dev/null && git --version 2>/dev/null && curl --version 2>/dev/null | head -1"
```
- tmux, git, curl 모두 버전 출력 → **건너뛰기** ✅
- 하나라도 없으면 → 아래 진행 (apt install은 이미 설치된 것은 자동으로 무시하므로 전체 실행 가능)

**🤖 설치 (실행):**
```bash
wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y && sudo apt install -y tmux git curl"
```

**🤖 확인 (실행):**
```bash
wsl -d Ubuntu -- bash -c "tmux -V && git --version"
```

---

### Step 4: Claude Code 설치 (🤖 자동 — 네이티브, Node.js 불필요)

Claude Code는 **네이티브 설치기**로 설치합니다. 단일 바이너리를 `~/.local/bin/claude`에 설치하며 **Node.js가 필요 없습니다** (백그라운드 자동 업데이트 포함). 옛 npm 방식(`npm install -g @anthropic-ai/claude-code`)은 Node.js가 필요했지만 더 이상 권장하지 않습니다.

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\"; claude --version 2>/dev/null"
```
- 버전 출력 → **건너뛰기** ✅
- 에러 또는 출력 없음 → 아래 진행

**🤖 설치 (실행 — 네이티브 설치기):**
```bash
wsl -d Ubuntu -- bash -c "curl -fsSL https://claude.ai/install.sh | bash"
```

**🤖 설치 확인 (실행 — PATH에 ~/.local/bin 추가):**
```bash
wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\"; claude --version && claude doctor 2>/dev/null | head -5"
```

- 네이티브 설치기는 `claude` 바이너리를 `~/.local/bin`에 두고, 셸 rc 파일에 PATH 추가를 시도합니다.
- 새 터미널에서 `claude`가 안 잡히면 `~/.bashrc`에 `export PATH="$HOME/.local/bin:$PATH"`를 추가하라고 안내하세요.

---

### Step 5: (선택) nvm + Node.js 설치 (🤖 자동 — Claude Code엔 불필요)

**Claude Code 네이티브 설치는 Node.js가 필요 없습니다.** 이 단계는 사용자가 별도의 Node 기반 도구(프로젝트 빌드 도구 등)를 쓸 때만 필요한 선택 단계입니다. 필요 없으면 건너뛰어도 Agent Teams + split pane은 완전히 작동합니다.

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" 2>/dev/null; node --version 2>/dev/null"
```
- 버전 출력 (예: `v20.x.x`) → **건너뛰기** ✅
- 에러 또는 출력 없음 → (Node가 필요한 경우에만) 아래 진행

**🤖 5-1. nvm 설치 (실행):**
```bash
wsl -d Ubuntu -- bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash"
```

**📋 5-2. 터미널 재시작 안내 (실행 금지 — AskUserQuestion으로 텍스트만 전달):**

```
[Step 5/9] nvm 설치가 완료되었습니다!

nvm을 사용하려면 터미널을 재시작해야 합니다.
하지만 걱정 마세요 - 제가 다른 방법으로 계속 진행하겠습니다.

(아무 것도 하지 않으셔도 됩니다. "계속"을 눌러주세요)
```

**🤖 5-3. Node.js 설치 (실행 - nvm 경로 직접 지정):**
```bash
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm install --lts && node --version"
```

---

### Step 6: Claude Code 로그인 (👤 사용자 조작 필요)

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\"; test -f ~/.claude/.credentials.json && echo 'LOGGED_IN' || echo 'NOT_LOGGED_IN'"
```
- `LOGGED_IN` 출력 → **건너뛰기** ✅ (이미 로그인됨)
- `NOT_LOGGED_IN` → 아래 진행

**이 단계는 브라우저 로그인이 필요합니다. Claude Code가 직접 실행할 수 없습니다.**

**📋 사용자에게 전달 (실행 금지 — AskUserQuestion으로 텍스트만 전달):**

```
[Step 6/9] Claude Code 로그인이 필요합니다.
(Claude Pro / Max / Team / Enterprise 계정이 필요합니다 — 무료 플랜은 사용할 수 없습니다)

WSL Ubuntu 터미널을 열고 아래 순서대로 진행해주세요:

1. Ubuntu 터미널에서 아래 명령어를 입력하고 Enter:

   claude

2. 첫 실행 시 자동으로 로그인 안내가 나타납니다. 이후 두 가지 경우가 있습니다:

   [경우 A] 브라우저가 자동으로 열리는 경우:
   → Claude.ai 계정으로 로그인하세요
   → 로그인 후 터미널로 돌아오면 성공입니다

   [경우 B] 브라우저가 자동으로 안 열리는 경우 (WSL2에서 흔합니다):
   → 터미널에서 c 키를 누르면 로그인 URL이 복사됩니다
   → Windows 브라우저(Chrome, Edge 등)를 열고 주소창에 붙여넣기(Ctrl+V) 후 Enter
   → 로그인 후 "코드"가 표시되면, 그 코드를 복사해
     터미널의 "Paste code here if prompted" 부분에 붙여넣으세요
     (WSL2·SSH·컨테이너에서는 로컬 콜백이 막혀 코드 입력 방식이 자주 쓰입니다)

3. 로그인이 완료되면 "완료"라고 알려주세요

(Ubuntu 터미널 여는 법: 시작 메뉴에서 "Ubuntu" 검색 후 클릭)
(로그아웃·전환은 Claude Code 안에서 /logout, 상태 확인은 /status)
```

---

### Step 7: Oh My Tmux 설치 (🤖 자동)

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "test -d ~/.tmux && echo 'installed'"
```
- `installed` 출력 → **건너뛰기** ✅
- 출력 없음 → 아래 진행

**🤖 설치 (실행) — 각 명령어를 순서대로 실행:**
```bash
wsl -d Ubuntu -- bash -c "cd ~ && git clone https://github.com/gpakosz/.tmux.git"
```
```bash
wsl -d Ubuntu -- bash -c "ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf"
```
```bash
wsl -d Ubuntu -- bash -c "cp ~/.tmux/.tmux.conf.local ~/"
```

**🤖 마우스 지원 활성화 (실행):**
```bash
wsl -d Ubuntu -- bash -c "grep -q '^set -g mouse on' ~/.tmux.conf.local || sed -i 's/#set -g mouse on/set -g mouse on/' ~/.tmux.conf.local"
```

---

### Step 8: teammateMode 설정 (🤖 자동)

먼저 사용자의 프로젝트 경로를 파악해야 감지가 가능합니다.

**📋 8-1. 프로젝트 경로 확인 (실행 금지 — AskUserQuestion으로 텍스트만 전달):**

```
[Step 8/9] Agent Teams split pane 설정을 적용할 프로젝트 경로를 알려주세요.

WSL Ubuntu 내 경로를 입력해주세요.
(예: ~/my-project, ~/code/my-app)

프로젝트가 아직 없다면 "없음"이라고 답해주세요.
새 디렉토리를 만들어 드리겠습니다.
```

**🤖 8-2. 경로 확인 후 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "cd {경로} && python3 -c \"
import json
try:
    d = json.load(open('.claude/settings.local.json'))
    tm = d.get('teammateMode')
    at = d.get('env',{}).get('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS')
    if tm == 'tmux' and at == '1':
        print('CONFIGURED')
    else:
        print('INCOMPLETE')
except:
    print('NOT_FOUND')
\" 2>/dev/null"
```
- `CONFIGURED` → **건너뛰기** ✅. "teammateMode가 이미 설정되어 있습니다." 안내.
- `INCOMPLETE` 또는 `NOT_FOUND` → 아래 진행

**🤖 프로젝트 경로가 있는 경우 (실행):**
```bash
wsl -d Ubuntu -- bash -c "cd {사용자가 준 경로} && mkdir -p .claude && python3 -c \"
import json, os
path = '.claude/settings.local.json'
d = {}
if os.path.exists(path):
    with open(path) as f:
        d = json.load(f)
d['teammateMode'] = 'tmux'
d.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
print('teammateMode: tmux 설정 완료')
\""
```

**🤖 프로젝트가 없는 경우 - 새 디렉토리 생성 (실행):**

사용자에게 디렉토리 이름 확인 후:
```bash
wsl -d Ubuntu -- bash -c "mkdir -p ~/{디렉토리명}/.claude && cd ~/{디렉토리명} && python3 -c \"
import json
d = {'teammateMode': 'tmux', 'env': {'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS': '1'}}
with open('.claude/settings.local.json', 'w') as f:
    json.dump(d, f, indent=2)
print('teammateMode: tmux 설정 완료')
\""
```

---

### Step 9: 최종 확인 (🤖 자동 + 👤 확인)

**🤖 자동 검증 (실행):**
```bash
# tmux 확인
wsl -d Ubuntu -- bash -c "tmux -V"

# Oh My Tmux 확인
wsl -d Ubuntu -- bash -c "test -d ~/.tmux && echo 'Oh My Tmux: 설치됨' || echo 'Oh My Tmux: 미설치'"

# Claude Code 확인 (네이티브 = ~/.local/bin/claude)
wsl -d Ubuntu -- bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\"; claude --version"

# (선택) Node.js 확인 — Claude Code엔 불필요
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" 2>/dev/null; node --version 2>/dev/null || echo '(Node.js 미설치 — 선택 사항이라 정상)'"

# teammateMode 확인
wsl -d Ubuntu -- bash -c "cd {프로젝트경로} && cat .claude/settings.local.json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(\"teammateMode:\", d.get(\"teammateMode\",\"없음\"))'"
```

**사용자에게 Core Setup 완료 안내:**

```
Core Setup이 완료되었습니다!

✅ WSL2 + Ubuntu
✅ tmux + Oh My Tmux
✅ Claude Code (네이티브 설치, Node.js 불필요)
✅ teammateMode: tmux (split pane 활성화)

🚀 기본 사용 방법:

1. WSL Ubuntu 터미널을 열고:
   tmux new-session -s claude
   cd {프로젝트경로}
   claude

2. Agent Teams가 실행되면 자동으로 split pane이 활성화됩니다

3. tmux pane 전환:
   Ctrl+B → 방향키    ← 다른 에이전트 pane으로 이동
   Ctrl+B → z         ← 현재 pane 전체화면 토글
```

Step 9 완료 후, Part 2 선택 기능 안내로 진행합니다.

---

## Part 2: Optional Features (선택)

Core Setup이 완료되면, 편의 기능을 추가로 설정할 수 있습니다.
각 기능은 독립적이며, 필요한 것만 골라서 설치할 수 있습니다.

**CRITICAL**: 사용자가 dontAsk/bypassPermissions 모드를 사용 중이면, Part 2 전체를 건너뛰고 최종 완료 메시지를 표시하세요.

---

### Step 10: 기존 프로젝트 가져오기 (👤 사용자 선택)

사용자에게 아래 **배경 설명**을 먼저 전달한 후 AskUserQuestion을 호출합니다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[추가 설정 1/3] 프로젝트 가져오기
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

지금 WSL Ubuntu에는 비어 있는 상태입니다.

만약 이미 Windows에서 Claude Code로 작업하던 프로젝트가 있다면,
그 프로젝트를 WSL에 가져올 수 있습니다.

가져오면 좋은 점:
- Windows에서 만든 .claude/ 설정(에이전트, 스킬 등)을 WSL에서도 그대로 사용
- 기존 코드와 CLAUDE.md를 WSL 환경에서 바로 이어서 작업

가져오는 방법은 git clone입니다.
(GitHub 등에 올려둔 저장소가 있어야 합니다)
```

```json
{
  "questions": [{
    "question": "기존 프로젝트를 WSL에 가져오시겠습니까?",
    "header": "프로젝트",
    "multiSelect": false,
    "options": [
      {
        "label": "네, git clone으로 가져올게요",
        "description": "GitHub 등에 올려둔 기존 프로젝트의 URL을 입력하면 WSL Ubuntu에 복제합니다"
      },
      {
        "label": "아니오, 나중에 할게요",
        "description": "지금은 건너뛰고 나중에 수동으로 git clone 할 수 있습니다"
      }
    ]
  }]
}
```

**"네" 선택 시 실행 절차:**

**🤖 10-1. GitHub CLI 설치 확인 (실행):**
```bash
wsl -d Ubuntu -- bash -c "gh --version 2>/dev/null"
```
- 버전 출력 → 건너뛰기
- 없으면 → 설치:
```bash
wsl -d Ubuntu -- bash -c "sudo apt install -y gh"
```

**📋 10-2. GitHub 인증 (실행 금지 — AskUserQuestion으로 텍스트만 전달):**

대부분의 프로젝트는 private 저장소이므로, **git clone 전에 먼저 GitHub 인증**이 필요합니다.

```
[Step 10] GitHub 인증을 먼저 진행합니다.

WSL Ubuntu 터미널에서 아래 명령어를 입력하세요:

   gh auth login

선택지가 순서대로 나타납니다. 아래와 같이 선택하세요:

   ? Where do you use GitHub?  →  GitHub.com  (Enter)
   ? What is your preferred protocol?  →  HTTPS  (Enter)
   ? Authenticate Git with your GitHub credentials?  →  Yes  (Enter)
   ? How would you like to authenticate?  →  Login with a web browser  (Enter)

그러면 화면에 아래처럼 1회용 코드가 표시됩니다:

   ! First copy your one-time code: XXXX-XXXX
   Press Enter to open github.com in your browser...

여기서 Enter를 누르세요.

⚠️ WSL에서는 브라우저가 자동으로 열리지 않는 경우가 많습니다.
   브라우저가 안 열리면 아래 순서대로 진행하세요:

   1. 터미널에 표시된 1회용 코드(XXXX-XXXX)를 메모하세요
   2. Windows에서 직접 브라우저(Chrome, Edge 등)를 열어주세요
   3. 주소창에 아래 URL을 직접 입력하세요:

      https://github.com/login/device

   4. 메모한 코드를 입력하세요
   5. "Authorize github" 버튼을 클릭하세요
   6. WSL 터미널에 "✓ Authentication complete" 메시지가 나오면 성공!

인증이 완료되면 "완료"라고 알려주세요.
```

**📋 10-3. 저장소 URL 확인 (AskUserQuestion으로 질문):**

```
git clone할 저장소 URL을 알려주세요.
(예: https://github.com/username/my-project.git)
```

**🤖 10-4. git clone 실행 (실행):**

저장소 URL을 받으면:
```bash
wsl -d Ubuntu -- bash -c "cd ~ && gh repo clone {사용자가 준 URL}"
```
- `gh repo clone`은 인증된 상태에서 private 저장소도 자동으로 복제합니다.
- 실패 시 fallback: `git clone {URL}`
- 클론된 폴더 이름을 확인하여 기억하세요 (이후 단계에서 사용).

**🤖 10-5. teammateMode 재적용 (실행) — CRITICAL:**

git clone으로 가져온 프로젝트에는 Windows 환경의 `.claude/settings.local.json`이 포함되어 있을 수 있습니다.
WSL tmux 환경에 맞게 **반드시 teammateMode를 다시 설정**해야 합니다.

```bash
wsl -d Ubuntu -- bash -c "cd ~/{클론된 폴더} && mkdir -p .claude && python3 -c \"
import json, os
path = '.claude/settings.local.json'
d = {}
if os.path.exists(path):
    with open(path) as f:
        d = json.load(f)
d['teammateMode'] = 'tmux'
d.setdefault('env', {})['CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS'] = '1'
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
print('teammateMode: tmux 재설정 완료')
\""
```

**🤖 10-6. settings.local.json을 .gitignore에 추가 (실행):**

환경별 설정이 git으로 덮어씌워지는 것을 방지합니다:
```bash
wsl -d Ubuntu -- bash -c "cd ~/{클론된 폴더} && grep -q 'settings.local.json' .gitignore 2>/dev/null || echo '.claude/settings.local.json' >> .gitignore"
```

git 사용자 설정 (자동):
사용자에게 이름/이메일 확인 후:
```bash
wsl -d Ubuntu -- bash -c "git config --global user.name '{이름}' && git config --global user.email '{이메일}'"
```

> **IMPORTANT**: Step 10에서 프로젝트를 클론했다면, 이후 Step 8에서 설정한 경로 대신 **클론된 프로젝트 경로**를 Step 11 이후의 모든 `{프로젝트경로}`로 사용하세요.

---

### Step 11: 실행 편의 함수 설치 (👤 사용자 선택)

**🤖 환경 감지 (실행):**
```bash
wsl -d Ubuntu -- bash -c "grep -q 'Claude Code Agent Teams' ~/.bashrc 2>/dev/null && echo 'installed'"
```
- `installed` 출력 → 사용자에게 "ai()/ain() 편의 함수가 이미 설치되어 있습니다. 건너뛰시겠습니까?" 확인 (재설치 옵션도 제공)
- 출력 없음 → 아래 진행

AskUserQuestion을 호출합니다. **question 필드에 배경 설명을 포함**하여 사용자가 맥락을 이해할 수 있게 합니다:

```json
{
  "questions": [{
    "question": "[추가 설정 2/3] 실행 편의 함수\n\n현재 Claude Code를 split pane으로 시작하려면 매번 3단계가 필요합니다:\n  1. tmux new-session -s claude\n  2. cd ~/my-project\n  3. claude\n\n편의 함수를 설치하면 한 단어로 줄일 수 있습니다:\n\n  ai  → 위 3단계를 한 번에 실행 (기본 세션)\n  ain → 이름 지정 세션. tmux 안에서도 사용 가능\n        예: ain research → 'research'라는 이름의 새 세션\n        tmux 안이면 새 창(window)으로 열림\n\n설치하지 않아도 Agent Teams는 정상 작동합니다.\n\n편의 함수를 설치하시겠습니까?",
    "header": "편의 함수",
    "multiSelect": false,
    "options": [
      {
        "label": "기본 설치 (Recommended)",
        "description": "ai, ain 명령어 추가. Claude Code 종료 후 별도 동작 없음."
      },
      {
        "label": "auto-push 포함 설치",
        "description": "ai, ain 명령어 + Claude Code 종료 시 자동으로 git add → commit → push. 다른 환경(Windows 등)과 자동 동기화됩니다."
      },
      {
        "label": "설치 안 함",
        "description": "매번 tmux → cd → claude를 직접 입력. 나중에 수동 설치 가능."
      }
    ]
  }]
}
```

**🤖 스크립트 경로 확인 (실행):**

이 레포의 `scripts/setup-bashrc.sh`를 WSL에서 실행해야 합니다.
Windows 경로를 WSL 마운트 경로로 변환하세요:
- `C:\path\to\` → `/mnt/c/path/to/`
- 예: `C:\Users\name\claude-agent-teams-setup\scripts\` → `/mnt/c/Users/name/claude-agent-teams-setup/scripts/`

먼저 스크립트 접근 가능 여부 확인:
```bash
wsl -d Ubuntu -- ls /mnt/{변환된 경로}/scripts/setup-bashrc.sh
```

**🤖 "기본 설치" 선택 시 (실행):**

`{WSL프로젝트경로}` = Step 8에서 지정한 경로. Step 10에서 프로젝트를 클론했다면 **클론된 경로**를 사용.

```bash
wsl -d Ubuntu -- bash "/mnt/{변환된 경로}/scripts/setup-bashrc.sh" "{WSL프로젝트경로}"
```

**🤖 "auto-push 포함 설치" 선택 시 (실행):**
```bash
wsl -d Ubuntu -- bash "/mnt/{변환된 경로}/scripts/setup-bashrc.sh" "{WSL프로젝트경로}" --with-auto-push
```

**🤖 설치 확인 (실행):**
```bash
wsl -d Ubuntu -- bash -c "source ~/.bashrc && echo \"AI_PROJECT_DIR=\$AI_PROJECT_DIR\" && type ai 2>/dev/null && echo 'ai() 함수 확인됨'"
```
- `AI_PROJECT_DIR`이 올바른 경로로 표시되는지 확인
- `AI_PROJECT_DIR`이 비어있으면 `setup-bashrc.sh`에 경로가 제대로 전달되지 않은 것 → 재실행

---

### Step 12: Windows ↔ WSL 자동 동기화 (👤 사용자 선택)

**🤖 환경 감지 (실행):**
```bash
schtasks /query /tn "AI-Vault-Auto-Push" 2>nul
```
- 작업이 존재하면 → 사용자에게 "자동 동기화 Task가 이미 등록되어 있습니다. 건너뛰시겠습니까?" 확인
- 에러 (작업 없음) → 아래 진행

사용자에게 아래 **배경 설명**을 먼저 전달한 후 AskUserQuestion을 호출합니다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[추가 설정 3/3] Windows ↔ WSL 자동 동기화
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Windows와 WSL Ubuntu는 파일 시스템이 분리되어 있습니다.
같은 컴퓨터 안이지만, 서로 다른 세계처럼 파일이 별도로 관리됩니다.

  Windows: C:\Users\you\my-project\      ← Windows의 파일
  WSL:     /home/you/my-project/          ← WSL의 파일 (별도 복사본)

만약 Windows에서도 같은 프로젝트를 열어서 작업하거나 (예: Obsidian, VS Code 등),
혹은 WSL에서 작업한 결과를 Windows 쪽에서 바로 보고 싶다면,
양쪽의 파일을 자동으로 맞춰주는 동기화가 필요합니다.

이 기능은 Windows에서 30분마다 자동으로:
  1. GitHub에서 최신 파일 가져오기 (git pull)
  2. Windows에서 변경된 파일 올리기 (git push)

를 실행하여 양쪽을 동기화합니다.

⚠️ WSL에서만 작업하고, Windows 쪽에서는 프로젝트를 열지 않는다면
   이 기능은 필요 없습니다.
```

```json
{
  "questions": [{
    "question": "Windows ↔ WSL 자동 동기화를 설정하시겠습니까?",
    "header": "자동 동기화",
    "multiSelect": false,
    "options": [
      {
        "label": "네, 설정할게요",
        "description": "Windows Task Scheduler에 30분 간격 자동 작업을 등록합니다. Windows에서도 같은 프로젝트를 사용하는 경우 권장합니다."
      },
      {
        "label": "아니오, 필요 없어요",
        "description": "WSL에서만 작업하거나, 필요할 때 수동으로 git pull/push를 실행합니다."
      }
    ]
  }]
}
```

**"네" 선택 시:**

Windows에서의 프로젝트 경로 확인:
```
Windows에서 프로젝트가 있는 경로를 알려주세요.
(예: C:\Users\username\my-project)
```

`scripts/setup-scheduler.ps1`을 실행:
```powershell
powershell -ExecutionPolicy Bypass -File "scripts/setup-scheduler.ps1" -RepoPath "{Windows 프로젝트 경로}"
```

---

### 최종 완료 메시지

모든 선택 기능 처리 후, 설치된 기능에 맞춰 안내:

```
설정이 모두 완료되었습니다!

✅ Core:
  - WSL2 + Ubuntu
  - tmux + Oh My Tmux
  - Claude Code (네이티브 설치, Node.js 불필요)
  - teammateMode: tmux (split pane 활성화)

{Option A 설치 시}
✅ 프로젝트 복제 완료

{Option B 설치 시}
✅ ai()/ain() 편의 함수 설치됨
  → ai 명령어로 바로 시작 가능

{Option C 설치 시}
✅ 자동 동기화 설정 (30분 간격)

🚀 시작하기:
{Option B가 설치된 경우}
  WSL 터미널에서: ai
{Option B가 설치되지 않은 경우}
  WSL 터미널에서:
  tmux new-session -s claude
  cd {프로젝트경로}
  claude
```

---

## 트러블슈팅

### "claude: command not found" (네이티브 설치 후)
네이티브 설치기는 `claude` 바이너리를 `~/.local/bin`에 둡니다. 이 경로가 PATH에 없으면 새 셸에서 못 찾습니다. 새 터미널을 열어보고, 그래도 안 되면 `~/.bashrc`에 아래를 추가 후 `source ~/.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```
설치·구성 상태 점검은 `claude doctor`로 확인할 수 있습니다.

### "nvm: command not found"
nvm/Node.js는 **선택 사항**이며 Claude Code 동작엔 영향이 없습니다. Node가 필요하면 Ubuntu 터미널을 완전히 닫고 다시 열어주세요. `source ~/.bashrc`로는 안 될 수 있습니다.

### "sessions should be nested with care"
tmux 안에서 `ai`를 실행하면 발생합니다. 대신 `ain 세션이름`을 사용하세요.

### git push rejected
다른 환경에서 먼저 push했을 때 발생합니다:
```bash
cd {프로젝트경로} && git pull --rebase && git push
```

### settings.local.json 충돌
```bash
cd {프로젝트경로} && git checkout -- .claude/settings.local.json
```

### WSL 버전 확인
```bash
wsl -d Ubuntu -- cat /proc/version
# "microsoft-standard-WSL2" 포함 확인
```

---

## 설정값 참고

| 설정 | 값 | 위치 |
|------|-----|------|
| teammateMode | `"tmux"` | `.claude/settings.local.json` |
| CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS | `"1"` | `.claude/settings.local.json` > env |
