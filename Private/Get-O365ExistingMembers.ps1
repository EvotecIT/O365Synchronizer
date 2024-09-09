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
            if ($GroupIDs.Keys.Count -gt 0) {
                $getMgUserSplat.ExpandProperty = 'memberOf'
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
                if ($User.MemberOf.Count -eq 0) {
                    continue
                }
                $GroupExclude = $false
                foreach ($Group in $User.MemberOf) {
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
                foreach ($Group in $User.MemberOf) {
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
            if ($GroupIDs.Keys.Count -gt 0) {
                $getMgContactSplat.ExpandProperty = 'memberOf'
            }
            $Users = Get-MgContact @getMgContactSplat
        } catch {
            Write-Color -Text "[e] ", "Failed to get contacts. ", "Error: $($_.Exception.Message)" -Color Red, White, Red
            return $false
        }
        :NextUser foreach ($User in $Users) {
            $Entry = $User.Id

            if ($GroupIDs.Keys.Count -gt 0) {
                if ($User.MemberOf.Count -eq 0) {
                    continue
                }
                $GroupExclude = $false
                foreach ($Group in $User.MemberOf) {
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
                foreach ($Group in $User.MemberOf) {
                    if ($GroupIDs.Keys -contains $Group.Id) {
                        $GroupInclude = $true
                        break
                    }
                }
                if ($GroupInclude -eq $false) {
                    Write-Verbose -Message "Filtering out contact $($User.MailNickname) by group inclusion"
                    continue
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
            }


            Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Contact' -InputObject $User
            $ExistingUsers[$Entry] = $User
        }
    }
    $ExistingUsers
}