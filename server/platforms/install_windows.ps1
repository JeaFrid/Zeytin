$ErrorActionPreference = "Stop"
Clear-Host

Write-Host ">>> Welcome to Zeytin!" -ForegroundColor Cyan
Write-Host ">>> Zeytin is a system that has set its mind on handling everything itself." -ForegroundColor Green
Write-Host ">>> So leave everything to us and sit back." -ForegroundColor Green
Write-Host ">>> Made with love by JeaFriday!" -ForegroundColor Yellow

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

choco install git curl wget openssl -y

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    choco install dart-sdk -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

git clone https://github.com/JeaFrid/Zeytin.git
if (-not $?) { Write-Host "Repository already exists, continuing..." -ForegroundColor Yellow }
Set-Location Zeytin
dart pub get

$INSTALL_LIVEKIT = Read-Host "`n>>> Do you want to enable Live Streaming & Calls (Installs Docker + LiveKit)? (y/n)"

if ($INSTALL_LIVEKIT -eq "y") {
    Write-Host "Checking/Installing Docker..." -ForegroundColor Cyan
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        Write-Host "Press ENTER after Docker is installed..." -ForegroundColor Yellow
        Read-Host
    }

    $LK_API_KEY = "api" + -join ((48..57) + (97..102) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    $LK_SECRET = "sec" + -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $PUBLIC_IP = (Invoke-WebRequest -Uri "https://ifconfig.me" -UseBasicParsing).Content.Trim()
    
    Write-Host "Deploying LiveKit Container..." -ForegroundColor Cyan
    $existingContainer = docker ps -aq -f name=zeytin-livekit
    if ($existingContainer) {
        Write-Host "Removing existing (old) Zeytin LiveKit container..." -ForegroundColor Yellow
        docker rm -f zeytin-livekit
    }
    docker run -d --name zeytin-livekit `
        --restart unless-stopped `
        -p 12133:7880 `
        -p 12134:7881 `
        -p 12135:7882/udp `
        -e LIVEKIT_KEYS="$LK_API_KEY`: $LK_SECRET" `
        livekit/livekit-server --dev --bind 0.0.0.0

    Write-Host "LiveKit deployed locally!" -ForegroundColor Green
    $CONFIG_FILE = "lib\config.dart"
    (Get-Content $CONFIG_FILE) -replace 'static String liveKitUrl = ".*";', "static String liveKitUrl = `"ws://$PUBLIC_IP:12133`";" | Set-Content $CONFIG_FILE
    (Get-Content $CONFIG_FILE) -replace 'static String liveKitApiKey = ".*";', "static String liveKitApiKey = `"$LK_API_KEY`";" | Set-Content $CONFIG_FILE
    (Get-Content $CONFIG_FILE) -replace 'static String liveKitSecretKey = ".*";', "static String liveKitSecretKey = `"$LK_SECRET`";" | Set-Content $CONFIG_FILE
    Write-Host "Zeytin configuration updated with LiveKit credentials (IP Base)!" -ForegroundColor Green
}

Write-Host "`nNote: Nginx with SSL is not automatically configured on Windows." -ForegroundColor Yellow
Write-Host "For production deployment, consider using IIS or a reverse proxy solution." -ForegroundColor Yellow

Write-Host "`n>>> Setting project permissions..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "zeytin" | Out-Null
New-Item -ItemType Directory -Force -Path "zeytin_err" | Out-Null

Write-Host "`nINSTALLATION COMPLETE! Run: dart server\runner.dart" -ForegroundColor Green
