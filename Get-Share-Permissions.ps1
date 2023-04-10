<#
.SYNOPSIS
Uses Get-Acl to display a window or save a .csv of the permissions for the entered folder.

.DESCRIPTION
I don't claim to know PowerShell coding standards, apologies to all who may read this.
Looks for a user-defined share folder and prints out a table of the results with an option to pipe it into a csv.
There is a filtering functionality that you can add / remove from as you please. 

.PARAMETER Directory
$Directory = the location that you are looking to investigate permissions on.

.EXAMPLE
Run the dang script.

.NOTES
- Devon Casey
#>
. ./Source.ps1
function Get-Permissions {
    param (
        $Directory # $servername gets passed into this. 
    )
    $Choice = Read-Host "Do you want to save a .csv of the results? [y]/[n] (Default is [n]) `nEnter"
    Switch ($Choice) { 
        "y" {$ChoiceBool = 1}
        "n" {$ChoiceBool = 0}
        "" {$ChoiceBool = 0}
        default {$ChoiceBool = 0}
    }
    $FolderPath = Get-ChildItem -Path $Directory -Force -Depth 1 # Get subfolders, only to depth of 1.
    $Output = @() # Creates an empty array
    ForEach ($Folder in $FolderPath) {
        $Acl = Get-Acl -Path $Folder.FullName # $Folder.FullName is the path of the folder being passed.
        ForEach ($Access in $Acl.Access) { 
            $checker = $Access.IdentityReference
            if ( ($checker -eq $FilterName01) -or # This if statement filters out unwanted group/users, add/remove as you wish.
                 ($checker -eq $FilterName02) -or # These varaibles are dot sourced. 
                 ($checker -eq $FilterName03) -or 
                 ($checker -eq $FilterName04) -or
                 ($checker -eq $FilterName05) -or
                 ($checker -eq $FilterName06) ) {
            } else {
                $Properties = [ordered]@{ # Separates the object into columns
                    "Folder Name"=$Folder.FullName; # File path
                    "Group/User"=$Access.IdentityReference; # User and the group they belong to
                    "Permissions"=$Access.FileSystemRights; # What permissions they have for the folder.
                    "Inherited"=$Access.IsInherited; # If they inherit their permissions from another group.
                    "Inherited From"=$Access.InheritanceFlags; # If the ACE is inherited to child items or not
                    "Propagation Flags"=$Access.PropagationFlags # How the ACE is inherited to child items.
                }
                $Output += New-Object -TypeName PSObject -Property $Properties # Creates a new object with the properties outlined above
            }
            if ($ChoiceBool -eq 1) {
                $Output | Export-Csv -Path "C:\Share_Permissions.csv" # Location to save csv.
            }
        } 
    }
    $Output | Out-GridView -Title "List of Share Permissions" # Displays a window of the share permissions. 
}

#Invoke-Command -ComputerName $ServerName -ScriptBlock {
    Get-Permissions($SharePath) # Runs the function on the remote server
#}