#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Target directory defaults to current directory
TARGET_DIR="${1:-.}"

# Remote repository URL for downloading zip if not run locally
REPO_URL="https://github.com/avatar-devid/Better-AI-Security-Skill"
ZIP_URL="${REPO_URL}/archive/refs/heads/main.zip"

echo "🛡️ Installing AI Security Skill..."
echo "Target directory: $(realpath "$TARGET_DIR")"

# Create target directories
mkdir -p "$TARGET_DIR/.skills"

# Check if script is run locally in the repository
if [ -d ".skills/Security" ]; then
    echo "📦 Detected local installation source. Copying files..."
    cp -r .skills/Security "$TARGET_DIR/.skills/"
else
    echo "🌐 Downloading latest Security Skill from GitHub..."
    TEMP_DIR=$(mktemp -d)
    
    # Download zip file
    if command -v curl >/dev/null 2>&1; then
        curl -sSL "$ZIP_URL" -o "$TEMP_DIR/skill.zip"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$ZIP_URL" -O "$TEMP_DIR/skill.zip"
    else
        echo "❌ Error: curl or wget is required to download the files."
        exit 1
    fi

    # Unzip the file
    if command -v unzip >/dev/null 2>&1; then
        unzip -q "$TEMP_DIR/skill.zip" -d "$TEMP_DIR"
    else
        echo "❌ Error: unzip is required to extract the files."
        exit 1
    fi

    # Copy files
    # The zip creates a directory named Better-AI-Security-Skill-main
    SRC_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "Better-AI-Security-Skill-*" | head -n 1)
    if [ -d "$SRC_DIR/.skills/Security" ]; then
        cp -r "$SRC_DIR/.skills/Security" "$TARGET_DIR/.skills/"
    else
        echo "❌ Error: Could not find .skills/Security in the downloaded repository."
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Clean up temp
    rm -rf "$TEMP_DIR"
fi

echo "✅ Copied security modules to $TARGET_DIR/.skills/Security"

# Creating AI Assistant rule files
echo "🤖 Configuring AI Assistant instructions..."

# 1. Cursor Rules
mkdir -p "$TARGET_DIR/.cursor/rules"
cat << 'EOF' > "$TARGET_DIR/.cursor/rules/security.mdc"
---
description: Apply security best practices to code generation and updates
globs: *
---
# Security Rules
Before writing or modifying any code in this project, read and follow the decision tree in:
.skills/Security/Security.md

LOAD only the relevant security modules and apply all loaded rules.
EOF
echo "   - Created .cursor/rules/security.mdc"

# 2. Claude Code
cat << 'EOF' > "$TARGET_DIR/CLAUDE.md"
# CLAUDE.md

## Security Skill
This project uses a hierarchical security skill system. Before implementing code, read:
.skills/Security/Security.md

Follow its decision tree and load the matching security modules. Apply all loaded rules.
EOF
echo "   - Created CLAUDE.md"

# 3. GitHub Copilot
mkdir -p "$TARGET_DIR/.github"
cat << 'EOF' > "$TARGET_DIR/.github/copilot-instructions.md"
# Copilot Instructions

## Security Skill Protocol
This project uses a hierarchical security skill system. Before implementing any feature:

1. Read: .skills/Security/Security.md
2. Evaluate the decision tree and load every matching module.
3. Apply all loaded rules.
EOF
echo "   - Created .github/copilot-instructions.md"

# 4. Windsurf
cat << 'EOF' > "$TARGET_DIR/.windsurfrules"
You have access to a hierarchical Security Skill system.
At the START of every task, read:
.skills/Security/Security.md

Follow the decision tree. LOAD only matching files. Apply every loaded security rule.
EOF
echo "   - Created .windsurfrules"

# 5. Gemini
cat << 'EOF' > "$TARGET_DIR/GEMINI.md"
## Security Skill
Before every implementation task, read:
.skills/Security/Security.md

Follow every LOAD directive and apply every loaded security rule.
EOF
echo "   - Created GEMINI.md"

echo "🎉 AI Security Skill installed successfully!"
echo "AI assistants in this workspace will now automatically follow the security protocols."
