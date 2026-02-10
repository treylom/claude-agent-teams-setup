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

## 단계별 실행 가이드

### Step 1: WSL2 설치 (👤 사용자 조작 필요)

**이 단계는 관리자 권한이 필요하여 사용자가 직접 실행해야 합니다.**

사용자에게 AskUserQuestion으로 안내:

```
[Step 1/12] WSL2를 설치해야 합니다.

아래 단계를 따라주세요:

1. Windows 검색창에 "PowerShell" 입력
2. "Windows PowerShell"을 우클릭 → "관리자로 실행"
3. 열린 창에 아래 명령어를 붙여넣고 Enter:

   wsl --install

4. 설치가 완료되면 컴퓨터를 재부팅해주세요
5. 재부팅 후 여기로 돌아와서 "완료"라고 알려주세요

💡 설치에 약 5-10분 정도 소요됩니다.
```

사용자가 완료를 알리면 `wsl --status`로 확인 후 다음 단계.

---

### Step 2: Ubuntu 설치 (👤 사용자 조작 필요)

**Microsoft Store에서 수동 설치가 필요합니다.**

사용자에게 AskUserQuestion으로 안내:

```
[Step 2/12] Ubuntu를 설치합니다.

1. Microsoft Store를 열어주세요 (시작 메뉴에서 검색)
2. "Ubuntu"를 검색하세요
3. "Ubuntu" (숫자 없는 최신 버전)을 선택 → "설치" 클릭
4. 설치 완료 후 "열기"를 클릭하세요
5. 사용자 이름과 비밀번호를 설정하세요
   - 사용자 이름: 영문 소문자만 (예: myname)
   - 비밀번호: 간단하게 (매번 sudo 시 입력)
6. 설정이 완료되면 "완료"라고 알려주세요

💡 사용자 이름은 나중에 변경하기 어려우니 신중하게 정해주세요.
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
[Step 4/12] nvm 설치가 완료되었습니다!

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
[Step 6/12] Claude Code 인증이 필요합니다.

WSL Ubuntu 터미널을 열고 아래 명령어를 실행해주세요:

   claude auth login

브라우저가 열리면 Anthropic 계정으로 로그인하세요.
인증이 완료되면 "완료"라고 알려주세요.

💡 Ubuntu 터미널 여는 법: 시작 메뉴에서 "Ubuntu" 검색 후 클릭
```

---

### Step 7: GitHub 인증 + 저장소 클론 (👤 사용자 조작 필요)

**7-1. 저장소 URL 확인:**

사용자에게 AskUserQuestion으로 확인:

```
[Step 7/12] 기존 Claude Code 프로젝트를 WSL에 복사합니다.

git clone할 저장소 URL을 알려주세요.
(예: https://github.com/username/my-project.git)

💡 저장소가 없다면 "없음"이라고 답해주세요. 새 프로젝트로 설정합니다.
```

**7-2. 저장소가 있는 경우:**

```
WSL Ubuntu 터미널에서 아래 명령어를 실행해주세요:

   cd ~ && git clone {사용자가 준 URL} AI

GitHub 인증이 필요하면:

   gh auth login

→ GitHub.com → HTTPS → Login with a web browser 선택

완료되면 "완료"라고 알려주세요.
```

**7-3. 저장소가 없는 경우 - 새 프로젝트 설정:**

```bash
wsl -d Ubuntu -- bash -c "mkdir -p ~/AI/.claude && cd ~/AI && git init"
```

**7-4. git 사용자 설정 (자동):**

사용자에게 이름/이메일 확인 후:
```bash
wsl -d Ubuntu -- bash -c "git config --global user.name '{이름}' && git config --global user.email '{이메일}'"
```

---

### Step 8: teammateMode 설정 (🤖 자동)

```bash
wsl -d Ubuntu -- bash -c "cd ~/AI && mkdir -p .claude && python3 -c \"
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

---

### Step 9: tmux 테마 설치 - Oh My Tmux (🤖 자동)

```bash
wsl -d Ubuntu -- bash -c "cd ~ && git clone https://github.com/gpakosz/.tmux.git 2>/dev/null; ln -s -f .tmux/.tmux.conf; cp .tmux/.tmux.conf.local . 2>/dev/null; echo 'Oh My Tmux 설치 완료'"
```

마우스 지원 활성화:
```bash
wsl -d Ubuntu -- bash -c "sed -i 's/#set -g mouse on/set -g mouse on/' ~/.tmux.conf.local 2>/dev/null"
```

---

### Step 10: ai()/ain() 편의 함수 설치 (🤖 자동)

`scripts/setup-bashrc.sh`를 WSL로 복사하여 실행:

```bash
# setup-bashrc.sh를 WSL에 복사
cp scripts/setup-bashrc.sh /tmp/setup-bashrc.sh 2>/dev/null
wsl -d Ubuntu -- bash -c "bash /mnt/c/Users/$(whoami)/OneDrive/Desktop/claude-agent-teams-setup/scripts/setup-bashrc.sh"
```

또는 직접 실행:
```bash
wsl -d Ubuntu -- bash /mnt/c/path/to/scripts/setup-bashrc.sh
```

설치 확인:
```bash
wsl -d Ubuntu -- bash -c "source ~/.bashrc && type ai 2>/dev/null && echo 'ai() 함수 확인됨'"
```

---

### Step 11: Windows 자동 동기화 설정 (🤖 자동 + 👤 확인)

**11-1. auto-push.ps1 생성 (자동):**

저장소가 있는 경우에만 실행. `scripts/setup-scheduler.ps1`을 활용:

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/setup-scheduler.ps1" -RepoPath "C:\Users\{사용자명}\OneDrive\Desktop\AI"
```

**11-2. 결과 안내:**

```
[Step 11/12] 자동 동기화가 설정되었습니다!

- WSL에서 /exit 시: 자동으로 git push
- Windows에서: 매 :00, :30에 자동으로 git pull + push

💡 수동 동기화가 필요하면 WSL에서 ai-sync 명령어를 사용하세요.
```

---

### Step 12: 최종 확인 (🤖 자동 + 👤 확인)

**자동 검증:**
```bash
# tmux 확인
wsl -d Ubuntu -- bash -c "tmux -V"

# Node.js 확인
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && node --version"

# Claude Code 확인
wsl -d Ubuntu -- bash -c "export NVM_DIR=\"\$HOME/.nvm\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && claude --version"

# teammateMode 확인
wsl -d Ubuntu -- bash -c "cd ~/AI && cat .claude/settings.local.json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(\"teammateMode:\", d.get(\"teammateMode\",\"없음\"))'"
```

**사용자에게 최종 안내:**

```
[Step 12/12] 설정이 모두 완료되었습니다! 🎉

✅ WSL2 + Ubuntu
✅ tmux + Oh My Tmux
✅ Node.js + Claude Code
✅ teammateMode: tmux (split pane 활성화)
✅ ai()/ain() 편의 함수
✅ 자동 동기화 (30분 간격)

🚀 사용 방법:

1. WSL Ubuntu 터미널을 열고:
   ai           ← Claude Code 시작 (tmux + split pane)
   ain my-task  ← 이름 지정 세션 시작

2. Agent Teams가 실행되면 자동으로 split pane이 활성화됩니다

3. tmux pane 전환:
   Ctrl+B → 방향키    ← 다른 에이전트 pane으로 이동
   Ctrl+B → z         ← 현재 pane 전체화면 토글

4. 종료: /exit → 자동으로 git push됩니다

즐겁게 사용하세요!
```

---

## 트러블슈팅

### "nvm: command not found"
Ubuntu 터미널을 완전히 닫고 다시 열어주세요. `source ~/.bashrc`로는 안 될 수 있습니다.

### "sessions should be nested with care"
tmux 안에서 `ai`를 실행하면 발생합니다. 대신 `ain 세션이름`을 사용하세요.

### git push rejected
Windows auto-sync가 먼저 push했을 때 발생합니다:
```bash
cd ~/AI && git pull origin master --rebase && git push origin master
```

### settings.local.json 충돌
```bash
cd ~/AI && git checkout -- .claude/settings.local.json
# ai() 함수의 _ai_setup이 teammateMode를 자동 재설정합니다
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
| Task Scheduler 간격 | 30분 (:00, :30) | Windows Task Scheduler |
| auto-push 트리거 | claude /exit 시 | `~/.bashrc` ai()/ain() 함수 |
