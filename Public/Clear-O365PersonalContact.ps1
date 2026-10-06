function Clear-O365PersonalContact {
    <#
    .SYNOPSIS
    Removes personal contacts from user on Office 365.

    .DESCRIPTION
    Removes personal contacts from user on Office 365.
    By default it will only remove contacts that were synchronized by O365Synchronizer.
    If you want to remove all contacts use -All parameter.

    .PARAMETER Identity
    Identity of the user to remove contacts from.

    .PARAMETER GuidPrefix
    Prefix of the GUID that is used to identify contacts that were synchronized by O365Synchronizer.
    By default no prefix is used, meaning GUID of the user will be used as File, As property of the contact.

    .PARAMETER FolderName
    Name of the folder to remove contacts from. If not set it will remove contacts from the main folder.

    .PARAMETER FolderRemove
    If set it will remove the folder as well, once the contacts are removed.
    The folder is removed only when empty; use -All to remove all contacts first if needed.

    .PARAMETER FullLogging
    If set it will log all actions. By default it will only log actions that meant contact is getting removed or an error happens.

    .PARAMETER All
    If set it will remove all contacts. By default it will only remove contacts that were synchronized by O365Synchronizer.

    .PARAMETER LogStream
    Routes messages to Host (default), Output, Verbose, or Information for this call.
    Use -LogStream Output for Azure Automation without enabling verbose job logging.
    Output adds plain log strings to the success stream alongside any returned data.

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -WhatIf

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365' -WhatIf

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -All -WhatIf

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -FolderName 'O365Sync' -FolderRemove -WhatIf

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365Synchronizer' -FullLogging -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Identity,
        [string] $GuidPrefix,
        [string] $FolderName,
        [switch] $FolderRemove,
        [switch] $FullLogging,
        [switch] $All,
        [ValidateSet('Host', 'Output', 'Verbose', 'Information')][string] $LogStream = 'Host'
    )
    # Route Output messages through this command, outside helper data pipelines.
    $O365LogOutputCmdlet = if ($LogStream -eq 'Output') { $PSCmdlet } else { $null }
    # Function-local defaults flow to nested calls without changing module or caller state.
    if ($PSBoundParameters.ContainsKey('LogStream')) {
        $PSDefaultParameterValues = $PSDefaultParameterValues.Clone()
        $PSDefaultParameterValues['Write-Color:OutputStream'] = $LogStream
        if ($PSBoundParameters.ContainsKey('Verbose')) {
            $PSDefaultParameterValues['Write-Color:Verbose'] = $PSBoundParameters['Verbose']
        }
        if ($PSBoundParameters.ContainsKey('InformationAction')) {
            $PSDefaultParameterValues['Write-Color:InformationAction'] = $PSBoundParameters['InformationAction']
        }
    }
    $SupportsFolderContactRemove = $false
    if ($FolderName -and (Get-Command Remove-MgUserContactFolderContact -ErrorAction SilentlyContinue)) {
        $SupportsFolderContactRemove = $true
    }
    if ($FolderName) {
        try {
            $FolderNameEscaped = $FolderName.Replace("'", "''")
            $CurrentContactsFolder = Get-MgUserContactFolder -UserId $Identity -Filter "DisplayName eq '$FolderNameEscaped'" -ErrorAction Stop -All
        } catch {
            Write-O365Log -Text "[!] ", "Getting user folder ", $FolderName, " failed for ", $Identity, ". Error: ", $_.Exception.Message -Color Red, White, Red, White
            return
        }
        if ($CurrentContactsFolder -is [array]) {
            if ($CurrentContactsFolder.Count -gt 1) {
                Write-O365Log -Text "[!] ", "Multiple folders named ", $FolderName, " found for ", $Identity, ". Using the first match." -Color Yellow, White, Red, White, Red
            }
            $CurrentContactsFolder = $CurrentContactsFolder | Select-Object -First 1
        }
        if (-not $CurrentContactsFolder) {
            Write-O365Log -Text "[!] ", "User folder ", $FolderName, " not found for ", $Identity -Color Yellow, Yellow, Red, Yellow, Red
            return
        }
        try {
            $CurrentContacts = Get-MgUserContactFolderContact -ContactFolderId $CurrentContactsFolder.Id -UserId $Identity -ErrorAction Stop -All
        } catch {
            Write-O365Log -Text "[!] ", "Getting user contacts for ", $Identity, " failed. Error: ", $_.Exception.Message -Color Red, White, Red
            return
        }
    } else {
        try {
            $CurrentContacts = Get-MgUserContact -UserId $Identity -All -ErrorAction Stop
        } catch {
            Write-O365Log -Text "[!] ", "Getting user contacts for ", $Identity, " failed. Error: ", $_.Exception.Message -Color Red, White, Red
            return
        }
    }
    foreach ($Contact in $CurrentContacts) {
        if ($GuidPrefix -and -not $Contact.FileAs.StartsWith($GuidPrefix)) {
            if (-not $All) {
                if ($FullLogging) {
                    Write-O365Log -Text "[i] ", "Skipping ", $Contact.Id, " because it is not created as part of O365Synchronizer." -Color Yellow, White, DarkYellow, White
                }
                continue
            }
        } elseif ($GuidPrefix -and $Contact.FileAs.StartsWith($GuidPrefix)) {
            $Contact.FileAs = $Contact.FileAs.Substring($GuidPrefix.Length)
        }
        $Guid = [guid]::Empty
        $ConversionWorked = [guid]::TryParse($Contact.FileAs, [ref]$Guid)
        if (-not $ConversionWorked) {
            if (-not $All) {
                if ($FullLogging) {
                    Write-O365Log -Text "[i] ", "Skipping ", $Contact.Id, " because it is not created as part of O365Synchronizer." -Color Yellow, White, DarkYellow, White
                }
                continue
            }
        }
        Write-O365Log -Text "[i] ", "Removing ", $Contact.DisplayName, " from ", $Identity, " (WhatIf: $WhatIfPreference)" -Color Yellow, White, Cyan, White, Cyan
        try {
            if ($SupportsFolderContactRemove -and $CurrentContactsFolder) {
                Remove-MgUserContactFolderContact -UserId $Identity -ContactFolderId $CurrentContactsFolder.Id -ContactId $Contact.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
            } else {
                Remove-MgUserContact -UserId $Identity -ContactId $Contact.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
            }
        } catch {
            Write-O365Log -Text "[!] ", "Failed to remove contact ", $Contact.Id, " from ", $Identity, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        }
    }
    if ($CurrentContactsFolder -and $FolderName -and $FolderRemove) {
        if (-not $WhatIfPreference) {
            $RemainingContacts = @()
            $MaxAttempts = 3
            for ($Attempt = 1; $Attempt -le $MaxAttempts; $Attempt++) {
                try {
                    $RemainingContacts = Get-MgUserContactFolderContact -ContactFolderId $CurrentContactsFolder.Id -UserId $Identity -ErrorAction Stop -All
                } catch {
                    Write-O365Log -Text "[!] ", "Checking remaining contacts in folder ", $FolderName, " failed for ", $Identity, ". Error: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
                    break
                }
                if (-not $RemainingContacts -or @($RemainingContacts).Count -eq 0) {
                    break
                }
                if ($Attempt -lt $MaxAttempts) {
                    Start-Sleep -Seconds 2
                }
            }

            $RemainingCount = @($RemainingContacts).Count
            if ($RemainingCount -gt 0) {
                Write-O365Log -Text "[!] ", "Folder ", $FolderName, " not removed for ", $Identity, " because it still contains ", $RemainingCount, " contact(s). Use -All or remove remaining contacts first." -Color Yellow, White, Red, White, Red, White, Red, White, Red
                return
            }
        } else {
            Write-O365Log -Text "[i] ", "Skipping empty-folder check for ", $FolderName, " because WhatIf is set." -Color Yellow, White, Cyan, White
        }

        Write-O365Log -Text "[i] ", "Removing folder ", $FolderName, " from ", $Identity, " (WhatIf: $WhatIfPreference)" -Color Yellow, White, Cyan, White, Cyan
        try {
            Remove-MgUserContactFolder -UserId $Identity -ContactFolderId $CurrentContactsFolder.Id -WhatIf:$WhatIfPreference -ErrorAction Stop
        } catch {
            Write-O365Log -Text "[!] ", "Failed to remove folder ", $FolderName, " from ", $Identity, " because: ", $_.Exception.Message -Color Yellow, White, Red, White, Red, White, Red
        }
    }
}
