# Claude Code Agent Teams + Split Pane 자동 설정 가이드

이 프로젝트는 **Windows에서 Claude Code Agent Teams의 split pane 모드를 설정**하는 자동화 가이드입니다.
사용자가 "설정 시작해줘"라고 하면, 아래 절차를 순서대로 실행합니다.

---

## 시작 조건

사용자가 이 레포를 열고 설정을 요청하면, 먼저 아래를 확인합니다:

```
1. 플랫폼 확인: process.platform === "win32" 인지 확인
   → Windows가 아니면: "이 가이드는 Windows 전용입니다" 안내 후 중단

2. WSL2 설치 여부: `wsl --status` 실행
   → 설치됨: Step 3으로 건너뛰기
   → 미설치: Step 1부터 시작

3. Ubuntu 설치 여부: `wsl -d Ubuntu -- echo ok` 실행
   → 설치됨: Step 3으로 건너뛰기
   → 미설치: Step 2부터 시작
```

---

## 핵심 원칙

### 실행 유형

| 유형 | 예시 | Claude 행동 |
|------|------|------------|
| 🤖 자동 실행 | apt install, npm install | Claude가 직접 실행하고 결과 보고 |
| 👤 사용자 조작 | 관리자 PowerShell, MS Store, 브라우저 인증, 재부팅 | 친절한 안내 메시지 출력 → "완료되면 알려주세요" 대기 |

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

## Part 1: Core Setup (필수)

이 단계들만으로 Agent Teams + split pane이 완전히 작동합니다.

### Step 1: WSL2 설치 (👤 사용자 조작 필요)

**이 단계는 관리자 권한이 필요하여 사용자가 직접 실행해야 합니다.**

사용자에게 AskUserQuestion으로 안내:

```
[Step 1/9] WSL2를 설치해야 합니다.

아래 단계를 따라주세요:

1. Windows 검색창에 "PowerShell" 입력
2. "Windows PowerShell"을 우클릭 → "관리자로 실행"
3. 열린 창에 아래 명령어를 붙여넣고 Enter:

   wsl --install

4. 설치가 완료되면 컴퓨터를 재부팅해주세요
5. 재부팅 후 여기로 돌아와서 "완료"라고 알려주세요
```

사용자가 완료를 알리면 `wsl --status`로 확인 후 다음 단계.

---

### Step 2: Ubuntu 설치 (👤 사용자 조작 필요)

**Microsoft Store에서 수동 설치가 필요합니다.**

사용자에게 AskUserQuestion으로 안내:

```
[Step 2/9] Ubuntu를 설치합니다.

1. Microsoft Store를 열어주세요 (시작 메뉴에서 검색)
2. "Ubuntu"를 검색하세요
3. "Ubuntu" (숫자 없는 최신 버전)을 선택 → "설치" 클릭
4. 설치 완료 후 "열기"를 클릭하세요
5. 사용자 이름과 비밀번호를 설정하세요
   - 사용자 이름: 영문 소문자만 (예: myname)
   - 비밀번호: 간단하게 (매번 sudo 시 입력)
6. 설정이 완료되면 "완료"라고 알려주세요
```

사용자가 완료를 알리면:
```bash
wsl -d Ubuntu -- echo "Ubuntu OK: $(whoami)"
```
사용자 이름 확인 후 다음 단계.

---

### Step 3: 기본 패키지 설치 (🤖 자동 실행)

Claude Code가 직접 실행합니다:

```bash
wsl -d Ubuntu -- bash -c "sudo apt update && sudo apt upgrade -y && sudo apt install -y tmux git curl"
```

확인:
```bash
wsl -d Ubuntu -- bash -c "tmux -V && git --version"
```

---

### Step 4: nvm + Node.js 설치 (🤖 자동 + 👤 터미널 재시작)

**4-1. nvm 설치 (자동):**
```bash
wsl -d Ubuntu -- bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
```

**4-2. 터미널 재시작 안내 (사용자 조작):**

사용자에게 AskUserQuestion으로 안내:

```
[Step 4/9] nvm 설치가 완료되었습니다!

nvm을 사용하려면 터미널을 재시작해야 합니다.
하지만 걱정 마세요 - 제가 다른 방법으로 계속 진행하겠습니다.

(아무 것도 하지 않으셔도 됩니다. "계속"을 눌러주세요)
```

**4-3. Node.js 설치 (자동 - nvm 경로 직접 지정):**
```bash
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm install --lts && node --version"
```

---

### Step 5: Claude Code 설치 (🤖 자동)

```bash
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm install -g @anthropic-ai/claude-code && claude --version"
```

---

### Step 6: Claude Code 인증 (👤 사용자 조작 필요)

사용자에게 AskUserQuestion으로 안내:

```
[Step 6/9] Claude Code 인증이 필요합니다.

WSL Ubuntu 터미널을 열고 아래 명령어를 실행해주세요:

   claude auth login

브라우저가 열리면 Anthropic 계정으로 로그인하세요.
인증이 완료되면 "완료"라고 알려주세요.

(Ubuntu 터미널 여는 법: 시작 메뉴에서 "Ubuntu" 검색 후 클릭)
```

---

### Step 7: Oh My Tmux 설치 (🤖 자동)

```bash
wsl -d Ubuntu -- bash -c "cd ~ && git clone https://github.com/gpakosz/.tmux.git 2>/dev/null; ln -s -f .tmux/.tmux.conf; cp .tmux/.tmux.conf.local . 2>/dev/null; echo 'Oh My Tmux 설치 완료'"
```

마우스 지원 활성화:
```bash
wsl -d Ubuntu -- bash -c "sed -i 's/#set -g mouse on/set -g mouse on/' ~/.tmux.conf.local 2>/dev/null"
```

---

### Step 8: teammateMode 설정 (🤖 자동)

**8-1. 프로젝트 경로 확인:**

사용자에게 AskUserQuestion으로 확인:

```
[Step 8/9] Agent Teams split pane 설정을 적용할 프로젝트 경로를 알려주세요.

WSL Ubuntu 내 경로를 입력해주세요.
(예: ~/my-project, ~/code/my-app)

프로젝트가 아직 없다면 "없음"이라고 답해주세요.
새 디렉토리를 만들어 드리겠습니다.
```

**8-2. 프로젝트 경로가 있는 경우:**
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

**8-3. 프로젝트가 없는 경우 - 새 디렉토리 생성:**

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

**자동 검증:**
```bash
# tmux 확인
wsl -d Ubuntu -- bash -c "tmux -V"

# Node.js 확인
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && node --version"

# Claude Code 확인
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && claude --version"

# teammateMode 확인
wsl -d Ubuntu -- bash -c "cd {프로젝트경로} && cat .claude/settings.local.json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(\"teammateMode:\", d.get(\"teammateMode\",\"없음\"))'"
```

**사용자에게 Core Setup 완료 안내:**

```
Core Setup이 완료되었습니다!

✅ WSL2 + Ubuntu
✅ tmux + Oh My Tmux
✅ Node.js + Claude Code
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

Core Setup 완료 후, 추가 기능을 설정할지 사용자에게 물어봅니다.

**CRITICAL**: 사용자가 dontAsk/bypassPermissions 모드를 사용 중이면, Part 2 전체를 건너뛰고 완료 메시지를 표시하세요.

---

### Option A: 기존 프로젝트 복제 (git clone)

사용자에게 AskUserQuestion으로 확인:

```
[선택 기능 A] 기존 프로젝트를 WSL에 복제하시겠습니까?

Windows에서 사용하던 Claude Code 프로젝트(설정, 코드 등)를
WSL Ubuntu에 git clone으로 가져올 수 있습니다.

→ "예" - git clone할 저장소 URL을 알려주세요
→ "아니오" - 건너뛰기 (나중에 수동으로 가능)
```

**사용자가 "예"를 선택한 경우:**

```
git clone할 저장소 URL을 알려주세요.
(예: https://github.com/username/my-project.git)
```

저장소 URL을 받으면:

```
WSL Ubuntu 터미널에서 아래 명령어를 실행해주세요:

   cd ~ && git clone {사용자가 준 URL}

GitHub 인증이 필요하면:

   gh auth login

→ GitHub.com → HTTPS → Login with a web browser 선택

완료되면 "완료"라고 알려주세요.
```

git 사용자 설정 (자동):
사용자에게 이름/이메일 확인 후:
```bash
wsl -d Ubuntu -- bash -c "git config --global user.name '{이름}' && git config --global user.email '{이메일}'"
```

---

### Option B: ai()/ain() 편의 함수 설치

사용자에게 AskUserQuestion으로 확인:

```
[선택 기능 B] 편의 함수(ai/ain)를 설치하시겠습니까?

이 함수를 설치하면:
- ai 명령어: tmux + Claude Code를 한 번에 시작
- ain <이름>: 이름 지정 세션 시작

매번 tmux → cd → claude를 입력하지 않아도 됩니다.

→ "예" - 편의 함수 설치
→ "아니오" - 건너뛰기
```

**사용자가 "예"를 선택한 경우:**

추가로 auto-push 기능 확인:

```
Claude Code 종료 시 자동으로 git push를 실행하시겠습니까?

이 기능은 Claude Code를 /exit으로 종료할 때:
git add → commit → pull --rebase → push를 자동 실행합니다.

WSL과 GitHub 간 코드를 자동 동기화하는 데 유용합니다.

→ "예" - auto-push 활성화
→ "아니오" - auto-push 없이 기본 함수만 설치
```

`scripts/setup-bashrc.sh`를 WSL에서 실행:

```bash
# auto-push 없이 설치
wsl -d Ubuntu -- bash /mnt/{드라이브}/path/to/scripts/setup-bashrc.sh "{프로젝트경로}"

# auto-push 포함 설치
wsl -d Ubuntu -- bash /mnt/{드라이브}/path/to/scripts/setup-bashrc.sh "{프로젝트경로}" --with-auto-push
```

설치 확인:
```bash
wsl -d Ubuntu -- bash -c "source ~/.bashrc && type ai 2>/dev/null && echo 'ai() 함수 확인됨'"
```

---

### Option C: Windows 자동 동기화 (Task Scheduler)

사용자에게 AskUserQuestion으로 확인:

```
[선택 기능 C] Windows 자동 동기화를 설정하시겠습니까?

이 기능은 Windows에서 매 30분마다 자동으로:
- git pull: WSL에서 push한 변경사항을 Windows로 가져오기
- git push: Windows에서 변경된 파일을 GitHub에 push

WSL과 Windows 양쪽에서 같은 프로젝트를 작업할 때 유용합니다.
(Task Scheduler에 자동 작업이 등록됩니다)

→ "예" - 자동 동기화 설정
→ "아니오" - 건너뛰기
```

**사용자가 "예"를 선택한 경우:**

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
  - Node.js + Claude Code
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

### "nvm: command not found"
Ubuntu 터미널을 완전히 닫고 다시 열어주세요. `source ~/.bashrc`로는 안 될 수 있습니다.

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
