function Write-O365Log {
    <#
    .SYNOPSIS
    Writes synchronization messages through PSWriteColor.

    .DESCRIPTION
    In Output mode, sends messages directly through the public command's runtime.
    This keeps log strings out of helper return values and intermediate assignments.
    Other streams and file logging retain PSWriteColor's behavior.
    #>
    [CmdletBinding()]
    param(
        [string[]] $Text,
        [ConsoleColor[]] $Color,
        [switch] $NoConsoleOutput
    )

    $OutputCmdlet = $ExecutionContext.SessionState.PSVariable.GetValue('O365LogOutputCmdlet')
    if ($OutputCmdlet) {
        Write-Color @PSBoundParameters | ForEach-Object {
            $OutputCmdlet.WriteObject($_)
        }
    } else {
        Write-Color @PSBoundParameters
    }
}
