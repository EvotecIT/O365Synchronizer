function Initialize-FolderName {
    [cmdletbinding()]
    param(
        [string] $UserId,
        [string] $FolderName
    )
    if ($FolderName) {
        $FolderInformation = Get-MgUserContactFolder -UserId $UserId -Filter "DisplayName eq '$FolderName'"
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