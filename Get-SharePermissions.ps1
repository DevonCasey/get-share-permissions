param (
    [Parameter(Mandatory = $true)]
    [string]$RemoteServerPath
)

# Function to get shares from the server
function Get-SMBShares {
    param (
        [string]$ComputerName
    )

    try {
        Get-SmbShare -CimSession $ComputerName |
            Select-Object Name, Path, PSComputerName, Description
    }
    catch {
        Write-Host "Error: Unable to retrieve shares from $ComputerName. Make sure the server is accessible and has the appropriate permissions." -ForegroundColor Red
        exit 1
    }
}

# Function to get share permissions
function Get-SMBSharePermissions {
    param (
        [string]$ShareName,
        [string]$ComputerName
    )

    try {
        Get-SmbShareAccess -Name $ShareName -CimSession $ComputerName |
            Select-Object Name, AccountName, PSComputerName, Description
    }
    catch {
        Write-Host "Error: Unable to retrieve permissions for share $ShareName on $ComputerName." -ForegroundColor Red
        return @()
    }
}

# Main script

# Check if the provided path is a valid remote server path
if (-not ($RemoteServerPath -like "\\*")) {
    Write-Host "Error: The provided path is not a valid remote server path. Please provide a UNC path (e.g., \\ServerName)." -ForegroundColor Red
    exit 1
}

# Extract the server name from the provided path
$serverName = ($RemoteServerPath -split "\\")[2]

# Retrieve the list of shares from the server
$shares = Get-SMBShares -ComputerName $serverName

if ($shares.Count -eq 0) {
    Write-Host "No shares found on $serverName." -ForegroundColor Yellow
    exit
}

# Create an array to store the share details with permissions
$sharesWithPermissions = @()

# Iterate through each share and get its permissions
foreach ($share in $shares) {
    $shareName = $share.Name
    $sharePermissions = Get-SMBSharePermissions -ShareName $shareName -ComputerName $serverName

    if ($sharePermissions.Count -gt 0) {
        # Add the permissions to the share details
        $shareWithPermissions = $share | Select-Object *, @{Name = "Permissions"; Expression = {$sharePermissions}}
        $sharesWithPermissions += $shareWithPermissions
    }
    else {
        # Add the share without permissions
        $sharesWithPermissions += $share
    }
}

# Export the list to a CSV file
$csvFilePath = "$serverName-SharesWithPermissions.csv"
$sharesWithPermissions | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "The list of shares on $serverName with permissions has been exported to $csvFilePath." -ForegroundColor Green
