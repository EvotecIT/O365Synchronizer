function Get-O365ExchangeHiddenAddressListCache {
    <#
    .SYNOPSIS
    Builds a lookup cache of Exchange recipients hidden from the address list.

    .DESCRIPTION
    Retrieves Exchange recipients and returns case-insensitive lookups by
    ExternalDirectoryObjectId and SMTP-like address properties for hidden
    recipients only.
    #>
    [CmdletBinding()]
    param()

    $HiddenRecipientsById = @{}
    $HiddenRecipientsByAddress = @{}
    try {
        $Recipients = Get-Recipient -ResultSize Unlimited -ErrorAction Stop
    } catch [System.Management.Automation.CommandNotFoundException] {
        Write-Color -Text "[e] ", "Exchange hidden-address filtering requires an active Exchange Online session. Connect-ExchangeOnline first." -Color Red, White
        return $false
    } catch {
        Write-Color -Text "[e] ", "Failed to get Exchange recipients. ", "Error: $($_.Exception.Message)" -Color Red, White, Red
        return $false
    }

    foreach ($Recipient in $Recipients) {
        if (-not $Recipient.HiddenFromAddressListsEnabled) {
            continue
        }
        if ($Recipient.ExternalDirectoryObjectId) {
            $HiddenRecipientsById[[string] $Recipient.ExternalDirectoryObjectId] = $true
        }

        $AddressCandidates = @(
            if ($Recipient.PrimarySmtpAddress) {
                [string] $Recipient.PrimarySmtpAddress
            }
            if ($Recipient.WindowsEmailAddress) {
                [string] $Recipient.WindowsEmailAddress
            }
            if ($Recipient.ExternalEmailAddress) {
                $ExternalAddress = [string] $Recipient.ExternalEmailAddress
                if ($ExternalAddress -match '^[sS][mM][tT][pP]:(.+)$') {
                    $Matches[1]
                } else {
                    $ExternalAddress
                }
            }
        )
        foreach ($Address in $AddressCandidates) {
            if (-not [string]::IsNullOrWhiteSpace($Address)) {
                $HiddenRecipientsByAddress[$Address.Trim()] = $true
            }
        }
    }

    [PSCustomObject] @{
        ById      = $HiddenRecipientsById
        ByAddress = $HiddenRecipientsByAddress
    }
}
