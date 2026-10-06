Describe 'O365Synchronizer message stream integration' {
    InModuleScope O365Synchronizer {
        BeforeAll {
            $script:RealInitializeFolderName = (Get-Command Initialize-FolderName).ScriptBlock
            $script:RealGetContactsFromTenant = (Get-Command Get-O365ContactsFromTenant).ScriptBlock
            # Exchange commands are external boundaries and are not required modules.
            function Get-Contact { param($ResultSize) }
            function Get-MailContact { param($ResultSize) }
        }
        BeforeEach {
            Mock Get-MgUserContact { @() }
            Mock Get-O365ExistingMembers { [ordered]@{} }
            Mock Initialize-FolderName { [pscustomobject]@{ Id = 'folder-id' } }
        }

        It 'emits nested messages as plain output without capturing them as contact data' {
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Output -Verbose:$false -InformationAction Ignore -PassThru *>&1)
            $records | Should -Contain '[i] Contacts to process: 0'
            $records | Should -Contain '[i] User owner@example.com has 0 contacts, out of which 0 synchronized.'
            @($records | Where-Object { $_ -isnot [string] }).Count | Should -Be 0
            Should -Invoke Get-MgUserContact -Times 1 -Exactly
        }

        It 'preserves action objects alongside output messages from assigned helper results' {
            Mock Get-O365ExistingMembers { [ordered]@{ 'source-id' = [pscustomobject]@{ Id = 'source-id'; DisplayName = 'Source User'; Mail = 'source@example.com' } } }
            Mock New-O365WrapperPersonalContact { $true }
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Output -PassThru)
            $actions = @($records | Where-Object { $_ -isnot [string] })
            $actions.Count | Should -Be 1
            $actions[0].Status | Should -Be 'OK'
            $actions[0].Action | Should -Be 'New'
            $records | Should -Contain '[+] Creating Source User / source@example.com'
            Should -Invoke New-O365WrapperPersonalContact -Times 1 -Exactly

            $withoutActions = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Output)
            @($withoutActions | Where-Object { $_ -isnot [string] }).Count | Should -Be 0
            $withoutActions | Should -Contain '[+] Creating Source User / source@example.com'
        }

        It 'keeps folder creation diagnostics out of folder metadata' {
            # Use the real folder helper rather than the default boundary mock.
            Mock Initialize-FolderName { & $script:RealInitializeFolderName -UserId $UserId -FolderName $FolderName }
            Mock Get-MgUserContactFolder { if ($All) { [pscustomobject]@{ Id = 'created-folder' } } else { @() } }
            Mock New-MgUserContactFolder { [pscustomobject]@{ Id = 'created-folder' } }
            Mock Get-MgUserContactFolderContact { @() }
            Mock Sync-InternalO365PersonalContact { [pscustomobject]@{ Status = 'OK'; Action = 'Test'; FolderId = $FolderInformation.Id } }
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -FolderName 'Sync' -LogStream Output -PassThru)
            ($records | Where-Object { $_ -isnot [string] }).FolderId | Should -Be 'created-folder'
            $records | Should -Contain '[+] User folder Sync created for owner@example.com'
        }

        It 'routes failed contact reads to output and stops before synchronization' {
            Mock Get-MgUserContact { throw 'synthetic read failure' }
            Mock Sync-InternalO365PersonalContact { throw 'must not run after a failed read' }
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Output -PassThru)
            ($records -join '') | Should -Match 'synthetic read failure'
            @($records | Where-Object { $_ -isnot [string] }).Count | Should -Be 0
            Should -Invoke Sync-InternalO365PersonalContact -Times 0
        }

        It 'routes cleanup diagnostics to output without verbose logging' {
            Mock Get-MgUserContact { throw 'synthetic read failure' }
            $records = @(Clear-O365PersonalContact -Identity 'owner@example.com' -LogStream Output -Verbose:$false *>&1)
            $records.Count | Should -Be 1
            $records[0] | Should -BeOfType ([string])
            $records[0] | Should -Match 'synthetic read failure'
        }

        It 'keeps discovered domains and tenant inventory separate from output logs' {
            Mock Get-Contact { @() }
            Mock Get-MailContact { @() }
            Mock Get-O365ContactsFromTenant {
                @($Domains).Count | Should -Be 1
                $Domains[0] | Should -Be 'example.com'
                & $script:RealGetContactsFromTenant -Domains $Domains
            }
            Mock New-O365OrgContact { $null }
            $records = @(Sync-O365Contact -SourceObjects @([pscustomobject]@{ Mail = 'user@example.com'; DisplayName = 'User' }) -LogStream Output -WhatIf)
            $records | Should -Contain '[i] Adding example.com to list of domains to synchronize'
            ($records -join '') | Should -Match 'Finished synchronization of 1 objects'
            Should -Invoke New-O365OrgContact -Times 1 -Exactly
        }

        It 'restores normal host output after an output call' {
            $null = Sync-O365PersonalContact -UserId 'owner@example.com' -LogStream Output
            @(Sync-O365PersonalContact -UserId 'owner@example.com' -InformationAction Ignore).Count | Should -Be 0
            $records = @(Sync-O365PersonalContact -UserId 'owner@example.com' 6>&1)
            ($records.MessageData.Message -join '') | Should -Match 'Contacts to process: 0'
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
