function Set-LoggingCapabilities {
    <#
    .SYNOPSIS
    Configures Write-Color logging defaults.

    .DESCRIPTION
    Sets default logging parameters and optionally prunes old log files.

    .PARAMETER LogPath
    Path to the log file.

    .PARAMETER LogMaximum
    Maximum number of matching log files to keep, including the active log.

    .PARAMETER LogFilePattern
    Explicit filename wildcard identifying this job's logs. Must match the active
    log filename. Without a pattern, no files are removed.

    .PARAMETER ShowTime
    Enables timestamp output.

    .PARAMETER TimeFormat
    Format string for timestamps.

    .PARAMETER ParameterPSDefaultParameterValues
    Invocation-local defaults to update without replacing other logging settings.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string] $LogPath,
        [int] $LogMaximum,
        [switch] $ShowTime,
        [string] $TimeFormat,
        [ValidateNotNullOrEmpty()][ValidatePattern('^[^\\/:]+$')][string] $LogFilePattern,
        [System.Collections.IDictionary] $ParameterPSDefaultParameterValues
    )

    if ($null -eq $ParameterPSDefaultParameterValues) {
        $Script:PSDefaultParameterValues = @{}
        $ParameterPSDefaultParameterValues = $Script:PSDefaultParameterValues
    }
    $ParameterPSDefaultParameterValues['Write-Color:LogFile'] = $LogPath
    $ParameterPSDefaultParameterValues['Write-Color:ShowTime'] = if ($PSBoundParameters.ContainsKey('ShowTime')) { $ShowTime.IsPresent } else { $null }
    $ParameterPSDefaultParameterValues['Write-Color:TimeFormat'] = $TimeFormat
    Remove-EmptyValue -Hashtable $ParameterPSDefaultParameterValues

    if ($LogPath) {
        $FullLogPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($LogPath)
        $FolderPath = [io.path]::GetDirectoryName($FullLogPath)
        if ($LogFilePattern -and [io.path]::GetFileName($FullLogPath) -notlike $LogFilePattern) {
            throw 'LogFilePattern must match the active log filename.'
        }
        if (-not (Test-Path -LiteralPath $FolderPath)) {
            $null = New-Item -Path $FolderPath -ItemType Directory -Force -WhatIf:$false
        }
        if ($LogMaximum -gt 0) {
            if (-not $LogFilePattern) {
                Write-Warning 'Log retention skipped: specify LogFilePattern to identify the files owned by this job.'
                return
            }
            # Reserve one slot for the active log, even when it has not been created yet.
            $CurrentLogs = Get-ChildItem -LiteralPath $FolderPath -File -ErrorAction Stop |
                Where-Object {
                    $_.Name -like $LogFilePattern -and
                    $_.FullName -ne $FullLogPath -and
                    -not ($_.Attributes -band [io.fileattributes]::ReparsePoint)
                } |
                Sort-Object -Property CreationTime, Name -Descending |
                Select-Object -Skip ($LogMaximum - 1)
            if ($CurrentLogs) {
                Write-O365Log -Text '[i] ', "Logs directory has more than ", $LogMaximum, " log files. Cleanup required..." -Color Yellow, DarkCyan, Red, DarkCyan
                foreach ($Log in $CurrentLogs) {
                    if (-not $PSCmdlet.ShouldProcess($Log.FullName, 'Remove retained log file')) {
                        continue
                    }
                    try {
                        Remove-Item -LiteralPath $Log.FullName -Confirm:$false -ErrorAction Stop
                        Write-O365Log -Text '[+] ', "Deleted ", "$($Log.FullName)" -Color Yellow, White, Green
                    } catch {
                        Write-O365Log -Text '[-] ', "Couldn't delete log file $($Log.FullName). Error: ", $_.Exception.Message -Color Yellow, White, Red
                    }
                }
            }
        } else {
            Write-O365Log -Text '[i] ', "LogMaximum is set to 0 (Unlimited). No log files will be deleted." -Color Yellow, DarkCyan
        }
    }
}
