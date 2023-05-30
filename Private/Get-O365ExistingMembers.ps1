function Get-O365ExistingMembers {
    [cmdletbinding()]
    param(
        [string[]] $MemberTypes,
        [switch] $RequireAccountEnabled,
        [switch] $RequireAssignedLicenses
    )
    # Lets get all users and cache them
    $ExistingUsers = [ordered] @{}
    if ($MemberTypes -contains 'Member' -or $MemberTypes -contains 'Guest') {
        try {
            $Users = Get-MgUser -Property $Script:PropertiesUsers -All -ErrorAction Stop
        } catch {
            Write-Color -Text "[e] ", "Failed to get users. ", "Error: $($_.Exception.Message)" -Color Red, White, Red
            return $false
        }
        foreach ($User in $Users) {
            if ($RequireAccountEnabled) {
                if (-not $User.AccountEnabled) {
                    continue
                }
            }
            if ($RequireAssignedLicenses) {
                if ($User.AssignedLicenses.Count -eq 0) {
                    continue
                }
            }
            Add-Member -MemberType NoteProperty -Name 'Type' -Value $User.UserType -InputObject $User
            $Entry = $User.Id
            $ExistingUsers[$Entry] = $User
        }
    }
    if ($MemberTypes -contains 'Contact') {
        try {
            $Users = Get-MgContact -Property $Script:PropertiesContacts -All
        } catch {
            Write-Color -Text "[e] ", "Failed to get contacts. ", "Error: $($_.Exception.Message)" -Color Red, White, Red
            return $false
        }
        foreach ($User in $Users) {
            $Entry = $User.Id
            Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Contact' -InputObject $User
            $ExistingUsers[$Entry] = $User
        }
    }
    $ExistingUsers
}