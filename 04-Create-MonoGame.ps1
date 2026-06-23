# ==========================================================
# MonoGame Project Manager & Runner
# For Digital Game Production (DG225)
# ==========================================================

$Host.UI.RawUI.WindowTitle = "MonoGame Project Manager"

# Set encoding to UTF-8 for console output compatibility
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

function Show-Header {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "        MonoGame Project Manager & Runner (v1.3)" -ForegroundColor Cyan
    Write-Host "      DG225 Digital Game Production | C# + .NET 9.0" -ForegroundColor DarkCyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Find-Projects {
    # Scan for .csproj files recursively, excluding build/temp and tool directories
    $projects = Get-ChildItem -Path "$PSScriptRoot" -Filter "*.csproj" -Recurse | 
                Where-Object { $_.FullName -notmatch '\\(bin|obj|packages|\.git|\.vscode|\.agents)\\'}
    return $projects
}

function Get-MgcbFiles ($projectDir) {
    # Scan for .mgcb files inside the project directory
    $mgcbFiles = Get-ChildItem -Path $projectDir -Filter "*.mgcb" -Recurse | 
                 Where-Object { $_.FullName -notmatch '\\(bin|obj)\\'}
    return $mgcbFiles
}

# Function to create a new project
function Create-NewProject {
    Clear-Host
    Show-Header
    
    Write-Host "[+] --- Create New MonoGame Project ---" -ForegroundColor Green
    Write-Host ""
    
    # 1. Ask for Project Name
    $validName = $false
    $projectName = ""
    while (-not $validName) {
        $projectName = Read-Host "Enter Project Name (Alphanumeric only, e.g. MyNewGame)"
        if ($projectName -match '^[a-zA-Z][a-zA-Z0-9_]*$') {
            # Check if directory already exists
            $targetDir = Join-Path "$PSScriptRoot\src" $projectName
            if (Test-Path $targetDir) {
                Write-Host "[!] Folder '$projectName' already exists in src/! Please choose a different name." -ForegroundColor Red
            } else {
                $validName = $true
            }
        } else {
            Write-Host "[!] Invalid name! Must start with a letter and contain no spaces or special characters." -ForegroundColor Red
        }
    }
    
    # 2. Select Template Type
    Write-Host ""
    Write-Host "Select MonoGame Template Type:" -ForegroundColor Yellow
    Write-Host "  [1] DesktopGL (Recommended - Cross-platform Windows/macOS/Linux using OpenGL)" -ForegroundColor White
    Write-Host "  [2] WindowsDX (Runs on Windows only using DirectX)" -ForegroundColor White
    Write-Host ""
    
    $templateChoice = ""
    while ($templateChoice -ne "1" -and $templateChoice -ne "2") {
        $templateChoice = Read-Host "Select template (1-2, Press Enter for DesktopGL)"
        if ($templateChoice -eq "") { $templateChoice = "1" }
    }
    
    $templateName = "mgdesktopgl"
    $templateDesc = "DesktopGL (Cross-platform)"
    if ($templateChoice -eq "2") {
        $templateName = "mgwindowsdx"
        $templateDesc = "WindowsDX (DirectX)"
    }
    
    Write-Host ""
    Write-Host "[*] Preparing environment..." -ForegroundColor Yellow
    
    # Check and Install/Update MonoGame Templates
    Write-Host "[*] Installing/Updating MonoGame C# templates..." -ForegroundColor DarkGray
    dotnet new install MonoGame.Templates.CSharp 2>$null
    
    # Create Project
    Write-Host "[*] Generating project '$projectName' ($templateDesc) in src/$projectName..." -ForegroundColor Green
    $projectSrcPath = "src/$projectName"
    
    # Execute dotnet new command
    dotnet new $templateName -n $projectName -o $projectSrcPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Project files generated successfully!" -ForegroundColor Green
        
        # Link project to solution (.sln)
        $slnPath = Join-Path $PSScriptRoot "Monogame.sln"
        if (Test-Path $slnPath) {
            Write-Host "[*] Adding new project to Monogame.sln..." -ForegroundColor Yellow
            dotnet sln "$slnPath" add "$projectSrcPath/$projectName.csproj"
        }
        
        # Add VS Code configurations
        $vscodeDir = Join-Path $PSScriptRoot ".vscode"
        $launchPath = Join-Path $vscodeDir "launch.json"
        $tasksPath = Join-Path $vscodeDir "tasks.json"
        
        if (Test-Path $launchPath) {
            try {
                $launchJson = Get-Content $launchPath -Raw | ConvertFrom-Json
                $configName = "Play $projectName (Debug)"
                $exists = $launchJson.configurations | Where-Object { $_.name -eq $configName }
                if (-not $exists) {
                    $newConfig = [PSCustomObject]@{
                        name = $configName
                        type = "dotnet"
                        request = "launch"
                        projectPath = '${workspaceFolder}/src/' + $projectName + '/' + $projectName + '.csproj'
                        preLaunchTask = "build-$projectName"
                    }
                    $launchJson.configurations += $newConfig
                    $launchJson | ConvertTo-Json -Depth 10 | Out-File $launchPath -Encoding utf8
                    Write-Host "[*] Added launch configuration in .vscode/launch.json!" -ForegroundColor DarkGray
                }
            } catch {}
        }
        
        if (Test-Path $tasksPath) {
            try {
                $tasksJson = Get-Content $tasksPath -Raw | ConvertFrom-Json
                $taskLabel = "build-$projectName"
                $exists = $tasksJson.tasks | Where-Object { $_.label -eq $taskLabel }
                if (-not $exists) {
                    $newTask = [PSCustomObject]@{
                        label = $taskLabel
                        command = "dotnet"
                        type = "process"
                        args = @(
                            "build",
                            ('${workspaceFolder}/src/' + $projectName + '/' + $projectName + '.csproj'),
                            "/property:GenerateFullPaths=true",
                            "/consoleloggerparameters:NoSummary;ForceNoAlign"
                        )
                        problemMatcher = "$msCompile"
                    }
                    $tasksJson.tasks += $newTask
                    $tasksJson | ConvertTo-Json -Depth 10 | Out-File $tasksPath -Encoding utf8
                    Write-Host "[*] Added build task in .vscode/tasks.json!" -ForegroundColor DarkGray
                }
            } catch {}
        }
        
        Write-Host ""
        Write-Host "[OK] Project '$projectName' created and configured successfully!" -ForegroundColor Green
        Write-Host ""
        $switchChoice = Read-Host "Do you want to manage this new project now? (Y/N, Press Enter for Yes)"
        if ($switchChoice -eq "" -or $switchChoice.ToLower() -eq "y") {
            $newProjFile = Get-ChildItem -Path "$PSScriptRoot/$projectSrcPath" -Filter "$projectName.csproj" | Select-Object -First 1
            if ($newProjFile) {
                return $newProjFile
            }
        }
    } else {
        Write-Host "[!] Failed to create project using dotnet CLI templates." -ForegroundColor Red
        Read-Host "Press Enter to return to main menu..."
    }
    return $null
}

# Function to manage the selected project
function Manage-Project ($selectedProject) {
    $projectPath = $selectedProject.FullName
    $projectDir = $selectedProject.DirectoryName
    $projectName = $selectedProject.BaseName
    
    $projectMenuExit = $false
    while (-not $projectMenuExit) {
        Clear-Host
        Show-Header
        
        Write-Host "Selected Project: " -NoNewline
        Write-Host "$projectName" -ForegroundColor Green
        Write-Host "File Path:        " -NoNewline
        Write-Host "$(Resolve-Path $projectPath -Relative)" -ForegroundColor Gray
        Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Choose an action:" -ForegroundColor Yellow
        Write-Host "  [1] Run Project           " -ForegroundColor White -NoNewline; Write-Host "-> Start game (dotnet run)" -ForegroundColor Gray
        Write-Host "  [2] Build Project         " -ForegroundColor White -NoNewline; Write-Host "-> Compile project (dotnet build)" -ForegroundColor Gray
        Write-Host "  [3] Open Content Editor   " -ForegroundColor White -NoNewline; Write-Host "-> Open MGCB Editor for Assets" -ForegroundColor Gray
        Write-Host "  [4] Restore Tools         " -ForegroundColor White -NoNewline; Write-Host "-> Restore dotnet tools in this PC" -ForegroundColor Gray
        Write-Host "  [5] Clean Project         " -ForegroundColor White -NoNewline; Write-Host "-> Clean cache/temp files (dotnet clean)" -ForegroundColor Gray
        Write-Host "  [6] Open Project Folder   " -ForegroundColor White -NoNewline; Write-Host "-> Open in Windows Explorer" -ForegroundColor Gray
        Write-Host "  [7] Select Another Project" -ForegroundColor White -NoNewline; Write-Host "-> Go back to project selection" -ForegroundColor Gray
        Write-Host "  [8] Exit                  " -ForegroundColor Red -NoNewline; Write-Host "-> Close program" -ForegroundColor Gray
        Write-Host ""
        
        $action = Read-Host "Enter choice (1-8)"
        Write-Host ""
        
        switch ($action) {
            "1" {
                Write-Host "[*] Running $projectName..." -ForegroundColor Green
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                dotnet run --project "$projectPath"
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host "[*] Game process terminated." -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Press Enter to return to menu..."
            }
            "2" {
                Write-Host "[*] Building $projectName..." -ForegroundColor Green
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                dotnet build "$projectPath"
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host "[OK] Build completed." -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Press Enter to return to menu..."
            }
            "3" {
                Write-Host "[*] Searching for MGCB Content Pipeline (.mgcb)..." -ForegroundColor Yellow
                $mgcbFiles = Get-MgcbFiles $projectDir
                
                if ($mgcbFiles.Count -eq 0) {
                    Write-Host "[!] No .mgcb file found! Opening blank MGCB Editor..." -ForegroundColor DarkYellow
                    dotnet mgcb-editor
                } else {
                    $mgcbFile = $mgcbFiles[0].FullName
                    $mgcbRelPath = Resolve-Path $mgcbFile -Relative
                    Write-Host "[OK] Found Content Pipeline: $mgcbRelPath" -ForegroundColor Green
                    Write-Host "[*] Opening MGCB Editor..." -ForegroundColor Yellow
                    Start-Process dotnet -ArgumentList "mgcb-editor `"$mgcbFile`"" -WorkingDirectory $projectDir
                    Start-Sleep -Seconds 1
                }
            }
            "4" {
                Write-Host "[*] Restoring .NET Tools..." -ForegroundColor Green
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                dotnet tool restore
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host "[OK] Tools restore completed." -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Press Enter to return to menu..."
            }
            "5" {
                Write-Host "[*] Cleaning project build cache..." -ForegroundColor Green
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                dotnet clean "$projectPath"
                Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host "[OK] Project cleaned successfully." -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Press Enter to return to menu..."
            }
            "6" {
                Write-Host "[*] Opening folder: $projectDir" -ForegroundColor Green
                explorer.exe "$projectDir"
                Start-Sleep -Seconds 1
            }
            "7" {
                $projectMenuExit = $true
            }
            "8" {
                $projectMenuExit = $true
                $global:ScriptExit = $true
            }
            Default {
                Write-Host "[!] Invalid option! Please enter 1-8" -ForegroundColor Red
                Start-Sleep -Seconds 1.5
            }
        }
    }
}

# Main Script Loop
$global:ScriptExit = $false

while (-not $global:ScriptExit) {
    Clear-Host
    Show-Header
    
    Write-Host "[*] Scanning for MonoGame projects..." -ForegroundColor Yellow
    $projectList = Find-Projects
    
    if (-not $projectList -or $projectList.Count -eq 0) {
        Write-Host "[!] No MonoGame (.csproj) projects found in this workspace!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Choose an option:" -ForegroundColor Yellow
        Write-Host "  [1] Create a New MonoGame Project" -ForegroundColor Green
        Write-Host "  [2] Scan Again" -ForegroundColor White
        Write-Host "  [3] Exit" -ForegroundColor Red
        Write-Host ""
        
        $noProjChoice = Read-Host "Enter choice (1-3)"
        if ($noProjChoice -eq "1") {
            $newProj = Create-NewProject
            if ($newProj) {
                Manage-Project $newProj
            }
        } elseif ($noProjChoice -eq "2") {
            continue
        } elseif ($noProjChoice -eq "3") {
            $global:ScriptExit = $true
        }
        continue
    }
    
    Write-Host "[OK] Found $($projectList.Count) project(s):" -ForegroundColor Green
    Write-Host ""
    
    for ($i = 0; $i -lt $projectList.Count; $i++) {
        $relPath = Resolve-Path $projectList[$i].FullName -Relative
        Write-Host "  [$($i + 1)] " -ForegroundColor Cyan -NoNewline
        Write-Host "$($projectList[$i].BaseName) " -ForegroundColor White -NoNewline
        Write-Host "($relPath)" -ForegroundColor Gray
    }
    Write-Host ""
    
    $newProjectOptionNum = $projectList.Count + 1
    $exitOptionNum = $projectList.Count + 2
    
    Write-Host "  [$newProjectOptionNum] [+] Create a New MonoGame Project" -ForegroundColor Green
    Write-Host "  [$exitOptionNum] [x] Exit" -ForegroundColor Red
    Write-Host ""
    
    $selectedProjectIndex = -1
    while ($selectedProjectIndex -lt 0 -or $selectedProjectIndex -ge $exitOptionNum) {
        $input = Read-Host "Select an option (1-$exitOptionNum)"
        if ($input -match '^\d+$') {
            $selectedProjectIndex = [int]$input - 1
        }
        if ($selectedProjectIndex -lt 0 -or $selectedProjectIndex -ge $exitOptionNum) {
            Write-Host "[!] Invalid choice! Please enter a number from 1 to $exitOptionNum" -ForegroundColor Red
        }
    }
    
    if ($selectedProjectIndex -eq ($newProjectOptionNum - 1)) {
        $newProj = Create-NewProject
        if ($newProj) {
            Manage-Project $newProj
        }
    } elseif ($selectedProjectIndex -eq ($exitOptionNum - 1)) {
        $global:ScriptExit = $true
    } else {
        $selectedProject = $projectList[$selectedProjectIndex]
        Manage-Project $selectedProject
    }
}

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Thank you for using MonoGame Project Manager! Have fun!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Seconds 1.5
