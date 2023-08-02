<#
.SYNOPSIS
Uses Get-acl to display a window or save a .csv of the permissions for the entered folder.

.DESCRIPTION
I don't claim to know PowerShell coding standards, apologies to all who may read this.
Looks for a user-defined share folder and prints out a table of the results with an option to pipe it into a csv.
There is a filtering functionality that you can add / remove from as you please. 

.PARAMETER 
directory or location that you are looking to investigate permissions on.

.EXAMPLE
Run the dang script.

.NOTES
- Devon Casey
#>
. ./Source.ps1
function Get-Permissions {
    param (
        $directory # $servername gets passed into this. 
    )
    $choice = Read-Host "Do you want to save a .csv of the results? [y]/[n] (Default is [n]) `nEnter"
    Switch ($choice) { 
        "y" {$choiceBool = 1}
        "n" {$choiceBool = 0}
        "" {$choiceBool = 0}
        default {$choiceBool = 0}
    }
    $folderPath = Get-ChildItem -Path $directory-Depth 1 # Get subfolders, only to depth of 1.
    $output = @() # Creates an empty array
    ForEach ($folder in $folderPath) {
        $acl = Get-acl -Path $folder.FullName # $folder.FullName is the path of the folder being passed.
        ForEach ($access in $acl.access) { 
            $checker = $access.IdentityReference
            if ( ($checker -eq $filterName01) -or # This if statement filters out unwanted group/users, add/remove as you wish.
                 ($checker -eq $filterName02) -or # These varaibles are dot sourced. 
                 ($checker -eq $filterName03) -or 
                 ($checker -eq $filterName04) -or
                 ($checker -eq $filterName05) -or
                 ($checker -eq $filterName06) ) {
            } else {
                $properties = [ordered]@{ # Separates the object into columns
                    "folder Name"=$folder.FullName; # File path
                    "Group/User"=$access.IdentityReference; # User and the group they belong to
                    "Permissions"=$access.FileSystemRights; # What permissions they have for the folder.
                    "Inherited"=$access.IsInherited; # If they inherit their permissions from another group.
                    "Inherited From"=$access.InheritanceFlags; # If the aCE is inherited to child items or not
                    "Propagation Flags"=$access.PropagationFlags # How the aCE is inherited to child items.
                }
                $output += New-Object -TypeName PSObject -Property $properties a new object with the properties outlined above
            }
            if ($choiceBool -eq 1) {
                $output | Export-Csv -Path "C:\Share_Permissions.csv" # Location to save csv.
            }
        } 
    }
    $output | Out-GridView -Title "List of Share Permissions" # Displays a window of the share permissions. 
}

#Invoke-Command -ComputerName $ServerName -ScriptBlock {
    Get-Permissions($sharePath) # Runs the function on the remote server
#}