# =============================================
# Claude Starter Kit — Setup Script (Windows)
#
# Claude Code 안에서 실행하도록 설계됨
# 비대화형: 플래그로 설치 항목 선택
#
# 사용법:
#   .\setup.ps1 -All                          # 전체 설치
#   .\setup.ps1 -Pick claude,superclaude      # 선택 설치
#   .\setup.ps1 -Pick mcp,perms              # MCP + Permissions만
#   .\setup.ps1 -List                         # 설치 가능 항목 보기
# =============================================

param(
    [switch]$All,
    [switch]$List,
    [string]$Pick = "",
    [ValidateSet("power", "balanced", "safe")]
    [string]$PermPreset = "power"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

# --- 출력 헬퍼 ---
function Write-Step($num, $total, $msg) { Write-Host "`n[$num/$total] $msg" -ForegroundColor Blue }
function Write-Ok($msg) { Write-Host "  OK $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  !! $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  XX $msg" -ForegroundColor Red }

# --- 설치 가능 항목 ---
$Components = @{
    "claude"       = "Claude Code (npm install)"
    "superclaude"  = "SuperClaude Framework (GitHub clone + uv install)"
    "mcp"          = "MCP Servers (context7, playwright, sequential, github, firebase)"
    "perms"        = "Permissions (bypassPermissions + tool allow list)"
    "skills"       = "Skills (pdf, docx, mermaid, error-tracking, etc.)"
    "rules"        = "AI Collaboration Rules + Security Coding + Git Workflow"
}

# --- List 모드 ---
if ($List) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Claude Starter Kit - Available Components"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    foreach ($key in $Components.Keys | Sort-Object) {
        Write-Host "  $key" -ForegroundColor Yellow -NoNewline
        Write-Host " — $($Components[$key])"
    }
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Gray
    Write-Host "  .\setup.ps1 -All                        # Install everything"
    Write-Host "  .\setup.ps1 -Pick claude,mcp,perms      # Select components"
    Write-Host "  .\setup.ps1 -Pick perms -PermPreset balanced  # Choose permission level"
    Write-Host ""
    Write-Host "Permission Presets:" -ForegroundColor Gray
    Write-Host "  power     — All tools auto-allowed, bypassPermissions (default)"
    Write-Host "  balanced  — Read/search auto, build/test auto, edits need approval"
    Write-Host "  safe      — Read-only auto, everything else needs approval"
    Write-Host ""
    exit 0
}

# --- 설치 대상 결정 ---
$targets = @()
if ($All) {
    $targets = @("claude", "superclaude", "mcp", "perms", "skills", "rules")
} elseif ($Pick) {
    $targets = $Pick -split "," | ForEach-Object { $_.Trim().ToLower() }
    foreach ($t in $targets) {
        if (-not $Components.ContainsKey($t)) {
            Write-Fail "Unknown component: $t"
            Write-Host "  Available: $($Components.Keys -join ', ')"
            exit 1
        }
    }
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Claude Starter Kit"
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\setup.ps1 -All                    # Install everything"
    Write-Host "  .\setup.ps1 -Pick claude,mcp,perms  # Select components"
    Write-Host "  .\setup.ps1 -List                   # Show available components"
    Write-Host ""
    exit 0
}

$Total = $targets.Count
$Step = 0

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Starter Kit — Installing"
Write-Host "  Components: $($targets -join ', ')"
Write-Host "========================================" -ForegroundColor Cyan

# =============================================
# CLAUDE CODE
# =============================================
if ($targets -contains "claude") {
    $Step++
    Write-Step $Step $Total "Claude Code"

    if (!(Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Warn "Node.js not found. Installing..."
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    }

    if (!(Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing Claude Code..." -ForegroundColor Yellow
        npm install -g @anthropic-ai/claude-code
        Write-Ok "Claude Code installed: $(claude --version)"
    } else {
        Write-Ok "Claude Code already installed: $(claude --version)"
    }
}

# =============================================
# SUPERCLAUDE
# =============================================
if ($targets -contains "superclaude") {
    $Step++
    Write-Step $Step $Total "SuperClaude Framework"

    # uv 설치 확인
    if (!(Get-Command uv -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing uv..." -ForegroundColor Yellow
        Invoke-RestMethod https://astral.sh/uv/install.ps1 | Invoke-Expression
        $env:PATH = "$env:USERPROFILE\.local\bin;$env:PATH"
    }
    Write-Ok "uv $(uv --version)"

    # SuperClaude 클론 + 설치
    $scDir = Join-Path $env:USERPROFILE "SuperClaude_Framework"
    if (!(Get-Command superclaude -ErrorAction SilentlyContinue)) {
        if (!(Test-Path $scDir)) {
            Write-Host "  Cloning SuperClaude..." -ForegroundColor Yellow
            git clone https://github.com/SuperClaude-Org/SuperClaude_Framework.git $scDir
        }
        Push-Location $scDir
        uv tool install --editable ".[dev]"
        Pop-Location
        Write-Ok "SuperClaude installed"
    } else {
        Write-Ok "SuperClaude already installed: $(superclaude --version)"
    }

    # SuperClaude commands 설치
    try {
        superclaude install 2>$null
        Write-Ok "SuperClaude commands installed"
    } catch {
        Write-Warn "superclaude install skipped (already installed)"
    }
}

# =============================================
# MCP SERVERS
# =============================================
if ($targets -contains "mcp") {
    $Step++
    Write-Step $Step $Total "MCP Servers (global scope)"

    $mcpServers = @(
        @{ Name = "context7"; Cmd = "npx"; Args = "-y @upstash/context7-mcp@latest" }
        @{ Name = "playwright"; Cmd = "npx"; Args = "@anthropic-ai/mcp-playwright@latest" }
        @{ Name = "sequential-thinking"; Cmd = "npx"; Args = "-y @anthropic-ai/mcp-sequential-thinking" }
        @{ Name = "github"; Cmd = "npx"; Args = "-y @anthropic-ai/mcp-github"; Env = "GITHUB_PERSONAL_ACCESS_TOKEN" }
        @{ Name = "firebase"; Cmd = "npx"; Args = "-y firebase-tools@latest mcp" }
    )

    $existing = claude mcp list 2>&1

    foreach ($srv in $mcpServers) {
        if ($existing -match $srv.Name) {
            Write-Host "  - $($srv.Name) (already registered, skip)" -ForegroundColor Gray
            continue
        }

        $envFlag = ""
        if ($srv.Env) {
            $tokenVal = [System.Environment]::GetEnvironmentVariable($srv.Env, "User")
            if (!$tokenVal) { $tokenVal = $env:($srv.Env) }
            if ($tokenVal) {
                $envFlag = "-e `"$($srv.Env)=$tokenVal`""
            } else {
                Write-Warn "$($srv.Name) requires $($srv.Env) — set it first, then re-run"
                Write-Host "    [System.Environment]::SetEnvironmentVariable(`"$($srv.Env)`", `"your-token`", `"User`")" -ForegroundColor Gray
                continue
            }
        }

        $addCmd = "claude mcp add -s user $envFlag $($srv.Name) -- $($srv.Cmd) $($srv.Args)"
        try {
            Invoke-Expression $addCmd 2>$null
            Write-Ok "MCP added: $($srv.Name) (global)"
        } catch {
            Write-Warn "MCP add failed: $($srv.Name) — $_"
        }
    }
}

# =============================================
# PERMISSIONS
# =============================================
if ($targets -contains "perms") {
    $Step++
    Write-Step $Step $Total "Permissions ($PermPreset preset)"

    if (!(Test-Path $ClaudeDir)) { New-Item -ItemType Directory -Path $ClaudeDir | Out-Null }

    $presetFile = Join-Path $ScriptDir "permissions\$PermPreset.json"
    $dstSettings = Join-Path $ClaudeDir "settings.json"

    if (!(Test-Path $presetFile)) {
        Write-Fail "Preset file not found: $presetFile"
    } else {
        if (Test-Path $dstSettings) {
            $backup = "$dstSettings.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Copy-Item $dstSettings $backup -Force
            Write-Warn "Existing settings backed up: $backup"
        }

        # 기존 settings.json이 있으면 병합, 없으면 복사
        if (Test-Path $dstSettings) {
            try {
                $existing = Get-Content $dstSettings -Raw -Encoding UTF8 | ConvertFrom-Json
                $preset = Get-Content $presetFile -Raw -Encoding UTF8 | ConvertFrom-Json

                # permissions.allow 병합
                $existingAllow = @()
                if ($existing.permissions -and $existing.permissions.allow) {
                    $existingAllow = @($existing.permissions.allow)
                }
                $presetAllow = @($preset.permissions.allow)
                $merged = @($existingAllow + $presetAllow | Select-Object -Unique)

                $existing.permissions.allow = $merged
                if ($preset.permissions.defaultMode) {
                    $existing.permissions.defaultMode = $preset.permissions.defaultMode
                }

                $existing | ConvertTo-Json -Depth 10 | Set-Content $dstSettings -Encoding UTF8
                Write-Ok "Permissions merged ($PermPreset)"
            } catch {
                Copy-Item $presetFile $dstSettings -Force
                Write-Ok "Permissions set ($PermPreset) — merge failed, used preset directly"
            }
        } else {
            Copy-Item $presetFile $dstSettings -Force
            Write-Ok "Permissions set ($PermPreset)"
        }
    }
}

# =============================================
# SKILLS
# =============================================
if ($targets -contains "skills") {
    $Step++
    Write-Step $Step $Total "Skills"

    $skillsSource = Join-Path $ScriptDir "skills"
    $skillsDest = Join-Path $ClaudeDir "commands"

    if (!(Test-Path $skillsDest)) { New-Item -ItemType Directory -Path $skillsDest | Out-Null }

    if (Test-Path $skillsSource) {
        $skillFolders = Get-ChildItem $skillsSource -Directory
        $skillFiles = Get-ChildItem $skillsSource -File -Filter "*.md"
        $count = 0

        foreach ($folder in $skillFolders) {
            $dest = Join-Path $skillsDest $folder.Name
            if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
            Copy-Item "$($folder.FullName)\*" $dest -Force -Recurse
            $count++
            Write-Host "  - /$($folder.Name)" -ForegroundColor Gray
        }

        foreach ($file in $skillFiles) {
            Copy-Item $file.FullName $skillsDest -Force
            $count++
            Write-Host "  - $($file.Name)" -ForegroundColor Gray
        }

        Write-Ok "$count skills installed"
    } else {
        Write-Warn "No skills directory found in kit"
    }
}

# =============================================
# RULES
# =============================================
if ($targets -contains "rules") {
    $Step++
    Write-Step $Step $Total "AI Collaboration Rules"

    $rulesSource = Join-Path $ScriptDir "rules"
    $rulesDest = Join-Path $ClaudeDir "rules"

    if (!(Test-Path $rulesDest)) { New-Item -ItemType Directory -Path $rulesDest | Out-Null }

    if (Test-Path $rulesSource) {
        $ruleFiles = Get-ChildItem $rulesSource -Filter "*.md"
        Copy-Item "$rulesSource\*.md" $rulesDest -Force
        Write-Ok "$($ruleFiles.Count) rule files installed"
        $ruleFiles | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    }
}

# =============================================
# 검증
# =============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification"
Write-Host "========================================" -ForegroundColor Cyan

$pass = 0; $total = 0

function Test-Item($condition, $name) {
    $script:total++
    if (& $condition) { Write-Ok $name; $script:pass++ }
    else { Write-Warn "$name — not found" }
}

if ($targets -contains "claude") {
    Test-Item { Get-Command claude -ErrorAction SilentlyContinue } "Claude Code"
}
if ($targets -contains "superclaude") {
    Test-Item { Get-Command superclaude -ErrorAction SilentlyContinue } "SuperClaude"
    Test-Item { Get-Command uv -ErrorAction SilentlyContinue } "uv"
}
if ($targets -contains "perms") {
    Test-Item { Test-Path (Join-Path $ClaudeDir "settings.json") } "Permissions"
}
if ($targets -contains "skills") {
    Test-Item { Test-Path (Join-Path $ClaudeDir "commands") } "Skills directory"
}
if ($targets -contains "rules") {
    Test-Item { Test-Path (Join-Path $ClaudeDir "rules") } "Rules directory"
}
if ($targets -contains "mcp") {
    Write-Host ""
    Write-Host "  MCP Servers:" -ForegroundColor Yellow
    claude mcp list
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Done! ($pass/$total checks passed)"
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
