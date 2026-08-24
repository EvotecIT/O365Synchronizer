function Resolve-O365PersonalContactNickname {
    <#
    .SYNOPSIS
    Resolves the nickname written to a synchronized personal contact.

    .DESCRIPTION
    Returns either the directory display name or mail nickname according to
    the selected synchronization policy.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object] $SourceObject,
        [ValidateSet('DisplayName', 'MailNickname')][string] $NicknameSource = 'DisplayName'
    )

    $Value = $SourceObject.$NicknameSource
    if ($null -eq $Value) {
        return ''
    }

    ([string] $Value).Trim()
}
