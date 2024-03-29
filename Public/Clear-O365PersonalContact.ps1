﻿function Clear-O365PersonalContact {
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

    .PARAMETER FullLogging
    If set it will log all actions. By default it will only log actions that meant contact is getting removed or an error happens.

    .PARAMETER All
    If set it will remove all contacts. By default it will only remove contacts that were synchronized by O365Synchronizer.

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -WhatIf

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -GuidPrefix 'O365' -WhatIf

    .EXAMPLE
    Clear-O365PersonalContact -Identity 'przemyslaw.klys@test.pl' -All -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string] $Identity,
        [string] $GuidPrefix,
        [switch] $FullLogging,
        [switch] $All
    )
    $CurrentContacts = Get-MgUserContact -UserId $Identity -All
    foreach ($Contact in $CurrentContacts) {
        if ($GuidPrefix -and -not $Contact.FileAs.StartsWith($GuidPrefix)) {
            if (-not $All) {
                if ($FullLogging) {
                    Write-Color -Text "[i] ", "Skipping ", $Contact.Id, " because it is not created as part of O365Synchronizer." -Color Yellow, White, DarkYellow, White
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
                    Write-Color -Text "[i] ", "Skipping ", $Contact.Id, " because it is not created as part of O365Synchronizer." -Color Yellow, White, DarkYellow, White
                }
                continue
            }
        }
        Write-Color -Text "[i] ", "Removing ", $Contact.DisplayName, " from ", $Identity, " (WhatIf: $WhatIfPreference)" -Color Yellow, White, Cyan, White, Cyan
        Remove-MgUserContact -UserId $Identity -ContactId $Contact.Id -WhatIf:$WhatIfPreference
    }
}