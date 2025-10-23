# Fix Mosquitto Log Permissions
# Run as Administrator

#Requires -RunAsAdministrator

$installPath = "E:\Services\mosquitto"
$logPath = "$installPath\log\mosquitto.log"

Write-Host "Fixing Mosquitto log file permissions..." -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $logPath)) {
    Write-Host "Log file does not exist yet" -ForegroundColor Yellow
    exit 0
}

try {
    # Get current ACL
    Write-Host "Current permissions:" -ForegroundColor Yellow
    icacls $logPath
    Write-Host ""
    
    # Add full control for current user
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "Adding full control for: $currentUser" -ForegroundColor Cyan
    
    icacls $logPath /grant "${currentUser}:(F)" /T
    
    # Also grant Administrators group
    icacls $logPath /grant "Administrators:(F)" /T
    
    # Grant Users group read permission
    icacls $logPath /grant "Users:(R)" /T
    
    Write-Host ""
    Write-Host "New permissions:" -ForegroundColor Green
    icacls $logPath
    Write-Host ""
    
    Write-Host "Permissions fixed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now you can view the log with:" -ForegroundColor Yellow
    Write-Host "  Get-Content $logPath -Tail 50" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
pause

