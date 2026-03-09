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

                ($result.Update -is [array]) | Should -BeTrue
                ($result.Skip -is [array]) | Should -BeTrue

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

        Context 'Get-O365ExistingMembers manager resolution' {
            It 'resolves manager from string' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '10'
                            UserPrincipalName = 'user10@contoso.com'
                            Mail              = 'user10@contoso.com'
                            OtherMails        = @()
                            AssignedLicenses  = @('license')
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                            Manager           = ' Manager One '
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member')

                $result['10'].Manager | Should -Be 'Manager One'
            }

            It 'resolves manager from object displayName' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '11'
                            UserPrincipalName = 'user11@contoso.com'
                            Mail              = 'user11@contoso.com'
                            OtherMails        = @()
                            AssignedLicenses  = @('license')
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                            Manager           = [pscustomobject]@{ DisplayName = 'Manager Two' }
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member')

                $result['11'].Manager | Should -Be 'Manager Two'
            }

            It 'resolves manager from AdditionalProperties' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '12'
                            UserPrincipalName = 'user12@contoso.com'
                            Mail              = 'user12@contoso.com'
                            OtherMails        = @()
                            AssignedLicenses  = @('license')
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                            Manager           = [pscustomobject]@{
                                AdditionalProperties = @{
                                    displayName      = 'Manager Three'
                                    userPrincipalName = 'manager3@contoso.com'
                                }
                            }
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member')

                $result['12'].Manager | Should -Be 'Manager Three'
            }

            It 'does not set manager when empty' {
                Mock Get-MgUser {
                    @([pscustomobject]@{
                            Id                = '13'
                            UserPrincipalName = 'user13@contoso.com'
                            Mail              = 'user13@contoso.com'
                            OtherMails        = @()
                            AssignedLicenses  = @('license')
                            AccountEnabled    = $true
                            UserType          = 'Member'
                            MemberOf          = @()
                            Manager           = '   '
                        })
                }

                $result = Get-O365ExistingMembers -MemberTypes @('Member')

                $result['13'].PSObject.Properties.Name | Should -Not -Contain 'Manager'
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

        Context 'New-O365InternalContact categories' {
            It 'passes cleaned categories to wrapper' {
                $script:CapturedCategories = $null
                Mock New-O365WrapperPersonalContact {
                    param([string[]] $Categories)
                    $script:CapturedCategories = $Categories
                    $true
                }

                $user = [pscustomobject]@{
                    DisplayName = 'User With Categories'
                    Mail        = 'user@contoso.com'
                    Id          = '00000000-0000-0000-0000-000000000000'
                }

                $result = New-O365InternalContact -UserId 'user@contoso.com' -User $user -GuidPrefix '' -Category @(' Friends ', '', 'Work')

                $result.Status | Should -Be 'OK'
                ($script:CapturedCategories -join ',') | Should -Be 'Friends,Work'
            }
        }

        Context 'Set-O365InternalContact categories' {
            It 'updates categories when they differ' {
                $script:CapturedCategories = $null
                $script:CapturedCategoriesProvided = $false
                Mock Compare-UserToContact {
                    [pscustomobject]@{
                        UserId      = 'user@contoso.com'
                        Action      = 'Update'
                        DisplayName = 'User One'
                        Mail        = 'user@contoso.com'
                        Update      = @()
                        Skip        = @()
                        Details     = ''
                        Error       = ''
                    }
                }
                Mock Set-O365WrapperPersonalContact {
                    param([string[]] $Categories)
                    $script:CapturedCategories = $Categories
                    $script:CapturedCategoriesProvided = $PSBoundParameters.ContainsKey('Categories')
                    [pscustomobject]@{
                        Success      = $true
                        ErrorMessage = ''
                    }
                }

                $user = [pscustomobject]@{
                    DisplayName = 'User One'
                    Mail        = 'user@contoso.com'
                }
                $contact = [pscustomobject]@{
                    Id         = 'contact-id'
                    Categories = @('Old')
                }

                $result = Set-O365InternalContact -UserID 'user@contoso.com' -User $user -Contact $contact -Category @('New', ' Work ')

                $result.Update | Should -Contain 'Categories'
                ($script:CapturedCategories -join ',') | Should -Be 'New,Work'
                $script:CapturedCategoriesProvided | Should -BeTrue
            }

            It 'does not update when categories already match' {
                Mock Compare-UserToContact {
                    [pscustomobject]@{
                        UserId      = 'user@contoso.com'
                        Action      = 'Update'
                        DisplayName = 'User One'
                        Mail        = 'user@contoso.com'
                        Update      = @()
                        Skip        = @()
                        Details     = ''
                        Error       = ''
                    }
                }
                Mock Set-O365WrapperPersonalContact { throw 'Should not be called' }

                $user = [pscustomobject]@{
                    DisplayName = 'User One'
                    Mail        = 'user@contoso.com'
                }
                $contact = [pscustomobject]@{
                    Id         = 'contact-id'
                    Categories = @('Work', 'Friends')
                }

                $result = Set-O365InternalContact -UserID 'user@contoso.com' -User $user -Contact $contact -Category @('Friends', 'Work')

                $result.Status | Should -Be 'Not required'
            }

            It 'clears categories when empty array provided' {
                $script:CapturedCategories = $null
                $script:CapturedCategoriesProvided = $false
                Mock Compare-UserToContact {
                    [pscustomobject]@{
                        UserId      = 'user@contoso.com'
                        Action      = 'Update'
                        DisplayName = 'User One'
                        Mail        = 'user@contoso.com'
                        Update      = @()
                        Skip        = @()
                        Details     = ''
                        Error       = ''
                    }
                }
                Mock Set-O365WrapperPersonalContact {
                    param([string[]] $Categories)
                    $script:CapturedCategories = $Categories
                    $script:CapturedCategoriesProvided = $PSBoundParameters.ContainsKey('Categories')
                    [pscustomobject]@{
                        Success      = $true
                        ErrorMessage = ''
                    }
                }

                $user = [pscustomobject]@{
                    DisplayName = 'User One'
                    Mail        = 'user@contoso.com'
                }
                $contact = [pscustomobject]@{
                    Id         = 'contact-id'
                    Categories = @('Old')
                }

                $result = Set-O365InternalContact -UserID 'user@contoso.com' -User $user -Contact $contact -Category @()

                $result.Update | Should -Contain 'Categories'
                $script:CapturedCategoriesProvided | Should -BeTrue
                $script:CapturedCategories.Count | Should -Be 0
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

        Context 'Get-UniqueO365OrgContactName' {
            It 'uses the smtp local part when available' {
                $reservedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

                $result = Get-UniqueO365OrgContactName -PrimarySmtpAddress 'mario.rossi@contoso.com' -DisplayName 'Mario Rossi' -ReservedNames $reservedNames

                $result | Should -Be 'mario.rossi'
                $reservedNames.Contains('mario.rossi') | Should -BeTrue
            }

            It 'adds a numeric suffix when the preferred name is already reserved' {
                $reservedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                $null = $reservedNames.Add('mario.rossi')

                $result = Get-UniqueO365OrgContactName -PrimarySmtpAddress 'mario.rossi@contoso.com' -DisplayName 'Mario Rossi' -ReservedNames $reservedNames

                $result | Should -Be 'mario.rossi-2'
                $reservedNames.Contains('mario.rossi-2') | Should -BeTrue
            }

            It 'falls back to display name when smtp local part is unavailable' {
                $reservedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

                $result = Get-UniqueO365OrgContactName -PrimarySmtpAddress $null -DisplayName 'Mario Rossi' -ReservedNames $reservedNames

                $result | Should -Be 'Mario Rossi'
            }
        }

        Context 'Get-UniqueO365OrgContactDisplayName' {
            It 'keeps the original display name when available' {
                $reservedDisplayNames = @{}

                $result = Get-UniqueO365OrgContactDisplayName -DisplayName 'Mario Rossi' -ReservedDisplayNames $reservedDisplayNames

                $result | Should -Be 'Mario Rossi'
                $reservedDisplayNames['Mario Rossi'] | Should -Be 1
            }

            It 'adds a numeric suffix when the display name is already reserved' {
                $reservedDisplayNames = @{
                    'Mario Rossi' = 1
                }

                $result = Get-UniqueO365OrgContactDisplayName -DisplayName 'Mario Rossi' -ReservedDisplayNames $reservedDisplayNames

                $result | Should -Be 'Mario Rossi2'
                $reservedDisplayNames['Mario Rossi2'] | Should -Be 1
            }
        }

        Context 'New-O365OrgContact unique naming' {
            It 'creates a new mail contact with a unique internal name' {
                $script:CreatedContactName = $null
                $reservedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                $null = $reservedNames.Add('mario.rossi')
                function New-MailContact {
                    param([string] $Name)
                    $script:CreatedContactName = $Name
                    [pscustomobject]@{ Identity = 'contact-1' }
                }
                Mock Set-O365OrgContact {}

                $source = [pscustomobject]@{
                    DisplayName        = 'Mario Rossi'
                    PrimarySmtpAddress = 'mario.rossi@contoso.com'
                }
                $sourceContact = [pscustomobject]@{
                    DisplayName = 'Mario Rossi'
                }

                New-O365OrgContact -Source $source -SourceContact $sourceContact -ReservedNames $reservedNames

                $script:CreatedContactName | Should -Be 'mario.rossi-2'
                Assert-MockCalled Set-O365OrgContact -Times 1
            }
        }

        Context 'Sync-O365Contact unique display names' {
            It 'assigns visible unique display names to duplicate new contacts when requested' {
                $script:CreatedDisplayNames = [System.Collections.Generic.List[string]]::new()
                Mock Write-Color {}
                Mock Set-LoggingCapabilities {}
                Mock Start-TimeLog { [System.Diagnostics.Stopwatch]::StartNew() }
                Mock Stop-TimeLog { 'done' }
                Mock Convert-GraphObjectToContact {
                    param($SourceObject)
                    [ordered]@{
                        MailContact = [pscustomobject]@{
                            DisplayName        = $SourceObject.DisplayName
                            PrimarySmtpAddress = $SourceObject.Mail
                        }
                        Contact = [pscustomobject]@{
                            DisplayName = $SourceObject.DisplayName
                        }
                    }
                }
                Mock Get-O365ContactsFromTenant {
                    [pscustomobject]@{
                        ContactsCache        = [ordered]@{}
                        ReservedNames        = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                        ReservedDisplayNames = @{}
                    }
                }
                Mock New-O365OrgContact {
                    param($Source)
                    $script:CreatedDisplayNames.Add($Source.DisplayName)
                }

                $sourceObjects = @(
                    [pscustomobject]@{
                        DisplayName = 'Mario Rossi'
                        Mail        = 'mario.rossi@contoso.com'
                    },
                    [pscustomobject]@{
                        DisplayName = 'Mario Rossi'
                        Mail        = 'mario.rossi2@contoso.com'
                    }
                )

                Sync-O365Contact -SourceObjects $sourceObjects -Domains @('contoso.com') -EnsureUniqueDisplayName

                $script:CreatedDisplayNames[0] | Should -Be 'Mario Rossi'
                $script:CreatedDisplayNames[1] | Should -Be 'Mario Rossi2'
            }

            It 'does not rename an unchanged existing contact when the same display name already exists once' {
                $script:UpdatedDisplayNames = [System.Collections.Generic.List[string]]::new()
                Mock Write-Color {}
                Mock Set-LoggingCapabilities {}
                Mock Start-TimeLog { [System.Diagnostics.Stopwatch]::StartNew() }
                Mock Stop-TimeLog { 'done' }
                Mock Convert-GraphObjectToContact {
                    param($SourceObject)
                    [ordered]@{
                        MailContact = [pscustomobject]@{
                            DisplayName        = $SourceObject.DisplayName
                            PrimarySmtpAddress = $SourceObject.Mail
                        }
                        Contact = [pscustomobject]@{
                            DisplayName = $SourceObject.DisplayName
                        }
                    }
                }
                Mock Get-O365ContactsFromTenant {
                    $cache = [ordered]@{
                        'alice@contoso.com' = [ordered]@{
                            MailContact = [pscustomobject]@{
                                DisplayName        = 'Alice'
                                PrimarySmtpAddress = 'alice@contoso.com'
                            }
                            Contact = [pscustomobject]@{
                                DisplayName = 'Alice'
                            }
                        }
                    }
                    [pscustomobject]@{
                        ContactsCache        = $cache
                        ReservedNames        = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
                        ReservedDisplayNames = @{
                            'Alice' = 1
                        }
                    }
                }
                Mock Set-O365OrgContact {
                    param($Source)
                    $script:UpdatedDisplayNames.Add($Source.DisplayName)
                    $true
                }
                Mock New-O365OrgContact {}

                $sourceObjects = @(
                    [pscustomobject]@{
                        DisplayName = 'Alice'
                        Mail        = 'alice@contoso.com'
                    }
                )

                Sync-O365Contact -SourceObjects $sourceObjects -Domains @('contoso.com') -EnsureUniqueDisplayName

                $script:UpdatedDisplayNames[0] | Should -Be 'Alice'
                Assert-MockCalled New-O365OrgContact -Times 0
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
