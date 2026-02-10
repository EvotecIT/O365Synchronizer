function Initialize-FolderName {
    <#
    .SYNOPSIS
    Ensures the target contact folder exists.

    .DESCRIPTION
    Looks up the folder by name and creates it if missing.

    .PARAMETER UserId
    User mailbox identifier.

    .PARAMETER FolderName
    Name of the personal contacts folder.
    #>
    [cmdletbinding()]
    param(
        [string] $UserId,
        [string] $FolderName
    )
    if ($FolderName) {
        $FolderNameEscaped = $FolderName.Replace("'", "''")
        $FolderInformation = Get-MgUserContactFolder -UserId $UserId -Filter "DisplayName eq '$FolderNameEscaped'"
        if (-not $FolderInformation) {
            Write-Color -Text "[!] ", "User folder ", $FolderName, " not found for ", $UserId -Color Yellow, Yellow, Red, Yellow, Red
            # Create folder
            try {
                $FolderInformation = New-MgUserContactFolder -UserId $UserId -DisplayName $FolderName -ErrorAction Stop
            } catch {
                Write-Color -Text "[!] ", "Creating user folder ", $FolderName, " failed for ", $UserId, ". Error: ", $_.Exception.Message -Color Red, White, Red, White, Red, White
                return $false
            }
            if (-not $FolderInformation) {
                Write-Color -Text "[!] ", "Creating user folder ", $FolderName, " failed for ", $UserId -Color Red, White, Red, White
                return $false
            } else {
                Write-Color -Text "[+] ", "User folder ", $FolderName, " created for ", $UserId -Color Yellow, White, Green, White
            }
        }
        $FolderInformation
    }
}
