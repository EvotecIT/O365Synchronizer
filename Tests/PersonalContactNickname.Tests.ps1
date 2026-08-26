Describe 'O365Synchronizer personal contact nickname policy' {
    InModuleScope O365Synchronizer {
        BeforeAll {
            Initialize-DefaultValuesO365
        }

        BeforeEach {
            $script:CapturedNickname = $null
            $script:CapturedNicknameSource = $null
        }

        It 'uses the display name for newly synchronized contacts by default' {
            Mock New-O365WrapperPersonalContact {
                param([string] $NickName)
                $script:CapturedNickname = $NickName
                $true
            }
            $user = [pscustomobject]@{
                Id           = '11111111-1111-1111-1111-111111111111'
                DisplayName  = 'Chuck Norris | Contoso'
                MailNickname = 'chuck.norris'
                Mail         = 'chuck.norris@contoso.com'
            }

            $result = New-O365InternalContact -UserId 'owner@contoso.com' -User $user -GuidPrefix ''

            $result.Status | Should -Be 'OK'
            $script:CapturedNickname | Should -Be 'Chuck Norris | Contoso'
        }

        It 'can preserve the legacy mail nickname for newly synchronized contacts' {
            Mock New-O365WrapperPersonalContact {
                param([string] $NickName)
                $script:CapturedNickname = $NickName
                $true
            }
            $user = [pscustomobject]@{
                Id           = '11111111-1111-1111-1111-111111111111'
                DisplayName  = 'Chuck Norris | Contoso'
                MailNickname = 'chuck.norris'
                Mail         = 'chuck.norris@contoso.com'
            }

            $null = New-O365InternalContact -UserId 'owner@contoso.com' -User $user -GuidPrefix '' -NicknameSource MailNickname

            $script:CapturedNickname | Should -Be 'chuck.norris'
        }

        It 'repairs a legacy mail alias on an existing contact by default' {
            $user = [pscustomobject]@{
                DisplayName  = 'Chuck Norris | Contoso'
                MailNickname = 'chuck.norris'
                Mail         = 'chuck.norris@contoso.com'
            }
            $contact = [pscustomobject]@{
                Id             = 'contact-1'
                DisplayName    = 'Chuck Norris | Contoso'
                Nickname       = 'chuck.norris'
                EmailAddresses = @([pscustomobject]@{ Address = 'chuck.norris@contoso.com' })
            }

            $result = Compare-UserToContact -ExistingContactGAL $user -Contact $contact -UserID 'owner@contoso.com'

            $result.Update | Should -Contain 'NickName'
        }

        It 'does not rewrite a matching legacy alias in compatibility mode' {
            $user = [pscustomobject]@{
                DisplayName  = 'Chuck Norris | Contoso'
                MailNickname = 'chuck.norris'
                Mail         = 'chuck.norris@contoso.com'
            }
            $contact = [pscustomobject]@{
                Id             = 'contact-1'
                DisplayName    = 'Chuck Norris | Contoso'
                Nickname       = 'chuck.norris'
                EmailAddresses = @([pscustomobject]@{ Address = 'chuck.norris@contoso.com' })
            }

            $result = Compare-UserToContact -ExistingContactGAL $user -Contact $contact -UserID 'owner@contoso.com' -NicknameSource MailNickname

            $result.Update | Should -Not -Contain 'NickName'
            $result.Skip | Should -Contain 'NickName'
        }

        It 'writes the resolved nickname when updating an existing contact' {
            Mock Set-O365WrapperPersonalContact {
                param([string] $NickName)
                $script:CapturedNickname = $NickName
                [pscustomobject]@{ Success = $true; ErrorMessage = '' }
            }
            $user = [pscustomobject]@{
                DisplayName  = 'Chuck Norris | Contoso'
                MailNickname = 'chuck.norris'
                Mail         = 'chuck.norris@contoso.com'
            }
            $contact = [pscustomobject]@{
                Id             = 'contact-1'
                DisplayName    = 'Chuck Norris | Contoso'
                Nickname       = 'chuck.norris'
                EmailAddresses = @([pscustomobject]@{ Address = 'chuck.norris@contoso.com' })
            }

            $result = Set-O365InternalContact -UserID 'owner@contoso.com' -User $user -Contact $contact

            $result.Status | Should -Be 'OK'
            $script:CapturedNickname | Should -Be 'Chuck Norris | Contoso'
        }

        It 'forwards the public nickname policy into mailbox synchronization' {
            Mock Get-O365ExistingMembers { [ordered]@{} }
            Mock Initialize-FolderName { [pscustomobject]@{ Id = 'folder-id' } }
            Mock Get-O365ExistingUserContacts { [ordered]@{} }
            Mock Sync-InternalO365PersonalContact {
                $script:CapturedNicknameSource = $NicknameSource
                @()
            }

            Sync-O365PersonalContact -UserId 'owner@contoso.com' -NicknameSource MailNickname

            $script:CapturedNicknameSource | Should -Be 'MailNickname'
        }
    }
}
