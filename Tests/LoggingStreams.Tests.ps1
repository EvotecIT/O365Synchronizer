Describe 'O365Synchronizer message stream integration' {
    InModuleScope O365Synchronizer {
        BeforeEach {
            Mock Get-MgUserContact { @() }
            Mock Get-O365ExistingMembers { [ordered]@{} }
            Mock Initialize-FolderName { [pscustomobject]@{ Id = 'folder-id' } }
        }

        It 'keeps nested contact dictionaries off the verbose stream and logs complete messages' {
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Verbose -Verbose -PassThru 4>&1)
            $messages = @($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })
            @($records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should -Be 0
            $messages.Message | Should -Contain '[i] Contacts to process: 0'
            $messages.Message | Should -Contain '[i] User owner@example.com has 0 contacts, out of which 0 synchronized.'
        }

        It 'restores normal host output after an opted-in call' {
            $null = Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Verbose -Verbose 4>&1
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' 6>&1)
            ($records.MessageData.Message -join '') | Should -Match 'Contacts to process: 0'
        }

        It 'retains nonempty PassThru actions alongside verbose messages' {
            Mock Sync-InternalO365PersonalContact { [pscustomobject]@{ Status = 'OK'; Action = 'Update' } }
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Verbose -Verbose -PassThru 4>&1)
            $actions = @($records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })
            $actions.Count | Should -Be 1
            $actions[0].Status | Should -Be 'OK'
            $actions[0].Action | Should -Be 'Update'
            @($records | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }).Count | Should -BeGreaterThan 0
        }

        It 'honors information selection and suppression across nested module calls' {
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Information -InformationAction Continue 6>&1)
            $records.MessageData | Should -Contain '[i] Contacts to process: 0'
            @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Information -InformationAction Ignore 6>&1).Count | Should -Be 0
        }

        It 'routes cleanup diagnostics without returning messages as data' {
            Mock Get-MgUserContact { throw 'synthetic read failure' }
            $records = @(Clear-O365PersonalContact -Identity 'owner@example.com' -LogStream Verbose -Verbose 4>&1)
            @($records | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should -Be 0
            ($records.Message -join '') | Should -Match 'synthetic read failure'
        }

        It 'preserves stream defaults when organization logging is configured' {
            Mock Get-O365ContactsFromTenant { throw 'synthetic inventory failure' }
            $messages = @(& {
                try {
                    Sync-O365Contact -SourceObjects @([pscustomobject]@{ Mail = 'user@example.com' }) -LogStream Verbose -Verbose -ErrorAction Stop
                } catch {
                    $_.Exception.Message | Should -Be 'synthetic inventory failure'
                }
            } 4>&1)
            ($messages.Message -join '') | Should -Match 'Adding example.com'
        }

        It 'preserves legacy logging defaults when LogStream is omitted' {
            Mock Get-O365ContactsFromTenant { throw 'synthetic inventory failure' }
            $previousDefaults = $script:PSDefaultParameterValues
            $log = Join-Path $TestDrive 'legacy.log'
            try {
                try {
                    Sync-O365Contact -SourceObjects @([pscustomobject]@{ Mail = 'user@example.com' }) -LogPath $log -ErrorAction Stop
                } catch {
                    $_.Exception.Message | Should -Be 'synthetic inventory failure'
                }
                $script:PSDefaultParameterValues['Write-Color:LogFile'] | Should -Be $log
                (Get-Content -LiteralPath $log) -join '' | Should -Match 'Adding example.com'
            } finally {
                $script:PSDefaultParameterValues = $previousDefaults
            }
        }
    }
}
