function Convert-ConfigurationToSettings {
    [CmdletBinding()]
    param(
        [scriptblock] $ConfigurationBlock
    )
    $Configuration = & $ConfigurationBlock
    foreach ($C in $ConfigurationBlock) {

    }
}