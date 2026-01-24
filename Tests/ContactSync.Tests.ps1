Describe 'O365Synchronizer contact sync helpers' {
    InModuleScope O365Synchronizer {
        BeforeAll {
            Initialize-DefaultValuesO365
        }

        Context 'Compare-UserToContact address updates' {
            It 'updates all address fields when any address field changes' {
                $existing = [pscustomobject]@{
                    DisplayName    = 'User One'
                    Mail           = 'user1@example.com'
                    MailNickname   = 'user1'
                    GivenName      = 'User'
                    Surname        = 'One'
                    CompanyName    = 'Evotec'
                    BusinessPhones = '123'
                    MobilePhone    = '111'
                    HomePhone      = '222'
                    JobTitle       = 'Engineer'
                    Country        = 'PL'
                    City           = 'Warsaw'
                    State          = 'Mazovia'
                    Street         = 'Old Street'
                    PostalCode     = '00-000'
                }

                $contact = [pscustomobject]@{
                    Nickname       = 'user1'
                    DisplayName    = 'User One'
                    GivenName      = 'User'
                    Surname        = 'One'
                    EmailAddresses = @([pscustomobject]@{ Address = 'user1@example.com' })
                    BusinessPhones = '123'
                    MobilePhone    = '111'
                    HomePhone      = '222'
                    CompanyName    = 'Evotec'
                    JobTitle       = 'Engineer'
                    BusinessAddress = [pscustomobject]@{
                        CountryOrRegion = 'PL'
                        City            = 'Warsaw'
                        State           = 'Mazovia'
                        Street          = 'New Street'
                        PostalCode      = '00-000'
                    }
                }

                $result = Compare-UserToContact -ExistingContactGAL $existing -Contact $contact -UserID 'user1@example.com'

                $addressProperties = @('City', 'State', 'Street', 'PostalCode', 'Country')
                foreach ($Property in $addressProperties) {
                    $result.Update | Should -Contain $Property
                }
            }
        }

        Context 'Compare-UserToContact department and manager updates' {
            It 'updates department and manager when changed' {
                $existing = [pscustomobject]@{
                    DisplayName    = 'User Two'
                    Mail           = 'user2@example.com'
                    MailNickname   = 'user2'
                    GivenName      = 'User'
                    Surname        = 'Two'
                    CompanyName    = 'Evotec'
                    BusinessPhones = '123'
                    MobilePhone    = '111'
                    HomePhone      = '222'
                    JobTitle       = 'Engineer'
                    Department     = 'Sales'
                    Manager        = 'Boss One'
                    Country        = 'PL'
                    City           = 'Warsaw'
                    State          = 'Mazovia'
                    Street         = 'Street'
                    PostalCode     = '00-000'
                }

                $contact = [pscustomobject]@{
                    Nickname       = 'user2'
                    DisplayName    = 'User Two'
                    GivenName      = 'User'
                    Surname        = 'Two'
                    EmailAddresses = @([pscustomobject]@{ Address = 'user2@example.com' })
                    BusinessPhones = '123'
                    MobilePhone    = '111'
                    HomePhone      = '222'
                    CompanyName    = 'Evotec'
                    JobTitle       = 'Engineer'
                    Department     = 'Support'
                    Manager        = 'Boss Two'
                    BusinessAddress = [pscustomobject]@{
                        CountryOrRegion = 'PL'
                        City            = 'Warsaw'
                        State           = 'Mazovia'
                        Street          = 'Street'
                        PostalCode      = '00-000'
                    }
                }

                $result = Compare-UserToContact -ExistingContactGAL $existing -Contact $contact -UserID 'user2@example.com'

                $result.Update | Should -Contain 'Department'
                $result.Update | Should -Contain 'Manager'
            }
        }

        Context 'New-O365InternalContact require email' {
            It 'skips users without email when RequireEmailAddress is set' {
                Mock New-O365WrapperPersonalContact { throw 'Should not be called' }

                $user = [pscustomobject]@{
                    DisplayName = 'No Mail'
                    Mail        = $null
                    Id          = '00000000-0000-0000-0000-000000000000'
                }

                $result = New-O365InternalContact -UserId 'user@contoso.com' -User $user -GuidPrefix '' -RequireEmailAddress

                $result.Status | Should -Be 'Skipped'
                $result.Skip | Should -Be 'RequireEmailAddress'
            }
        }

        Context 'Set-O365WrapperPersonalContact result' {
            It 'returns success when update succeeds' {
                Mock Update-MgUserContact {}

                $result = Set-O365WrapperPersonalContact -UserId 'user@contoso.com' -ContactId 'contact-id' -DisplayName 'User One'

                $result.Success | Should -BeTrue
                $result.ErrorMessage | Should -Be ''
            }

            It 'returns error message when update fails' {
                Mock Update-MgUserContact { throw 'boom' }

                $result = Set-O365WrapperPersonalContact -UserId 'user@contoso.com' -ContactId 'contact-id' -DisplayName 'User One'

                $result.Success | Should -BeFalse
                $result.ErrorMessage | Should -Match 'boom'
            }

            It 'filters empty values from arrays before update' {
                Mock Update-MgUserContact {}

                $result = Set-O365WrapperPersonalContact -UserId 'user@contoso.com' -ContactId 'contact-id' -DisplayName 'User One' -EmailAddresses @('', 'user@contoso.com') -BusinessPhones @('', '123') -HomePhones @('') -ImAddresses @('im1', '')

                $result.Success | Should -BeTrue
                Assert-MockCalled Update-MgUserContact -Times 1 -ParameterFilter {
                    $EmailAddresses.Count -eq 1 -and
                    $EmailAddresses[0].Address -eq 'user@contoso.com' -and
                    $BusinessPhones -eq @('123') -and
                    $ImAddresses -eq @('im1') -and
                    -not $PSBoundParameters.ContainsKey('HomePhones')
                }
            }
        }

        Context 'Get-O365ExistingMembers external mail handling' {
            It 'uses OtherMails when Mail is empty' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '1'
                            UserPrincipalName = 'ext_user#EXT#@tenant.onmicrosoft.com'
                            Mail              = $null
                            OtherMails        = @('', ' external@domain.com ')
                            AssignedLicenses  = @()
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member')

                $result['1'].Mail | Should -Be 'external@domain.com'
            }

            It 'filters external users without licenses when RequireAssignedLicenses is set and no override' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '2'
                            UserPrincipalName = 'ext_user#EXT#@tenant.onmicrosoft.com'
                            Mail              = 'external@domain.com'
                            OtherMails        = @()
                            AssignedLicenses  = @()
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member') -RequireAssignedLicenses

                $result['2'] | Should -BeNullOrEmpty
            }

            It 'keeps external users without licenses when IncludeExternalUsers contains ExtUPN' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '3'
                            UserPrincipalName = 'ext_user#EXT#@tenant.onmicrosoft.com'
                            Mail              = 'external@domain.com'
                            OtherMails        = @()
                            AssignedLicenses  = @()
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member') -RequireAssignedLicenses -IncludeExternalUsers 'ExtUPN'

                $result['3'] | Should -Not -BeNullOrEmpty
            }

            It 'keeps guest users without licenses when IncludeExternalUsers contains Guest' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '4'
                            UserPrincipalName = 'guest_user@external.com'
                            Mail              = 'guest@external.com'
                            OtherMails        = @()
                            AssignedLicenses  = @()
                            AccountEnabled    = $true
                            UserType          = 'Guest'
                            MemberOf          = @()
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member') -RequireAssignedLicenses -IncludeExternalUsers 'Guest'

                $result['4'] | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Get-O365ExistingMembers OData and nested property filters' {
            It 'passes OData filter settings to Get-MgUser' {
                Mock Get-MgUser { @() }

                $null = Get-O365ExistingMembers -MemberTypes @('Member') -UserProvidedFilter {
                    Sync-O365PersonalContactFilterOData -Filter "onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTERCRITERIA'" -ConsistencyLevel eventual -CountVariable userCount -PageSize 999
                }

                Assert-MockCalled Get-MgUser -Times 1 -ParameterFilter {
                    $Filter -eq "(onPremisesExtensionAttributes/extensionAttribute5 eq 'MYFILTERCRITERIA')" -and
                    $ConsistencyLevel -eq 'eventual' -and
                    $CountVariable -eq 'userCount' -and
                    $PageSize -eq 999
                }
            }

            It 'supports nested property path filtering' {
                $user = [pscustomobject]@{
                    Id                             = '5'
                    UserPrincipalName              = 'user@contoso.com'
                    Mail                           = 'user@contoso.com'
                    OtherMails                     = @()
                    AssignedLicenses               = @('license')
                    AccountEnabled                 = $true
                    UserType                       = 'Member'
                    MemberOf                       = @()
                    OnPremisesExtensionAttributes  = [pscustomobject]@{
                        ExtensionAttribute5 = 'MYFILTERCRITERIA'
                    }
                }
                Mock Get-MgUser { @($user) }

                $result = Get-O365ExistingMembers -MemberTypes @('Member') -UserProvidedFilter {
                    Sync-O365PersonalContactFilter -Type Include -Property 'OnPremisesExtensionAttributes.ExtensionAttribute5' -Value @('MYFILTERCRITERIA') -Operator 'Equal'
                }

                $result['5'] | Should -Not -BeNullOrEmpty
            }
        }

        Context 'Set-O365InternalContact error propagation' {
            It 'preserves update details and returns error on failure' {
                Mock Compare-UserToContact {
                    [pscustomobject]@{
                        UserId      = 'user@contoso.com'
                        Action      = 'Update'
                        DisplayName = 'User One'
                        Mail        = 'user@contoso.com'
                        Update      = @('DisplayName')
                        Skip        = @()
                        Details     = ''
                        Error       = ''
                    }
                }
                Mock Set-O365WrapperPersonalContact {
                    [pscustomobject]@{
                        Success      = $false
                        ErrorMessage = 'update failed'
                    }
                }

                $user = [pscustomobject]@{
                    DisplayName = 'User One'
                    Mail        = 'user@contoso.com'
                }
                $contact = [pscustomobject]@{ Id = 'contact-id' }

                $result = Set-O365InternalContact -UserID 'user@contoso.com' -User $user -Contact $contact

                $result.Status | Should -Be 'Failed'
                $result.Error | Should -Be 'update failed'
                $result.Update | Should -Contain 'DisplayName'
            }
        }
    }
}
