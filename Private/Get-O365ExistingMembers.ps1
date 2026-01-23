function Get-O365ExistingMembers {
    [cmdletbinding()]
    param(
        [scriptblock] $UserProvidedFilter,
        [string[]] $MemberTypes,
        [switch] $RequireAccountEnabled,
        [switch] $RequireAssignedLicenses
    )

    # Build filtering system
    if ($UserProvidedFilter) {
        try {
            $FilterInformation = & $UserProvidedFilter
        } catch {
            Write-Color -Text "[e] ", "Failed to execute user provided filter because of error in line ", $_.InvocationInfo.ScriptLineNumber, " with message: ", $_.Exception.Message -Color Yellow, White, Red
            return $false
        }
    } else {
        $FilterInformation = @()
    }
    $GroupIDs = [ordered] @{}
    $GroupIDsExclude = [ordered] @{}
    $PropertyFilter = [ordered] @{}
    $PropertyFilterExclude = [ordered] @{}
    foreach ($Filter in $FilterInformation) {
        if ($Filter.FilterType -eq 'Group') {
            if ($Filter.Type -eq 'Include') {
                foreach ($GroupID in $Filter.GroupID) {
                    $GroupIDs[$GroupID] = $true
                }
            } elseif ($Filter.Type -eq 'Exclude') {
                foreach ($GroupID in $Filter.GroupID) {
                    $GroupIDsExclude[$GroupID] = $true
                }
            }
        } elseif ($Filter.FilterType -eq 'Property') {
            if ($Filter.Type -eq 'Include') {
                $PropertyFilter[$Filter.Property] = $Filter
            } elseif ($Filter.Type -eq 'Exclude') {
                $PropertyFilterExclude[$Filter.Property] = $Filter
            }
        } else {
            Write-Color -Text "[e] ", "Unknown filter type: $($Filter.FilterType)" -Color Red, White
            return $false
        }
    }
    # Lets get all users and cache them
    $ExistingUsers = [ordered] @{}
    if ($MemberTypes -contains 'Member' -or $MemberTypes -contains 'Guest') {
        try {
            $getMgUserSplat = @{
                Property    = $Script:PropertiesUsers
                All         = $true
                ErrorAction = 'Stop'
            }
            $Users = Get-MgUser @getMgUserSplat
        } catch {
            Write-Color -Text "[e] ", "Failed to get users. ", "Error: $($_.Exception.Message)" -Color Red, White, Red
            return $false
        }
        :NextUser foreach ($User in $Users) {
            #Write-Verbose -Message "Gathering user $($User.UserPrincipalName)"
            if ($RequireAccountEnabled) {
                if (-not $User.AccountEnabled) {
                    Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by account is disabled"
                    continue
                }
            }
            if ($RequireAssignedLicenses) {
                if ($User.AssignedLicenses.Count -eq 0) {
                    Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by no assigned licenses"
                    continue
                }
            }
            if ($GroupIDs.Keys.Count -gt 0) {
                try {
                    $UserGroups = Get-MgUserMemberOf -UserId $User.Id -All
                } catch {
                    Write-Color -Text "[e] ", "Failed to get groups for user $($User.UserPrincipalName). ", "Error: $($_.Exception.Message)" -Color Yellow, White, Red
                    continue
                }
                if ($UserGroups.Count -eq 0) {
                    continue
                }
                $GroupExclude = $false
                foreach ($Group in $UserGroups) {
                    if ($GroupIDsExclude.Keys -contains $Group.Id) {
                        $GroupExclude = $true
                        break
                    }
                }
                if ($GroupExclude -eq $true) {
                    Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by group exclusion"
                    continue
                }
                $GroupInclude = $false
                foreach ($Group in $UserGroups) {
                    if ($GroupIDs.Keys -contains $Group.Id) {
                        $GroupInclude = $true
                        break
                    }
                }
                if ($GroupInclude -eq $false) {
                    Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by group inclusion"
                    continue
                }
            }
            foreach ($Property in $PropertyFilterExclude.Keys) {
                $Filter = $PropertyFilterExclude[$Property]
                $Value = $User.$Property
                if ($Filter.Operator -eq 'Like') {
                    $Find = $false
                    foreach ($FilterValue in $Filter.Value) {
                        if ($Value -like $FilterValue) {
                            $Find = $true
                        }
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'Equal') {
                    $Find = $false
                    if ($Filter.Value -contains $Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'NotEqual') {
                    $Find = $false
                    if ($Filter.Value -notcontains $Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'LessThan') {
                    $Find = $false
                    if ($Value -lt $Filter.Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'MoreThan') {
                    $Find = $false
                    if ($Value -gt $Filter.Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } else {
                    Write-Color -Text "[e] ", "Unknown operator: $($Filter.Operator)" -Color Red, White
                    return $false
                }
            }
            foreach ($Property in $PropertyFilter.Keys) {
                $Filter = $PropertyFilter[$Property]
                $Value = $User.$Property
                if ($Filter.Operator -eq 'Like') {
                    $Find = $false
                    foreach ($FilterValue in $Filter.Value) {
                        if ($Value -like $FilterValue) {
                            $Find = $true
                        }
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'Equal') {
                    $Find = $false
                    if ($Filter.Value -contains $Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'NotEqual') {
                    $Find = $false
                    if ($Filter.Value -notcontains $Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'LessThan') {
                    $Find = $false
                    if ($Value -lt $Filter.Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'MoreThan') {
                    $Find = $false
                    if ($Value -gt $Filter.Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out user $($User.UserPrincipalName) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } else {
                    Write-Color -Text "[e] ", "Unknown operator: $($Filter.Operator)" -Color Red, White
                    return $false
                }
            }
            Add-Member -MemberType NoteProperty -Name 'Type' -Value $User.UserType -InputObject $User
            $Entry = $User.Id
            $ExistingUsers[$Entry] = $User
        }
    }
    if ($MemberTypes -contains 'Contact') {
        try {
            $getMgContactSplat = @{
                Property    = $Script:PropertiesContacts
                All         = $true
                ErrorAction = 'Stop'
            }
            $Users = Get-MgContact @getMgContactSplat
        } catch {
            Write-Color -Text "[e] ", "Failed to get contacts. ", "Error: $($_.Exception.Message)" -Color Red, White, Red
            return $false
        }
        :NextUser foreach ($User in $Users) {
            $Entry = $User.Id
            if ($GroupIDs.Keys.Count -gt 0) {
                try {
                    $UserGroups = Get-MgContactMemberOf -OrgContactId $User.Id -All
                } catch {
                    Write-Color -Text "[e] ", "Failed to get contact memberOf for contact $($User.Id). ", "Error: $($_.Exception.Message)" -Color Yellow, White, Red
                    continue
                }
                if ($UserGroups.Count -eq 0) {
                    continue
                }
                $GroupExclude = $false
                foreach ($Group in $UserGroups) {
                    if ($GroupIDsExclude.Keys -contains $Group.Id) {
                        $GroupExclude = $true
                        break
                    }
                }
                if ($GroupExclude -eq $true) {
                    Write-Verbose -Message "Filtering out contact $($User.MailNickname) by group exclusion"
                    continue
                }
                $GroupInclude = $false
                foreach ($Group in $UserGroups) {
                    if ($GroupIDs.Keys -contains $Group.Id) {
                        $GroupInclude = $true
                        break
                    }
                }
                if ($GroupInclude -eq $false) {
                    Write-Verbose -Message "Filtering out contact $($User.MailNickname) by group inclusion"
                    continue
                }
            }
            foreach ($Property in $PropertyFilterExclude.Keys) {
                $Filter = $PropertyFilterExclude[$Property]
                $Value = $User.$Property
                if ($Filter.Operator -eq 'Like') {
                    $Find = $false
                    foreach ($FilterValue in $Filter.Value) {
                        if ($Value -like $FilterValue) {
                            $Find = $true
                        }
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'Equal') {
                    $Find = $false
                    if ($Filter.Value -contains $Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'NotEqual') {
                    $Find = $false
                    if ($Filter.Value -notcontains $Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'LessThan') {
                    $Find = $false
                    if ($Value -lt $Filter.Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'MoreThan') {
                    $Find = $false
                    if ($Value -gt $Filter.Value) {
                        $Find = $true
                    }
                    if ($Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) matching $($Filter.Value)"
                        continue NextUser
                    }
                } else {
                    Write-Color -Text "[e] ", "Unknown operator: $($Filter.Operator)" -Color Red, White
                    return $false
                }
            }

            foreach ($Property in $PropertyFilter.Keys) {
                $Filter = $PropertyFilter[$Property]
                $Value = $User.$Property
                if ($Filter.Operator -eq 'Like') {
                    $Find = $false
                    foreach ($FilterValue in $Filter.Value) {
                        if ($Value -like $FilterValue) {
                            $Find = $true
                        }
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'Equal') {
                    $Find = $false
                    if ($Filter.Value -contains $Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'NotEqual') {
                    $Find = $false
                    if ($Filter.Value -notcontains $Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'LessThan') {
                    $Find = $false
                    if ($Value -lt $Filter.Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } elseif ($Filter.Operator -eq 'MoreThan') {
                    $Find = $false
                    if ($Value -gt $Filter.Value) {
                        $Find = $true
                    }
                    if (-not $Find) {
                        Write-Verbose -Message "Filtering out contact $($User.MailNickname) by property $($Property) not matching $($Filter.Value)"
                        continue NextUser
                    }
                } else {
                    Write-Color -Text "[e] ", "Unknown operator: $($Filter.Operator)" -Color Red, White
                    return $false
                }
            }

            # Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Contact' -InputObject $User
            # foreach ($Phone in $User.Phones) {
            #     if ($Phone.Type -eq 'Mobile') {
            #         Add-Member -MemberType NoteProperty -Name 'MobilePhone' -Value $Phone.Number -InputObject $User
            #     } elseif ($Phone.Type -eq 'Business') {
            #         Add-Member -MemberType NoteProperty -Name 'BusinessPhones' -Value $Phone.Number -InputObject $User
            #     } elseif ($Phone.Type -eq 'Home') {
            #         Add-Member -MemberType NoteProperty -Name 'HomePhone' -Value $Phone.Number -InputObject $User
            #     }
            # }
            # if ($User.BusinessAddress) {
            #     Add-Member -MemberType NoteProperty -Name 'Country' -Value $User.BusinessAddress.CountryOrRegion -InputObject $User
            #     Add-Member -MemberType NoteProperty -Name 'City' -Value $User.BusinessAddress.City -InputObject $User
            #     Add-Member -MemberType NoteProperty -Name 'State' -Value $User.BusinessAddress.State -InputObject $User
            #     Add-Member -MemberType NoteProperty -Name 'Street' -Value $User.BusinessAddress.Street -InputObject $User
            #     Add-Member -MemberType NoteProperty -Name 'PostalCode' -Value $User.BusinessAddress.PostalCode -InputObject $User
            # }

            $NewUser = [ordered] @{
                Id             = $User.Id                           #: f87e6e44-7372-4763-bee8-e265cab8ff54
                Type           = 'Contact'                       #: Contact
                MobilePhone    = $User.MobilePhone                  #: 111234
                BusinessPhones = $User.BusinessPhones               #: 001234
                Country        = $User.Addresses.CountryOrRegion                      #: Poland
                City           = $User.Addresses.City                                 #: Warsaw
                State          = $User.Addresses.State                                #: Mazovia
                Street         = $User.Addresses.Street                               #: 1st Street
                PostalCode     = $User.Addresses.PostalCode                           #: 00-000
                CompanyName    = $User.CompanyName                  #: Ziomek
                #DeletedDateTime              = $User.DeletedDateTime              #:
                #Department                   = $User.Department                   #:
                #DirectReports                = $User.DirectReports                #:
                DisplayName    = $User.DisplayName                  #: new_contact
                GivenName      = $User.GivenName                    #: My
                JobTitle       = $User.JobTitle                     #: Tytul
                Mail           = $User.Mail                         #: new_contact@evotec.pl
                MailNickname   = $User.MailNickname                 #: new_contact
                #Manager                      = $User.Manager                      #: Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject
                MemberOf       = $User.MemberOf                     #:
                #OnPremisesLastSyncDateTime   = $User.OnPremisesLastSyncDateTime   #:
                #OnPremisesProvisioningErrors = $User.OnPremisesProvisioningErrors #:
                #OnPremisesSyncEnabled        = $User.OnPremisesSyncEnabled        #:
                #Phones                    = $User.Phones                       #: {Microsoft.Graph.PowerShell.Models.MicrosoftGraphPhone, Microsoft.Graph.PowerShell.Models.MicrosoftGraphPhone, Microsoft.Graph.PowerShell.Models.MicrosoftGraphPhone}
                Mobile         = $User.Mobile                       #: 111234

                #ProxyAddresses            = $User.ProxyAddresses               #:
                #ServiceProvisioningErrors = $User.ServiceProvisioningErrors    #:
                Surname        = $User.Surname                      #: Test Contact
                #TransitiveMemberOf           = $User.TransitiveMemberOf           #:
                #AdditionalProperties         = $User.AdditionalProperties         #: {}
            }
            foreach ($Phone in $User.Phones) {
                if ($Phone.Type -eq 'Mobile') {
                    $NewUser.MobilePhone = $Phone.Number
                } elseif ($Phone.Type -eq 'Business') {
                    $NewUser.BusinessPhones = $Phone.Number
                } elseif ($Phone.Type -eq 'Home') {
                    $NewUser.HomePhone = $Phone.Number
                }
            }


            $ExistingUsers[$Entry] = [PSCustomObject] $NewUser
        }
    }
    $ExistingUsers
}
