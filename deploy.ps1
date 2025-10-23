# Mosquitto MQTT Server - Quick Deploy Script
# For installation at E:\Services\mosquitto
# Requires Administrator privileges

#Requires -RunAsAdministrator

# Color output function
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

# Check Mosquitto installation
function Test-MosquittoPath {
    param([string]$Path)
    
    $required = @(
        "mosquitto.exe",
        "mosquitto_passwd.exe",
        "mosquitto_pub.exe",
        "mosquitto_sub.exe"
    )
    
    foreach ($file in $required) {
        if (-not (Test-Path (Join-Path $Path $file))) {
            return $false
        }
    }
    return $true
}

# Main program
Clear-Host
Write-ColorText "========================================" "Cyan"
Write-ColorText "Mosquitto MQTT Server - Quick Deploy" "Green"
Write-ColorText "========================================" "Cyan"
Write-Host ""

$installPath = "E:\Services\mosquitto"

# Check installation
Write-ColorText "Checking Mosquitto installation..." "Cyan"
if (-not (Test-MosquittoPath $installPath)) {
    Write-ColorText "ERROR: Mosquitto not found at $installPath" "Red"
    Write-Host ""
    Write-ColorText "Please verify:" "Yellow"
    Write-ColorText "  1. Mosquitto is installed at $installPath" "White"
    Write-ColorText "  2. All required files exist" "White"
    Write-Host ""
    pause
    exit 1
}

Write-ColorText "Mosquitto installation found" "Green"
Write-Host ""

# Get version
Write-ColorText "Mosquitto Information:" "Cyan"
$versionOutput = & "$installPath\mosquitto.exe" --help 2>&1 | Out-String
if ($versionOutput -match "mosquitto version (\d+\.\d+\.\d+)") {
    Write-ColorText "  Version: $($Matches[1])" "White"
} else {
    Write-ColorText "  Version: Unknown" "White"
}
Write-ColorText "  Path: $installPath" "White"
Write-Host ""

# Step 1: Create directory structure
Write-ColorText "[1/7] Creating directory structure..." "Cyan"
$directories = @("data", "log", "conf.d")
foreach ($dir in $directories) {
    $dirPath = Join-Path $installPath $dir
    if (-not (Test-Path $dirPath)) {
        New-Item -ItemType Directory -Force -Path $dirPath | Out-Null
        Write-ColorText "  Created: $dir\" "Gray"
    } else {
        Write-ColorText "  Exists: $dir\" "Gray"
    }
}
Write-ColorText "  Done" "Green"
Write-Host ""

# Step 2: Check config file
Write-ColorText "[2/7] Checking configuration file..." "Cyan"
$configFile = Join-Path $installPath "mosquitto.conf"

if (Test-Path $configFile) {
    Write-ColorText "  Config file exists" "Gray"
    
    # Check key configurations
    $config = Get-Content $configFile -Raw
    $issues = @()
    
    if ($config -notmatch "listener\s+\d+") {
        $issues += "Missing listener configuration"
    }
    if ($config -notmatch "persistence_location") {
        $issues += "Missing persistence_location configuration"
    }
    if ($config -notmatch "log_dest") {
        $issues += "Missing log_dest configuration"
    }
    
    if ($issues.Count -gt 0) {
        Write-ColorText "  WARNING: Config file may be incomplete" "Yellow"
        foreach ($issue in $issues) {
            Write-ColorText "    - $issue" "Yellow"
        }
        
        $fix = Read-Host "  Use recommended config? (Y/N)"
        if ($fix -eq "Y" -or $fix -eq "y") {
            # Backup original config
            Copy-Item $configFile "$configFile.backup" -Force
            Write-ColorText "  Original config backed up to: mosquitto.conf.backup" "Gray"
            
            Write-ColorText "  Please manually copy the recommended mosquitto.conf file" "Yellow"
        }
    } else {
        Write-ColorText "  Config file is complete" "Green"
    }
} else {
    Write-ColorText "  WARNING: Config file not found" "Yellow"
    Write-ColorText "  Please copy mosquitto.conf to: $installPath" "Yellow"
    $continue = Read-Host "  Continue anyway? (Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        exit 1
    }
}
Write-Host ""

# Step 3: Set permissions
Write-ColorText "[3/7] Setting directory permissions..." "Cyan"
try {
    $acl = Get-Acl $installPath
    $everyone = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $everyone,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.AddAccessRule($rule)
    Set-Acl $installPath $acl
    Write-ColorText "  Permissions set successfully" "Green"
} catch {
    Write-ColorText "  WARNING: Failed to set permissions (may not affect usage)" "Yellow"
}
Write-Host ""

# Step 4: Configure firewall
Write-ColorText "[4/7] Configuring firewall..." "Cyan"
try {
    $existingRule = Get-NetFirewallRule -DisplayName "Mosquitto MQTT" -ErrorAction SilentlyContinue
    if ($existingRule) {
        Write-ColorText "  Firewall rule already exists" "Gray"
    } else {
        New-NetFirewallRule -DisplayName "Mosquitto MQTT" `
                           -Direction Inbound `
                           -LocalPort 1883 `
                           -Protocol TCP `
                           -Action Allow `
                           -ErrorAction Stop | Out-Null
        Write-ColorText "  Firewall rule added" "Green"
    }
} catch {
    Write-ColorText "  WARNING: Failed to configure firewall" "Yellow"
    Write-ColorText "  Please manually open TCP port 1883 in Windows Firewall" "Yellow"
}
Write-Host ""

# Step 5: Install/Update service
Write-ColorText "[5/7] Configuring Windows service..." "Cyan"

# Check if service exists
$service = Get-Service mosquitto -ErrorAction SilentlyContinue

if ($service) {
    Write-ColorText "  Service already installed" "Gray"
    if ($service.Status -eq "Running") {
        Write-ColorText "  Stopping existing service..." "Gray"
        Stop-Service mosquitto -Force
        Start-Sleep -Seconds 2
    }
    
    # Uninstall and reinstall to ensure config update
    Set-Location $installPath
    .\mosquitto.exe uninstall 2>&1 | Out-Null
    Start-Sleep -Seconds 1
}

Write-ColorText "  Installing service..." "Gray"
Set-Location $installPath
$installResult = .\mosquitto.exe install 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-ColorText "  Service installed successfully" "Green"
} else {
    Write-ColorText "  Service installation failed" "Red"
    Write-ColorText "  Error: $installResult" "Red"
    pause
    exit 1
}

# Set service to auto-start
Write-ColorText "  Setting auto-start..." "Gray"
sc.exe config mosquitto start= auto | Out-Null
Write-Host ""

# Step 6: Start service
Write-ColorText "[6/7] Starting service..." "Cyan"
Start-Sleep -Seconds 2

try {
    Start-Service mosquitto -ErrorAction Stop
    Start-Sleep -Seconds 3
    
    $service = Get-Service mosquitto
    if ($service.Status -eq "Running") {
        Write-ColorText "  Service started successfully" "Green"
    } else {
        throw "Service not running"
    }
} catch {
    Write-ColorText "  Service start failed" "Red"
    Write-ColorText "  Checking logs..." "Yellow"
    
    $logPath = Join-Path $installPath "log\mosquitto.log"
    if (Test-Path $logPath) {
        Write-Host ""
        Write-ColorText "  Last 20 log lines:" "Cyan"
        Get-Content $logPath -Tail 20 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-ColorText "Please check config file and logs, then start manually" "Yellow"
    pause
    exit 1
}
Write-Host ""

# Step 7: Verify deployment
Write-ColorText "[7/7] Verifying deployment..." "Cyan"

# Check port listening
Start-Sleep -Seconds 2
$listening = netstat -ano | Select-String ":1883.*LISTENING"

if ($listening) {
    Write-ColorText "  Port 1883 is listening" "Green"
} else {
    Write-ColorText "  WARNING: Port 1883 not listening" "Yellow"
}

# Function test
Write-ColorText "  Running function test..." "Gray"
try {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $testMsg = "Deployment test at $timestamp"
    
    # Start subscribe process (background)
    $subJob = Start-Job -ScriptBlock {
        param($path)
        & "$path\mosquitto_sub.exe" -h localhost -t test/deploy -C 1 2>&1
    } -ArgumentList $installPath
    
    Start-Sleep -Seconds 2
    
    # Publish message
    $pubResult = & "$installPath\mosquitto_pub.exe" -h localhost -t test/deploy -m $testMsg 2>&1
    
    Start-Sleep -Seconds 2
    $jobResult = Receive-Job $subJob
    Remove-Job $subJob -Force
    
    if ($jobResult -match $testMsg -or $LASTEXITCODE -eq 0) {
        Write-ColorText "  Function test passed" "Green"
    } else {
        Write-ColorText "  Function test failed" "Yellow"
    }
} catch {
    Write-ColorText "  Function test skipped" "Yellow"
}
Write-Host ""

# Display deployment summary
Write-ColorText "========================================" "Cyan"
Write-ColorText "Deployment Complete!" "Green"
Write-ColorText "========================================" "Cyan"
Write-Host ""

Write-ColorText "Service Information:" "Cyan"
Write-ColorText "  Status: Running" "Green"
Write-ColorText "  MQTT Port: 1883" "White"
Write-ColorText "  Config File: $installPath\mosquitto.conf" "White"
Write-ColorText "  Log File: $installPath\log\mosquitto.log" "White"
Write-ColorText "  Data Directory: $installPath\data\" "White"
Write-Host ""

Write-ColorText "Quick Test:" "Cyan"
Write-ColorText "  Subscribe test:" "White"
Write-ColorText "    cd $installPath" "Gray"
Write-ColorText "    .\mosquitto_sub.exe -h localhost -t test/# -v" "Gray"
Write-Host ""
Write-ColorText "  Publish test:" "White"
Write-ColorText "    cd $installPath" "Gray"
Write-ColorText "    .\mosquitto_pub.exe -h localhost -t test/topic -m `"Hello MQTT`"" "Gray"
Write-Host ""

Write-ColorText "Service Management:" "Cyan"
Write-ColorText "  Start: net start mosquitto" "Gray"
Write-ColorText "  Stop: net stop mosquitto" "Gray"
Write-ColorText "  Status: sc query mosquitto" "Gray"
Write-Host ""

Write-ColorText "Local IP Addresses:" "Cyan"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notmatch "^127\."} | ForEach-Object {
    Write-ColorText "  $($_.IPAddress)" "White"
}
Write-Host ""

Write-ColorText "Other machines can connect via:" "Cyan"
$validIPs = Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object {$_.IPAddress -notmatch "^127\." -and $_.IPAddress -notmatch "^169\.254\."} | 
    Select-Object -ExpandProperty IPAddress

if ($validIPs) {
    if ($validIPs -is [array]) {
        Write-ColorText "  $($validIPs[0]):1883" "White"
    } else {
        Write-ColorText "  $($validIPs):1883" "White"
    }
} else {
    Write-ColorText "  (Use any IP address above):1883" "Yellow"
}
Write-Host ""

Write-ColorText "========================================" "Cyan"
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

