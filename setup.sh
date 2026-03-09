#!/bin/bash
# =============================================
# Claude Starter Kit — Setup Script (Mac/Linux)
#
# Claude Code 안에서 실행하도록 설계됨
# 비대화형: 플래그로 설치 항목 선택
#
# Usage:
#   ./setup.sh --all                          # Install everything
#   ./setup.sh --pick claude,superclaude      # Select components
#   ./setup.sh --pick mcp,perms              # MCP + Permissions only
#   ./setup.sh --list                         # Show available components
# =============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# --- Colors ---
blue() { echo -e "\n\033[34m$1\033[0m"; }
green() { echo -e "  \033[32mOK\033[0m $1"; }
yellow() { echo -e "  \033[33m!!\033[0m $1"; }
red() { echo -e "  \033[31mXX\033[0m $1"; }

# --- Defaults ---
ALL=false
LIST=false
PICK=""
PERM_PRESET="power"

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) ALL=true; shift ;;
        --list) LIST=true; shift ;;
        --pick) PICK="$2"; shift 2 ;;
        --perm-preset) PERM_PRESET="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

COMPONENTS="claude superclaude mcp perms skills rules"

# --- List mode ---
if $LIST; then
    echo ""
    echo "========================================"
    echo "  Claude Starter Kit - Available Components"
    echo "========================================"
    echo ""
    echo "  claude       — Claude Code (npm install)"
    echo "  superclaude  — SuperClaude Framework (GitHub clone + uv install)"
    echo "  mcp          — MCP Servers (context7, playwright, sequential, github, firebase)"
    echo "  perms        — Permissions (bypassPermissions + tool allow list)"
    echo "  skills       — Skills (pdf, docx, mermaid, error-tracking, etc.)"
    echo "  rules        — AI Collaboration Rules + Security Coding + Git Workflow"
    echo ""
    echo "Usage:"
    echo "  ./setup.sh --all                        # Install everything"
    echo "  ./setup.sh --pick claude,mcp,perms      # Select components"
    echo "  ./setup.sh --pick perms --perm-preset balanced"
    echo ""
    echo "Permission Presets: power (default), balanced, safe"
    echo ""
    exit 0
fi

# --- Determine targets ---
if $ALL; then
    IFS=' ' read -ra TARGETS <<< "$COMPONENTS"
elif [ -n "$PICK" ]; then
    IFS=',' read -ra TARGETS <<< "$PICK"
else
    echo ""
    echo "Usage:"
    echo "  ./setup.sh --all                    # Install everything"
    echo "  ./setup.sh --pick claude,mcp,perms  # Select components"
    echo "  ./setup.sh --list                   # Show available"
    echo ""
    exit 0
fi

TOTAL=${#TARGETS[@]}
STEP=0

echo ""
echo "========================================"
echo "  Claude Starter Kit — Installing"
echo "  Components: ${TARGETS[*]}"
echo "========================================"

contains() { for t in "${TARGETS[@]}"; do [ "$t" = "$1" ] && return 0; done; return 1; }

# =============================================
# CLAUDE CODE
# =============================================
if contains "claude"; then
    STEP=$((STEP+1))
    blue "[$STEP/$TOTAL] Claude Code"

    if ! command -v node &>/dev/null; then
        yellow "Node.js not found. Install it first:"
        echo "    brew install node  (Mac)"
        echo "    sudo apt install nodejs npm  (Linux)"
        exit 1
    fi

    if ! command -v claude &>/dev/null; then
        echo "  Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code
        green "Claude Code installed: $(claude --version)"
    else
        green "Claude Code already installed: $(claude --version)"
    fi
fi

# =============================================
# SUPERCLAUDE
# =============================================
if contains "superclaude"; then
    STEP=$((STEP+1))
    blue "[$STEP/$TOTAL] SuperClaude Framework"

    if ! command -v uv &>/dev/null; then
        echo "  Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
    green "uv $(uv --version)"

    SC_DIR="$HOME/SuperClaude_Framework"
    if ! command -v superclaude &>/dev/null; then
        if [ ! -d "$SC_DIR" ]; then
            echo "  Cloning SuperClaude..."
            git clone https://github.com/SuperClaude-Org/SuperClaude_Framework.git "$SC_DIR"
        fi
        cd "$SC_DIR"
        uv tool install --editable ".[dev]"
        cd "$SCRIPT_DIR"
        green "SuperClaude installed"
    else
        green "SuperClaude already installed: $(superclaude --version)"
    fi

    superclaude install 2>/dev/null || yellow "superclaude install skipped"
fi

# =============================================
# MCP SERVERS
# =============================================
if contains "mcp"; then
    STEP=$((STEP+1))
    blue "[$STEP/$TOTAL] MCP Servers (global scope)"

    EXISTING=$(claude mcp list 2>&1 || true)

    add_mcp() {
        local name=$1; local cmd=$2; shift 2; local args="$*"
        if echo "$EXISTING" | grep -q "$name"; then
            echo "  - $name (already registered, skip)"
            return
        fi
        claude mcp add -s user "$name" -- $cmd $args 2>/dev/null && green "MCP added: $name (global)" || yellow "MCP add failed: $name"
    }

    add_mcp "context7" "npx" "-y" "@upstash/context7-mcp@latest"
    add_mcp "playwright" "npx" "@anthropic-ai/mcp-playwright@latest"
    add_mcp "sequential-thinking" "npx" "-y" "@anthropic-ai/mcp-sequential-thinking"
    add_mcp "firebase" "npx" "-y" "firebase-tools@latest" "mcp"

    # GitHub MCP (requires token)
    if echo "$EXISTING" | grep -q "github"; then
        echo "  - github (already registered, skip)"
    else
        GH_TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN:-}"
        if [ -n "$GH_TOKEN" ]; then
            claude mcp add -s user -e "GITHUB_PERSONAL_ACCESS_TOKEN=$GH_TOKEN" github -- npx -y @anthropic-ai/mcp-github 2>/dev/null && green "MCP added: github (global)" || yellow "MCP add failed: github"
        else
            yellow "github MCP requires GITHUB_PERSONAL_ACCESS_TOKEN — set it first"
            echo "    export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx"
        fi
    fi
fi

# =============================================
# PERMISSIONS
# =============================================
if contains "perms"; then
    STEP=$((STEP+1))
    blue "[$STEP/$TOTAL] Permissions ($PERM_PRESET preset)"

    mkdir -p "$CLAUDE_DIR"

    PRESET_FILE="$SCRIPT_DIR/permissions/$PERM_PRESET.json"
    DST="$CLAUDE_DIR/settings.json"

    if [ ! -f "$PRESET_FILE" ]; then
        red "Preset file not found: $PRESET_FILE"
    else
        if [ -f "$DST" ]; then
            BACKUP="$DST.backup.$(date +%Y%m%d%H%M%S)"
            cp "$DST" "$BACKUP"
            yellow "Existing settings backed up: $BACKUP"
        fi
        cp "$PRESET_FILE" "$DST"
        green "Permissions set ($PERM_PRESET)"
    fi
fi

# =============================================
# SKILLS
# =============================================
if contains "skills"; then
    STEP=$((STEP+1))
    blue "[$STEP/$TOTAL] Skills"

    SKILLS_SRC="$SCRIPT_DIR/skills"
    SKILLS_DST="$CLAUDE_DIR/commands"
    mkdir -p "$SKILLS_DST"

    if [ -d "$SKILLS_SRC" ]; then
        COUNT=0
        for item in "$SKILLS_SRC"/*/; do
            [ -d "$item" ] || continue
            name=$(basename "$item")
            mkdir -p "$SKILLS_DST/$name"
            cp -r "$item"* "$SKILLS_DST/$name/" 2>/dev/null || true
            echo "  - /$name"
            COUNT=$((COUNT+1))
        done
        for item in "$SKILLS_SRC"/*.md; do
            [ -f "$item" ] || continue
            cp "$item" "$SKILLS_DST/"
            echo "  - $(basename "$item")"
            COUNT=$((COUNT+1))
        done
        green "$COUNT skills installed"
    else
        yellow "No skills directory found in kit"
    fi
fi

# =============================================
# RULES
# =============================================
if contains "rules"; then
    STEP=$((STEP+1))
    blue "[$STEP/$TOTAL] AI Collaboration Rules"

    RULES_SRC="$SCRIPT_DIR/rules"
    RULES_DST="$CLAUDE_DIR/rules"
    mkdir -p "$RULES_DST"

    if [ -d "$RULES_SRC" ]; then
        cp "$RULES_SRC"/*.md "$RULES_DST/" 2>/dev/null
        COUNT=$(ls "$RULES_SRC"/*.md 2>/dev/null | wc -l)
        green "$COUNT rule files installed"
    fi
fi

# =============================================
# Verification
# =============================================
echo ""
echo "========================================"
echo "  Verification"
echo "========================================"

PASS=0; CHECKS=0

check() {
    CHECKS=$((CHECKS+1))
    if eval "$1" &>/dev/null; then green "$2"; PASS=$((PASS+1)); else yellow "$2 — not found"; fi
}

contains "claude" && check "command -v claude" "Claude Code"
contains "superclaude" && check "command -v superclaude" "SuperClaude"
contains "superclaude" && check "command -v uv" "uv"
contains "perms" && check "test -f '$CLAUDE_DIR/settings.json'" "Permissions"
contains "skills" && check "test -d '$CLAUDE_DIR/commands'" "Skills directory"
contains "rules" && check "test -d '$CLAUDE_DIR/rules'" "Rules directory"

if contains "mcp"; then
    echo ""
    echo "  MCP Servers:"
    claude mcp list 2>/dev/null || true
fi

echo ""
echo "========================================"
echo "  Done! ($PASS/$CHECKS checks passed)"
echo "========================================"
echo ""
