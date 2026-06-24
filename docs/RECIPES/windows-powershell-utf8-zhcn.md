# Recipe: Windows PowerShell 5.1 + Mavis 工具链中文乱码修复

> **创建**: 2026-06-24
> **作者**: meisijiya (Mavis 团队)
> **场景**: 任何 Windows + Mavis v3.0.47 + PowerShell 5.1 + 中文 user
> **问题**: Mavis 工具链跑 PowerShell 命令时输出 CJK 乱码
> **解决**: 修 PowerShell profile + Windows Terminal commandline
> **效果**: `Get-Content UTF-8 文件` 完美显示中文, subagent 收到干净中文 prompt

---

## 背景

```
Mavis 架构 (简化):
  Mavis Code.exe (Electron UI)
    ↓ RPC
  mavis daemon (v3.0.47 后台 Node.js) ← mavis 工具链用 PS 5.1 spawn 子进程跑 bash 命令
    ↓ spawn
  powershell.exe (Windows PowerShell 5.1, hard-code 不可改)
```

**问题链路**:
1. mavis daemon 用 Node.js `child_process.spawn('powershell.exe', ...)` 跑 PowerShell 命令
2. mavis 工具链**默认 system ANSI code page (CP936 / GBK)** 解码 PowerShell stdout
3. UTF-8 字节被 GBK 解码 → 部分字符 OK, 部分 `?` 替换
4. LLM 看到乱码中文 → 不能正常委派中文 task

**症状**:
- `Write-Host "中文测试"` 输出 `���Ĳ���`
- `Get-Content UTF-8文件` 输出部分 `?` 替换
- `[Console]::OutputEncoding` 显示 `Chinese Simplified (GB2312)` 即使 chcp 65001

---

## 已知限制（v0.4.1 必读）

本 recipe **仅修 pwsh 7 (PowerShell 7+) 路径**，对 **Windows PowerShell 5.1 (mavis 工具链默认) 无效**：

- `[Console]::OutputEncoding` 在 PS 5.1 是 `IsReadOnly: True`，profile 无法修改
- mavis 工具链 hardcode `powershell.exe` (PS 5.1) spawn 子进程，不走 pwsh 7
- mavis 委派 task 时仍走 PS 5.1 = 仍 mojibake

**推荐路径**：
1. 用户手开 WT tab → 用 pwsh 7（已修，OutputEncoding.CodePage=65001）
2. mavis 委派场景 → 走 helper script `C:\Users\22923\AppData\Local\Temp\pwsh-c.py`（Python 3 stdout UTF-8 强制）
3. 长期：mavis 工具链改 pwsh 7 spawn（FEEDBACK H-2 — 用户开 issue）

## 修复目标

- **PowerShell 5.1 默认编码** → UTF-8
- **`Get-Content / Set-Content / Out-File`** 默认 encoding → UTF-8
- **Windows Terminal PowerShell profile** 启动时自动 chcp 65001

---

## 步骤 (3 步, 全部需要)

### Step 1: 修 PowerShell profile (链式赋值 bug + 加 UTF-8 设置)

**问题**: 用户常复制粘贴的"PowerShell UTF-8 设置"行用链式赋值, PowerShell **不支持**, 导致只设成功第一项。

**错误写法 (常见)**:
```powershell
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
```

**正确写法** (写到 `C:\Users\22923\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`):

```powershell
# PowerShell Profile - UTF-8 乱码修复 (2026-06-24)

# 1. 切 console code page 到 UTF-8
#    (chcp 不会自动同步到 [Console]::OutputEncoding, 但能改 console)
chcp 65001 | Out-Null

# 2. PowerShell 5.1: 设 $OutputEncoding (影响 Write-Output 等)
#    (不能直接设 [Console]::OutputEncoding - 它是 readonly)
$OutputEncoding = [System.Text.Encoding]::UTF8

# 3. 关键! Get-Content / Set-Content / Out-File 默认按 system ANSI (GBK 936) 读
#    设默认 encoding 为 UTF-8, 不需要每次手动 -Encoding UTF8
$PSDefaultParameterValues['Get-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'

# 4. 加载必要的 .NET 引用 (PowerShell 5.1)
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
```

**写入方法 (避免 PowerShell 5.1 Set-Content UTF-8 损坏 CJK 陷阱)**:
- **不要**用 PowerShell `Set-Content -Encoding utf8` 写 (Set-Content 会损坏中文)
- **用** Python 写: `python -c "open('PATH', 'w', encoding='utf-8').write(content)"`
- **或**用 Read/Write 工具 (写 UTF-8 NO BOM)

### Step 2: 改 Windows Terminal PowerShell profile commandline

**目的**: WT 启动 PowerShell tab 时**先** `chcp 65001` 再启 powershell, 让 `[Console]::OutputEncoding` 同步到 UTF-8。

**修改文件**: `C:\Users\22923\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

**找**: `profiles.list` 数组里 `name == "PowerShell"` 的对象 (GUID 通常是 `{574e775e-4f2a-5b96-ac1e-a2962a402336}`)

**改 `commandline` 字段**为:
```
cmd.exe /K "chcp 65001 >nul && \"C:\\Program Files\\WindowsApps\\Microsoft.PowerShell_7.6.2.0_x64__8wekyb3d8bbwe\\pwsh.exe\" -NoExit"
```

**或 (如果用 PowerShell 5.1)**:
```
cmd.exe /K "chcp 65001 >nul && \"%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -NoExit"
```

**写入方法**:
- **用 Python** (避免 PS 写 JSON 损坏):
  ```python
  import json
  wt = r"C:\Users\22923\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  with open(wt, encoding="utf-8") as f: data = json.load(f)
  for p in data["profiles"]["list"]:
      if p.get("guid") == "{574e775e-4f2a-5b96-ac1e-a2962a402336}":
          p["commandline"] = 'cmd.exe /K "chcp 65001 >nul && ...'
  with open(wt, "w", encoding="utf-8") as f: json.dump(data, f, ensure_ascii=False, indent=4)
  ```
- **或**手动用 VSCode/Notepad 改

### Step 3: 重启 Windows Terminal

**新 tab** 默认用新配置, 加载新 profile。

---

## 验证 (3 步)

### 验证 1: PowerShell 启动后 [Console]::InputEncoding (PS 5.1 OutputEncoding readonly)
```powershell
[Console]::InputEncoding
# 期望: EncodingName: Unicode (UTF-8), CodePage: 65001
# 注: [Console]::OutputEncoding 在 PS 5.1 是 readonly, 改不了
```

### 验证 2: Get-Content 读 UTF-8 文件 (无 BOM)
```powershell
Get-Content "C:\Users\22923\Desktop\AGENTS.md" -TotalCount 3
# 期望: 中文显示完美, 无 ? 替换
```

### 验证 3: 写中文文件
```powershell
"测试中文" | Out-File -FilePath "$env:TEMP\test.txt" -Encoding utf8
Get-Content "$env:TEMP\test.txt"
# 期望: "测试中文" 干净显示
```

---

## 已知限制 (mavis 工具链 bug)

| 问题 | 现状 | 解决 |
|------|------|------|
| mavis 工具链显示某些字符为 `?` (mavis bash tool 内部渲染 bug) | 未修 (需 mavis 官方改 daemon) | **手动开 WT 看 OK**, 用 helper pwsh-c.py 也能修 |
| mavis `mavis agent update --system-prompt` 静默 drop | 已知 (FEEDBACK C-1) | 改用 Edit/Write 工具 |
| mavis daemon systemPrompt CJK → `??` | 已知 (FEEDBACK C-2) | 官方修 |
| `mavis memory append` body 偶发不写 | 已知 (FEEDBACK C-3) | 改用 Read+Write 直接改 MEMORY.md |

完整 bug 列表: `docs/RECIPES/../FEEDBACK-TO-MAVIS-OFFICIAL.md` (上层目录)

---

## Workaround: pwsh-c.py helper (我们已用)

如果**用户想用** 完美中文输出 (Mavis 工具链内), 用这个 helper:

**位置**: `C:\Users\22923\AppData\Local\Temp\pwsh-c.py`

**用法**:
```bash
python "C:\Users\22923\AppData\Local\Temp\pwsh-c.py" '<单行 PowerShell 命令>'
```

**作用**: Python subprocess 调 pwsh 7.6.2 + 设 UTF-8 + chcp 65001, 输出 UTF-8 bytes, 工具链正常显示中文。

**helper 源码**:
```python
import subprocess, sys
PWSH = r"C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.2.0_x64__8wekyb3d8bbwe\pwsh.exe"
UTF8_PREFIX = "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; $OutputEncoding = [System.Text.Encoding]::UTF8; chcp 65001 | Out-Null; "
def pwsh_c(cmd):
    r = subprocess.run([PWSH, "-NoProfile", "-Command", UTF8_PREFIX + cmd],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.stdout: sys.stdout.write(r.stdout)
    if r.stderr: sys.stderr.write(r.stderr)
    return r.returncode
if __name__ == "__main__":
    if len(sys.argv) < 2: sys.exit("Usage: pwsh-c <command>")
    sys.exit(pwsh_c(" ".join(sys.argv[1:])))
```

---

## 相关 issue / 关联文档

- `docs/OPTIMIZATION-v0.4.0-ADR.md` — D-P0-2 / D-P0-6 / D-P0-NEW-3 (skill 体系)
- `docs/FEEDBACK-TO-MAVIS-OFFICIAL.md` — C-5 (工具链 stdout 解码) 等 17 个 daemon bug
- `docs/RECIPES/../MEMORY.md` — 内部 memory 记录

---

## 总结 (3 句话)

1. **Mavis 工具链 hard-code `powershell.exe` 5.1**, 改不了
2. **改 PowerShell profile + WT commandline** 让 PS 5.1 启动时 [Console]::OutputEncoding = UTF-8
3. **Get-Content 默认 UTF-8** + **chcp 65001** 同步 → 中文 OK
