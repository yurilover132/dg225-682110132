# Setup-VSCode.ps1 - Automated VS Code Setup for MonoGame Development
# Description: Custom VS Code workspace setting generator for MonoGame .NET 9.0 in DG225 course.

# --- Styling & Colors ---
$Esc = [char]27
$Style = @{
    Reset      = "$Esc[0m"
    Bold       = "$Esc[1m"
    Underline  = "$Esc[4m"
    Cyan       = "$Esc[36m"
    Green      = "$Esc[32m"
    Yellow     = "$Esc[33m"
    Magenta    = "$Esc[35m"
    Red        = "$Esc[31m"
    Gray       = "$Esc[90m"
    White      = "$Esc[97m"
    BgBlue     = "$Esc[44m"
}

# Set encoding to UTF-8 for console output compatibility
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

function Show-Banner {
    Clear-Host
    Write-Host "$($Style.Bold)$($Style.Cyan)"
    Write-Host "███╗   ███╗ ██████╗ ███╗   ██╗ ██████╗  ██████╗  █████╗ ███╗   ███╗███████╗"
    Write-Host "████╗ ████║██╔═══██╗████╗  ██║██╔═══██╗██╔════╝ ██╔══██╗████╗ ████║██╔════╝"
    Write-Host "██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║██║  ███╗███████║██╔████╔██║█████╗  "
    Write-Host "██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  "
    Write-Host "██║ ╚═╝ ██║╚██████╔╝██║ ╚████║╚██████╔╝╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗"
    Write-Host "╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝"
    Write-Host "                                                                           "
    Write-Host "         VS CODE ENVIRONMENT SETUP FOR MONOGAME C# & .NET 9.0"
    Write-Host "              DG225 DIGITAL GAME PRODUCTION | CAMT"
    Write-Host "$($Style.Reset)"
}

function Write-Info { param([string]$msg) Write-Host "$($Style.Cyan)[i] $msg$($Style.Reset)" }
function Write-Success { param([string]$msg) Write-Host "$($Style.Green)[√] $msg$($Style.Reset)" }
function Write-Warning { param([string]$msg) Write-Host "$($Style.Yellow)[!] $msg$($Style.Reset)" }
function Write-ErrorMsg { param([string]$msg) Write-Host "$($Style.Red)[X] $msg$($Style.Reset)" }
function Write-Section { param([string]$title) 
    Write-Host "`n$($Style.Bold)$($Style.Underline)$($Style.White)$title$($Style.Reset)" 
}

# --- Main Logic ---
Show-Banner

# ยืนยันก่อนเริ่มทำงาน (Y/N)
Write-Host "สคริปต์นี้จะติดตั้ง MonoGame templates, MGCB Editor และสร้างไฟล์ตั้งค่า VS Code (.vscode)"
do {
    $runConfirm = (Read-Host "ต้องการรันการตั้งค่า VS Code หรือไม่? (Y/N)").Trim().ToUpper()
} while ($runConfirm -ne 'Y' -and $runConfirm -ne 'N')

if ($runConfirm -eq 'N') {
    Write-Warning "ยกเลิกการทำงานตามที่ผู้ใช้เลือก"
    exit
}

# Dynamic workspace resolution relative to script location
$workspaceDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.."))
if (-not (Test-Path "$workspaceDir\src")) {
    $workspaceDir = Get-Location
}
Write-Info "โฟลเดอร์ Workspace ของคุณคือ: $workspaceDir"

# 1. ตรวจสอบการติดตั้ง .NET 9.0 SDK
$dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnetCmd) {
    Write-ErrorMsg "ไม่พบคำสั่ง 'dotnet' บนเครื่องของคุณ กรุณาติดตั้ง .NET 9.0 SDK ก่อนใช้งาน!"
    Write-Host ""
    Write-Host "$($Style.Bold)วิธีแก้ไข:$($Style.Reset)"
    Write-Host "  1. ติดตั้งผ่าน Windows Package Manager (PowerShell Administrator):"
    Write-Host "     $($Style.Yellow)winget install Microsoft.DotNet.SDK.9$($Style.Reset)"
    Write-Host "  2. หรือดาวน์โหลดโดยตรงจากหน้าเว็บไมโครซอฟท์:"
    Write-Host "     https://dotnet.microsoft.com/download"
    Write-Host ""
    Write-Host "กดปุ่มใดๆ เพื่อออกจากสคริปต์..."
    [void][System.Console]::ReadKey($true)
    exit
}

$dotnetVersion = dotnet --version
Write-Success "ตรวจพบ .NET SDK เวอร์ชัน: $dotnetVersion"

if ($dotnetVersion -notmatch '^9\.') {
    Write-Warning "วิชานี้เขียนด้วย .NET 9.0 แต่เครื่องคุณใช้เวอร์ชันอื่น ($dotnetVersion)"
    Write-Host "แนะนำให้ติดตั้ง .NET 9.0 SDK เพื่อหลีกเลี่ยงปัญหาความเข้ากันได้"
}

# 2. ติดตั้ง/อัปเดต MonoGame Project Templates
Write-Section "1. ติดตั้ง MonoGame Project Templates"
Write-Info "กำลังดำเนินการติดตั้ง/อัปเดต MonoGame C# templates..."
dotnet new install MonoGame.Templates.CSharp 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Success "ติดตั้ง/อัปเดต MonoGame C# Templates สำเร็จ!"
} else {
    Write-Warning "การติดตั้ง templates เกิดข้อผิดพลาดเล็กน้อย แต่โปรเจกต์เดิมยังสามารถรันได้"
}

# 3. ติดตั้งเครื่องมือจัดการ Asset (MGCB Editor)
Write-Section "2. ติดตั้งเครื่องมือ MonoGame Content Pipeline (MGCB) Editor"
$globalTools = dotnet tool list -g
if ($globalTools -match "dotnet-mgcb-editor") {
    Write-Success "เครื่องมือ MGCB Editor ติดตั้งแบบ Global อยู่แล้วในระบบ"
} else {
    Write-Info "ไม่พบ MGCB Editor ในแบบ Global กำลังดำเนินการติดตั้งให้..."
    dotnet tool install -g dotnet-mgcb-editor 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "ติดตั้ง dotnet-mgcb-editor สำเร็จ!"
    } else {
        Write-Warning "ไม่สามารถติดตั้ง MGCB Editor แบบ Global ได้ (สคริปต์จะพยายามใช้เครื่องมือจากตัวโปรเจกต์แทน)"
    }
}

# พยายามลงทะเบียนไฟล์ .mgcb เพื่อให้ดับเบิ้ลคลิกเปิด MGCB Editor ได้บน Windows
Write-Info "กำลังลงทะเบียนไฟล์ .mgcb เพื่อการเปิดใช้งานที่สะดวกด้วยเมาส์..."
try {
    dotnet-mgcb-editor register 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        mgcb-editor-wpf install 2>&1 | Out-Null
    }
    Write-Success "ลงทะเบียนไฟล์นามสกุล .mgcb สำเร็จ"
} catch {
    Write-Warning "ไม่สามารถลงทะเบียน .mgcb ให้กับระบบปฏิบัติการได้ (ไม่มีผลกับการเขียนโค้ด)"
}

# 4. สแกนหาโปรเจกต์ MonoGame C# ในโฟลเดอร์ src
Write-Section "3. ค้นหาโปรเจกต์และกู้คืนโปรเจกต์ย่อย (Project scanning & tool restoring)"
$srcDir = Join-Path $workspaceDir "src"
$csprojFiles = @()

if (Test-Path $srcDir) {
    $csprojFiles = Get-ChildItem -Path $srcDir -Filter "*.csproj" -Recurse | 
                   Where-Object { $_.FullName -notmatch '\\(bin|obj|packages|\.git|\.vscode|\.agents)\\' }
}

if ($csprojFiles.Count -eq 0) {
    Write-Warning "ไม่พบโปรเจกต์ย่อย (.csproj) ภายใต้โฟลเดอร์ src/"
} else {
    Write-Success "พบโปรเจกต์ในระบบทั้งหมด $($csprojFiles.Count) รายการ:"
    foreach ($file in $csprojFiles) {
        $relPath = Resolve-Path $file.FullName -Relative
        Write-Host "  » $($file.BaseName) ($relPath)" -ForegroundColor White
        
        # ตรวจสอบและทำ dotnet tool restore ในกรณีที่โปรเจกต์ย่อยมี local tools (เช่น mgcb-editor รุ่นเฉพาะเจาะจง)
        $projDir = $file.DirectoryName
        $localManifest = Join-Path $projDir ".config\dotnet-tools.json"
        if (Test-Path $localManifest) {
            Write-Info "   [+] พบ local tools manifest ในโฟลเดอร์นี้ กำลังรัน dotnet tool restore..."
            Push-Location $projDir
            dotnet tool restore 2>&1 | Out-Null
            Pop-Location
            Write-Success "   [+] ดำเนินการติดตั้ง local tools สำหรับ $($file.BaseName) สำเร็จ!"
        }
    }
}

# 5. จัดการโฟลเดอร์ .vscode
Write-Section "4. สร้างและอัปเดตไฟล์การตั้งค่า VS Code (.vscode)"
$vscodeDir = Join-Path $workspaceDir ".vscode"

if (Test-Path $vscodeDir) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $vscodeDir "backup_$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    $filesToBackup = @("extensions.json", "settings.json", "tasks.json", "launch.json")
    foreach ($file in $filesToBackup) {
        $src = Join-Path $vscodeDir $file
        if (Test-Path $src) {
            Copy-Item $src -Destination $backupDir -Force
        }
    }
    Write-Info "สำรองไฟล์ตั้งค่า VS Code ชุดเดิมไว้ที่: .vscode\backup_$timestamp\"
} else {
    New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
}

# 5.1 เขียนไฟล์ extensions.json (แนะนำ extension ที่ควรใช้กับ MonoGame)
$extensionsJson = @"
{
    "recommendations": [
        "ms-dotnettools.csharp",
        "ms-dotnettools.csdevkit",
        "clarke-dyer.monogame-mgcb"
    ]
}
"@
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "extensions.json"), $extensionsJson, [System.Text.Encoding]::UTF8)
Write-Success "สร้างไฟล์ .vscode/extensions.json เรียบร้อย"

# 5.2 เขียนไฟล์ settings.json (ตั้งค่าการจัดหน้ากระดาษและ solution)
$settingsJson = @"
{
    "files.encoding": "utf8",
    "editor.formatOnSave": true,
    "dotnet.defaultSolution": "Monogame.sln",
    "csharp.inlayHints.enableInlayHintsForImplicitObjectCreation": true,
    "csharp.inlayHints.enableInlayHintsForLambdaParameterTypes": true,
    "csharp.inlayHints.enableInlayHintsForParameterNames": true,
    "csharp.inlayHints.enableInlayHintsForTypes": true
}
"@
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "settings.json"), $settingsJson, [System.Text.Encoding]::UTF8)
Write-Success "สร้างไฟล์ .vscode/settings.json เรียบร้อย"

# 5.3 เขียนไฟล์ tasks.json (สร้างงาน build สำหรับแต่ละโปรเจกต์ที่สแกนเจอ)
$tasksList = @()
foreach ($file in $csprojFiles) {
    # หารูปแบบ path สัมพัทธ์สำหรับใสลงใน tasks.json
    $relPath = $file.FullName.Replace($workspaceDir, "").Replace("\", "/").TrimStart("/")
    $projectName = $file.BaseName
    
    $tasksList += @{
        label = "build-$projectName"
        command = "dotnet"
        type = "process"
        args = @(
            "build",
            "`${workspaceFolder}/$relPath",
            "/property:GenerateFullPaths=true",
            "/consoleloggerparameters:NoSummary;ForceNoAlign"
        )
        problemMatcher = "`$msCompile"
    }
}

# กรณีพิเศษถ้าไม่มีโปรเจกต์ใดๆ เลย ให้ใส่ fallback task ไว้
if ($tasksList.Count -eq 0) {
    $tasksList += @{
        label = "build-active-project"
        command = "dotnet"
        type = "process"
        args = @(
            "build",
            "`${file}",
            "/property:GenerateFullPaths=true",
            "/consoleloggerparameters:NoSummary;ForceNoAlign"
        )
        problemMatcher = "`$msCompile"
    }
}

$tasksObj = @{
    version = "2.0.0"
    tasks = $tasksList
}

$tasksJsonString = ConvertTo-Json -InputObject $tasksObj -Depth 10
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "tasks.json"), $tasksJsonString, [System.Text.Encoding]::UTF8)
Write-Success "สร้างไฟล์ .vscode/tasks.json เรียบร้อย"

# 5.4 เขียนไฟล์ launch.json (ตั้งค่า Debugger ให้กด F5 รันได้เลยสำหรับแต่ละโปรเจกต์)
$configList = @()
foreach ($file in $csprojFiles) {
    $relPath = $file.FullName.Replace($workspaceDir, "").Replace("\", "/").TrimStart("/")
    $projectName = $file.BaseName
    
    $configList += @{
        name = "Play $projectName (Debug)"
        type = "dotnet"
        request = "launch"
        projectPath = "`${workspaceFolder}/$relPath"
        preLaunchTask = "build-$projectName"
    }
}

if ($configList.Count -eq 0) {
    $configList += @{
        name = "MonoGame: Debug Active Project"
        type = "dotnet"
        request = "launch"
        projectPath = "`${file}"
    }
}

$launchObj = @{
    version = "0.2.0"
    configurations = $configList
}

$launchJsonString = ConvertTo-Json -InputObject $launchObj -Depth 10
[System.IO.File]::WriteAllText((Join-Path $vscodeDir "launch.json"), $launchJsonString, [System.Text.Encoding]::UTF8)
Write-Success "สร้างไฟล์ .vscode/launch.json เรียบร้อย"

# --- แนะนำการใช้งาน ---
Write-Section "การตั้งค่าสำเร็จเรียบร้อย! 🎮"
Write-Host "$($Style.Bold)คำแนะนำและขั้นตอนการทำงานขั้นต่อไป:$($Style.Reset)"
Write-Host " 1. $($Style.Bold)เปิดใช้งาน VS Code:$($Style.Reset)"
Write-Host "    - ดับเบิ้ลคลิกโฟลเดอร์ของรายวิชา หรือเปิด VS Code แล้วเลือกเมนู Open Folder ไปยัง Workspace นี้"
Write-Host "    - แนะนำให้ยอมรับการติดตั้ง Extension ตามที่แจ้งเตือน (C# Dev Kit และอื่นๆ)"
Write-Host ""
Write-Host " 2. $($Style.Bold)วิธี Build และรันโปรเจกต์ด้วยโหมด Debug (F5):$($Style.Reset)"
Write-Host "    - ไปที่เมนู Run & Debug ($($Style.Cyan)Ctrl + Shift + D$($Style.Reset)) บนแถบซ้ายมือ"
Write-Host "    - เลือกการทำงานเช่น $($Style.Bold)'Play monogame1 (Debug)'$($Style.Reset) หรือ $($Style.Bold)'Play monogame2 (Debug)'$($Style.Reset)"
Write-Host "    - กดปุ่ม $($Style.Cyan)F5$($Style.Reset) เพื่อคอมไพล์โปรเจกต์และเปิดหน้าต่างเกมขึ้นมาทันที"
Write-Host ""
Write-Host " 3. $($Style.Bold)การแก้ไขเนื้อหาและ Resource ของเกม (Assets):$($Style.Reset)"
Write-Host "    - ดับเบิ้ลคลิกไฟล์นามสกุล $($Style.Bold).mgcb$($Style.Reset) ใน VS Code เพื่อเปิดหน้าจอแต่ง Asset"
Write-Host "    - หรือใช้งานผ่านสคริปต์ควบคุมส่วนกลางโดยเปิด Terminal ในโฟลเดอร์นี้ แล้วเรียกใช้งาน:"
Write-Host "      $($Style.Yellow).\scripts\run.ps1$($Style.Reset)"
Write-Host "      ในสคริปต์จะมีเมนูรันโปรเจกต์ เปิด Content Editor และสร้างโปรเจกต์ใหม่แบบสำเร็จรูปให้อย่างง่ายดาย"
Write-Host ""
Write-Host "$($Style.Bold)ขอให้สนุกและประสบความสำเร็จกับการเรียนรู้การพัฒนาเกมในรายวิชา DG225 ครับ! 🚀$($Style.Reset)"
Write-Host "---------------------------------------------------------------------------"
Write-Host "กดปุ่มใดๆ เพื่อสิ้นสุดการทำงาน..."
[void][System.Console]::ReadKey($true)
