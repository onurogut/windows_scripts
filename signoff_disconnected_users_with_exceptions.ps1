# Log file path and name
$logFolder = "C:\signoff_logs"
$currentDate = Get-Date -Format "yyyy-MM-dd"
$logFile = Join-Path $logFolder "signoff_edilen_$currentDate.html"

# Session timeout duration (minutes)
$sessionTimeoutMinutes = 240

$excludedUsers = @(
    "user1",
    "user2"

    # You can add more users here
)

# HTML style definitions
$htmlStyle = @"
<style>
    body { 
        font-family: Arial, sans-serif; 
        margin: 20px;
        font-size: 14px;
    }
    .log-container { 
        width: 95%; 
        margin: 0 auto; 
    }
    h1 {
        text-align: center;
        color: #333;
        font-size: 24px;
        margin-bottom: 20px;
    }
    .log-entry { 
        padding: 8px 12px;
        margin: 4px 0;
        border-radius: 4px;
        text-align: left;
        font-size: 13px;
        border-left: 4px solid;
    }
    .INFO { 
        background-color: #e8f5e9; 
        color: #2e7d32;
        border-left-color: #2e7d32;
    }
    .WARNING { 
        background-color: #fff3e0; 
        color: #ef6c00;
        border-left-color: #ef6c00;
    }
    .ERROR { 
        background-color: #ffebee; 
        color: #c62828;
        border-left-color: #c62828;
    }
    .DEBUG { 
        background-color: #f5f5f5; 
        color: #616161;
        border-left-color: #616161;
    }
    .timestamp { 
        font-weight: bold;
        margin-right: 8px;
    }
    .severity {
        display: inline-block;
        min-width: 60px;
        font-weight: bold;
        margin-right: 8px;
    }
</style>
"@

# Log function
function Write-LogMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARNING', 'DEBUG', 'ERROR')]
        [string]$severity = 'INFO'
    )
    
    # Create the folder if it doesn't exist
    if (-not (Test-Path $logFolder)) {
        New-Item -ItemType Directory -Path $logFolder | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # If the file does not exist, create the HTML header
    if (-not (Test-Path $logFile)) {
        @"
<!DOCTYPE html>
<html>
<head>
    <title>Signed Off Disconnected Users - $currentDate</title>
    $htmlStyle
</head>
<body>
<div class="log-container">
<h1>Signed Off Disconnected Users - $currentDate</h1>
"@ | Out-File -FilePath $logFile -Encoding UTF8
    }
    
    # Insert the new log entry at the top of the file (right after the h1 tag)
    $content = Get-Content -Path $logFile -Raw
    $insertPoint = $content.IndexOf('</h1>') + 5
    $newEntry = @"

<div class="log-entry $severity">
    <span class="timestamp">[$timestamp]</span>
    <span class="severity">[$severity]</span>
    $message
</div>
"@
    $updatedContent = $content.Insert($insertPoint, $newEntry)
    $updatedContent | Out-File -FilePath $logFile -Encoding UTF8 -Force
    
    # Also print to console
    Write-Host "[$timestamp] [$severity] $message"
}

# Close HTML file function
function Close-LogFile {
    Add-Content -Path $logFile -Value "</div></body></html>"
}

# Add users to be excluded here


# Script start log
Write-LogMessage "Script execution started" -severity "INFO"
Write-LogMessage "Excluded users: $($excludedUsers -join ', ')" -severity "DEBUG"

# Retrieve all disconnected sessions
try {
    $allDisconnectedSessions = quser | Where-Object { $_ -match "Disc" }
    Write-LogMessage "Disconnected sessions successfully retrieved" -severity "DEBUG"
} catch {
    Write-LogMessage "Error retrieving disconnected sessions: $_" -severity "ERROR"
    exit
}

$longDisconnectedSessions = @()
$shortDisconnectedSessions = @()
$excludedDisconnectedSessions = @()

foreach ($session in $allDisconnectedSessions) {
    $splitLine = $session -split '\s+'
    $username = $splitLine[1]
    $sessionId = $splitLine[2]
    $disconnectTime = $splitLine[4]

    Write-LogMessage "Processing session - User: $username, Duration: $disconnectTime" -severity "DEBUG"

    # Check if the user is excluded
    if ($excludedUsers -contains $username) {
        $excludedDisconnectedSessions += $session
        Write-LogMessage "Excluded user found: $username (Session ID: $sessionId)" -severity "DEBUG"
        continue
    }

    try {
        # If the duration is in minutes (e.g., "27")
        if ($disconnectTime -match '^\d+$') {
            $disconnectDuration = [int]$disconnectTime
            if ($disconnectDuration -gt $sessionTimeoutMinutes) {
                $longDisconnectedSessions += $session
                Write-LogMessage "User $username has been disconnected for $disconnectDuration minutes" -severity "DEBUG"
            } else {
                $shortDisconnectedSessions += $session
            }
        }
        # If the duration is in "hours:minutes" format (e.g., "1:27")
        elseif ($disconnectTime -match '(\d+):(\d+)') {
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2]
            $totalMinutes = ($hours * 60) + $minutes
            
            if ($totalMinutes -gt $sessionTimeoutMinutes) {
                $longDisconnectedSessions += $session
                Write-LogMessage "User $username has been disconnected for $totalMinutes minutes" -severity "DEBUG"
            } else {
                $shortDisconnectedSessions += $session
            }
        }
        else {
            Write-LogMessage "Unknown time format: $disconnectTime" -severity "WARNING"
            $shortDisconnectedSessions += $session
        }
    }
    catch {
        Write-LogMessage "Error calculating duration: $_" -severity "ERROR"
        $shortDisconnectedSessions += $session
    }
}

# Show excluded users who are currently disconnected
if ($excludedDisconnectedSessions) {
    Write-LogMessage "Excluded users currently disconnected:" -severity "INFO"
    foreach ($session in $excludedDisconnectedSessions) {
        $splitLine = $session -split '\s+'
        $username = $splitLine[1]
        $sessionId = $splitLine[2]
        $disconnectTime = $splitLine[4]
        Write-LogMessage "User: $username, Session ID: $sessionId, Disconnection Duration: $disconnectTime (No action will be taken)" -severity "DEBUG"
    }
}

# Show users disconnected for less than the timeout period
if ($shortDisconnectedSessions) {
    Write-LogMessage "Users disconnected for less than $sessionTimeoutMinutes minutes: (will be skipped)" -severity "INFO"
    foreach ($session in $shortDisconnectedSessions) {
        $splitLine = $session -split '\s+'
        $username = $splitLine[1]
        $sessionId = $splitLine[2]
        $disconnectTime = $splitLine[4]
        Write-LogMessage "User: $username, Session ID: $sessionId, Disconnection Duration: $disconnectTime" -severity "DEBUG"
    }
}

# Log off users who have been disconnected for longer than the timeout period
foreach ($session in $longDisconnectedSessions) {
    try {
        $splitLine = $session -split '\s+'
        $username = $splitLine[1]
        $sessionId = $splitLine[2]
        $disconnectTime = $splitLine[4]
        
        Write-LogMessage "Logging off user: $username (Session ID: $sessionId) (Disconnected Duration: $disconnectTime minutes)" -severity "WARNING"
        logoff $sessionId
        Write-LogMessage "User successfully logged off: $username" -severity "INFO"
    }
    catch {
        Write-LogMessage "ERROR: Failed to log off session $sessionId : $_" -severity "ERROR"
    }
}

Write-LogMessage "Script execution completed" -severity "INFO"
Close-LogFile
