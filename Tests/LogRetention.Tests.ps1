Describe 'O365Synchronizer log retention' {
    InModuleScope O365Synchronizer {
        BeforeEach {
            $script:SavedLoggingDefaults = $script:PSDefaultParameterValues
            Mock Write-Color {}
            $folder = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            $null = New-Item -Path $folder -ItemType Directory
            foreach ($name in 'sync-current.log', 'sync-old.log', 'sync-new.log', 'other.log', 'notes.txt') {
                $path = Join-Path $folder $name
                Set-Content -LiteralPath $path -Value $name
                (Get-Item -LiteralPath $path).CreationTimeUtc = [datetime]'2020-01-01'
            }
            (Get-Item -LiteralPath (Join-Path $folder 'sync-new.log')).CreationTimeUtc = [datetime]'2021-01-01'
            $null = New-Item -Path (Join-Path $folder 'sync-directory.log') -ItemType Directory
            Set-Content -LiteralPath (Join-Path $folder 'sync-directory.log/keep.txt') -Value 'keep'
            $active = Join-Path $folder 'sync-current.log'
        }

        AfterEach {
            $script:PSDefaultParameterValues = $script:SavedLoggingDefaults
        }

        It 'prunes only matching archives and reserves the oldest active log' {
            Set-LoggingCapabilities -LogPath $active -LogMaximum 2 -LogFilePattern 'sync-*.log'

            Test-Path -LiteralPath (Join-Path $folder 'sync-old.log') | Should -BeFalse
            foreach ($name in 'sync-current.log', 'sync-new.log', 'other.log', 'notes.txt', 'sync-directory.log/keep.txt') {
                Test-Path -LiteralPath (Join-Path $folder $name) | Should -BeTrue
            }
        }

        It 'does not infer ownership when no pattern is supplied' {
            Set-LoggingCapabilities -LogPath $active -LogMaximum 1 -WarningAction SilentlyContinue
            @(Get-ChildItem -LiteralPath $folder -File).Count | Should -Be 5
        }

        It 'does not prune when retention is disabled' {
            Set-LoggingCapabilities -LogPath $active -LogMaximum 0 -LogFilePattern 'sync-*.log'
            @(Get-ChildItem -LiteralPath $folder -File).Count | Should -Be 5
        }

        It 'honors WhatIf through the public synchronization command' {
            Mock Get-O365ContactsFromTenant { throw 'end of retention check' }
            try {
                Sync-O365Contact -SourceObjects @([pscustomobject]@{ Mail = 'user@example.com' }) -LogPath $active -LogMaximum 1 -LogFilePattern 'sync-*.log' -WhatIf -ErrorAction Stop
            } catch {
                $_.Exception.Message | Should -Be 'end of retention check'
            }
            @(Get-ChildItem -LiteralPath $folder -File).Count | Should -Be 5
        }

        It 'reserves a slot before the current log exists and supports relative paths' {
            Push-Location $folder
            try {
                Set-LoggingCapabilities -LogPath './sync-next.log' -LogMaximum 2 -LogFilePattern 'sync-*.log'
            } finally {
                Pop-Location
            }
            @(Get-ChildItem -LiteralPath $folder -File | Where-Object Name -like 'sync-*.log').Name | Should -Be @('sync-new.log')
            Test-Path -LiteralPath (Join-Path $folder 'other.log') | Should -BeTrue
        }

        It 'rejects a pattern for another job before removing any files' {
            { Set-LoggingCapabilities -LogPath $active -LogMaximum 1 -LogFilePattern 'other*' } | Should -Throw '*must match*'
            @(Get-ChildItem -LiteralPath $folder -File).Count | Should -Be 5
        }

        It 'reports a deletion failure without claiming that the file was deleted' {
            Mock Remove-Item { throw 'access denied' }
            Set-LoggingCapabilities -LogPath $active -LogMaximum 2 -LogFilePattern 'sync-*.log'
            Test-Path -LiteralPath (Join-Path $folder 'sync-old.log') | Should -BeTrue
            Should -Invoke Write-Color -Times 0 -ParameterFilter { $Text -contains 'Deleted ' }
            Should -Invoke Write-Color -Times 1 -ParameterFilter { ($Text -join '') -match 'access denied' }
        }
    }
}
