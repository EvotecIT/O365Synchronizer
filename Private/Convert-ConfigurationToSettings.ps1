function Convert-ConfigurationToSettings {
    <#
    .SYNOPSIS
    Expands a configuration scriptblock into settings.

    .DESCRIPTION
    Invokes the configuration scriptblock and provides a hook for
    normalizing settings in the future.

    .PARAMETER ConfigurationBlock
    ScriptBlock that returns configuration data.
    #>
    [CmdletBinding()]
    param(
        [scriptblock] $ConfigurationBlock
    )
    $Configuration = & $ConfigurationBlock
    foreach ($C in $ConfigurationBlock) {

    }
}
