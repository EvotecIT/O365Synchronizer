function Set-O365Credentials {
    [cmdletbinding()]
    param(
        [string] $TenantID,
        [string] $Domain,
        [string] $ClientID,
        [string] $ClientSecret
    )

    $Credentials = @{
        TenantID     = $TenantID
        Domain       = $Domain
        ClientID     = $ClientID
        ClientSecret = $ClientSecret
    }
    Remove-EmptyValue -Hashtable $Credentials
}