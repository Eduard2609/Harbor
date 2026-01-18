# Version management script for Harbor
# Usage: .\tools\version.ps1 [show|bump-patch|bump-minor|bump-major]

param(
    [Parameter(Position=0)]
    [ValidateSet("show", "bump-patch", "bump-minor", "bump-major")]
    [string]$Action = "show"
)

$RootDir = Split-Path -Parent $PSScriptRoot
$CargoToml = Join-Path $RootDir "Cargo.toml"
$PyProjectToml = Join-Path $RootDir "pyproject.toml"

function Get-Version {
    $content = Get-Content $CargoToml -Raw
    if ($content -match 'version\s*=\s*"([^"]+)"') {
        return $Matches[1]
    }
    throw "Version not found in Cargo.toml"
}

function Set-Version {
    param([string]$NewVersion)
    
    # Update Cargo.toml
    $cargoContent = Get-Content $CargoToml -Raw
    $cargoContent = $cargoContent -replace '(version\s*=\s*")[^"]+(")', "`${1}$NewVersion`$2"
    Set-Content $CargoToml $cargoContent -NoNewline
    
    # Update pyproject.toml
    $pyContent = Get-Content $PyProjectToml -Raw
    $pyContent = $pyContent -replace '(version\s*=\s*")[^"]+(")', "`${1}$NewVersion`$2"
    Set-Content $PyProjectToml $pyContent -NoNewline
    
    Write-Host "Updated version to $NewVersion" -ForegroundColor Green
    Write-Host "  - Cargo.toml (workspace)" -ForegroundColor Gray
    Write-Host "  - pyproject.toml" -ForegroundColor Gray
}

function Bump-Version {
    param([string]$BumpType)
    
    $current = Get-Version
    $parts = $current -split '\.'
    
    if ($parts.Count -ne 3) {
        throw "Invalid version format: $current"
    }
    
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    
    switch ($BumpType) {
        "major" { $newVersion = "$($major + 1).0.0" }
        "minor" { $newVersion = "$major.$($minor + 1).0" }
        "patch" { $newVersion = "$major.$minor.$($patch + 1)" }
    }
    
    Set-Version $newVersion
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Review changes: git diff" -ForegroundColor White
    Write-Host "  2. Commit: git commit -am 'chore: bump version to $newVersion'" -ForegroundColor White
    Write-Host "  3. Tag: git tag v$newVersion" -ForegroundColor White
    Write-Host "  4. Push: git push && git push --tags" -ForegroundColor White
}

# Main execution
switch ($Action) {
    "show" {
        $version = Get-Version
        Write-Host "Current version: $version" -ForegroundColor Cyan
    }
    "bump-patch" {
        Bump-Version "patch"
    }
    "bump-minor" {
        Bump-Version "minor"
    }
    "bump-major" {
        Bump-Version "major"
    }
}
