# install.ps1
# Set ErrorActionPreference to Stop
$ErrorActionPreference = "Stop"

# Target directory defaults to current directory
$TargetDir = if ($args[0]) { $args[0] } else { "." }
# Get absolute path for target directory
$TargetDir = (Resolve-Path $TargetDir).Path

$RepoUrl = "https://github.com/avatar-devid/Better-AI-Security-Skill"
$ZipUrl = "$RepoUrl/archive/refs/heads/main.zip"

Write-Host "🛡️ Installing AI Security Skill..." -ForegroundColor Green
Write-Host "Target directory: $TargetDir" -ForegroundColor Cyan

# Create target directories
New-Item -ItemType Directory -Force -Path (Join-Path $TargetDir ".skills") | Out-Null

# Define local source path relative to script directory
$LocalSource = Join-Path $PSScriptRoot ".skills\Security"
if (Test-Path $LocalSource) {
    Write-Host "📦 Detected local installation source. Copying files..." -ForegroundColor Yellow
    Copy-Item -Path $LocalSource -Destination (Join-Path $TargetDir ".skills") -Recurse -Force
} else {
    Write-Host "🌐 Downloading latest Security Skill from GitHub..." -ForegroundColor Yellow
    
    # Setup temp path
    $TempDir = Join-Path $env:TEMP ([Guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $TempDir | Out-Null
    $ZipFile = Join-Path $TempDir "skill.zip"
    
    # Download zip
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -UseBasicParsing
    
    # Extract zip
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force
    
    # Copy files
    $SrcDir = Get-ChildItem -Path $TempDir -Directory -Filter "Better-AI-Security-Skill-*" | Select-Object -First 1
    $RemoteSource = Join-Path $SrcDir.FullName ".skills\Security"
    if (Test-Path $RemoteSource) {
        Copy-Item -Path $RemoteSource -Destination (Join-Path $TargetDir ".skills") -Recurse -Force
    } else {
        Write-Error "Could not find .skills\Security in the downloaded repository."
        Remove-Item -Path $TempDir -Recurse -Force
        exit 1
    }
    
    # Clean up temp
    Remove-Item -Path $TempDir -Recurse -Force
}

Write-Host "✅ Copied security modules to $(Join-Path $TargetDir '.skills\Security')" -ForegroundColor Green

# Creating AI Assistant rule files
Write-Host "🤖 Configuring AI Assistant instructions..." -ForegroundColor Cyan

# 1. Cursor Rules
$CursorDir = Join-Path $TargetDir ".cursor\rules"
New-Item -ItemType Directory -Force -Path $CursorDir | Out-Null
$CursorRuleContent = @"
---
description: Apply security best practices to code generation and updates
globs: *
---
# Security Rules
Before writing or modifying any code in this project, read and follow the decision tree in:
.skills/Security/Security.md

LOAD only the relevant security modules and apply all loaded rules.
"@
Set-Content -Path (Join-Path $CursorDir "security.mdc") -Value $CursorRuleContent -Encoding UTF8
Write-Host "   - Created .cursor\rules\security.mdc"

# 2. Claude Code
$ClaudeContent = @"
# CLAUDE.md

## Security Skill
This project uses a hierarchical security skill system. Before implementing code, read:
.skills/Security/Security.md

Follow its decision tree and load the matching security modules. Apply all loaded rules.
"@
Set-Content -Path (Join-Path $TargetDir "CLAUDE.md") -Value $ClaudeContent -Encoding UTF8
Write-Host "   - Created CLAUDE.md"

# 3. GitHub Copilot
$CopilotDir = Join-Path $TargetDir ".github"
New-Item -ItemType Directory -Force -Path $CopilotDir | Out-Null
$CopilotContent = @"
# Copilot Instructions

## Security Skill Protocol
This project uses a hierarchical security skill system. Before implementing any feature:

1. Read: .skills/Security/Security.md
2. Evaluate the decision tree and load every matching module.
3. Apply all loaded rules.
"@
Set-Content -Path (Join-Path $CopilotDir "copilot-instructions.md") -Value $CopilotContent -Encoding UTF8
Write-Host "   - Created .github\copilot-instructions.md"

# 4. Windsurf
$WindsurfContent = @"
You have access to a hierarchical Security Skill system.
At the START of every task, read:
.skills/Security/Security.md

Follow the decision tree. LOAD only matching files. Apply every loaded security rule.
"@
Set-Content -Path (Join-Path $TargetDir ".windsurfrules") -Value $WindsurfContent -Encoding UTF8
Write-Host "   - Created .windsurfrules"

# 5. Gemini
$GeminiContent = @"
## Security Skill
Before every implementation task, read:
.skills/Security/Security.md

Follow every LOAD directive and apply every loaded security rule.
"@
Set-Content -Path (Join-Path $TargetDir "GEMINI.md") -Value $GeminiContent -Encoding UTF8
Write-Host "   - Created GEMINI.md"

Write-Host "🎉 AI Security Skill installed successfully!" -ForegroundColor Green
Write-Host "AI assistants in this workspace will now automatically follow the security protocols." -ForegroundColor Green
