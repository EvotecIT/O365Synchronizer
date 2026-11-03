Describe 'Filtered directory manager reads' {
    InModuleScope O365Synchronizer {
        It 'uses separate manager reads with an OData source filter' {
            Initialize-DefaultValuesO365
            Mock Get-MgUser {
                [pscustomobject]@{ Id = 'user-1'; UserType = 'Member'; DisplayName = 'Person'; UserPrincipalName = 'user@contoso.com'; Mail = 'user@contoso.com' }
            }
            Mock Complete-O365UserManagers {
                $Users[0] | Add-Member NoteProperty Manager 'Boss' -Force
                $Users
            }
            $result = Get-O365ExistingMembers -MemberTypes Member -RequireAccountEnabled:$false -RequireAssignedLicenses:$false -UserProvidedFilter {
                Sync-O365PersonalContactFilterOData -Filter "department eq 'Sales'" -ConsistencyLevel eventual -CountVariable count
            }
            $result['user-1'].Manager | Should -Be 'Boss'
            Should -Invoke Get-MgUser -Times 1 -Exactly -ParameterFilter { $Filter -and -not $PSBoundParameters.ContainsKey('ExpandProperty') }
            Should -Invoke Complete-O365UserManagers -Times 1 -Exactly
        }

        It 'hydrates selected users in bounded batches with reordered responses and no-manager support' {
            $script:BatchSizes = [System.Collections.Generic.List[int]]::new()
            Mock Invoke-MgGraphRequest {
                $request = $Body | ConvertFrom-Json
                $script:BatchSizes.Add($request.requests.Count)
                $responses = @($request.requests | ForEach-Object {
                    $userId = ($_.url -split '/')[2].Split('?')[0]
                    $_.url | Should -BeLike '*/manager?*'
                    if ($userId -eq 'user-20') {
                        @{ id = $_.id; status = 404; body = @{ error = @{ code = 'Request_ResourceNotFound' } } }
                    } else {
                        @{ id = $_.id; status = 200; body = @{ displayName = "Boss $userId" } }
                    }
                })
                [array]::Reverse($responses)
                @{ responses = $responses }
            }
            $users = @(0..20 | ForEach-Object { [pscustomobject]@{ Id = "user-$_"; DisplayName = "Person $_" } })
            $result = @(Complete-O365UserManagers -Users $users)
            $script:BatchSizes.Count | Should -Be 2
            $script:BatchSizes[0] | Should -Be 20
            $script:BatchSizes[1] | Should -Be 1
            $result.Count | Should -Be 21
            $result[0].Manager | Should -Be 'Boss user-0'
            $result[19].Manager | Should -Be 'Boss user-19'
            $result[20].Manager | Should -BeNullOrEmpty
        }

        It 'rejects incomplete manager reads' {
            Mock Invoke-MgGraphRequest { @{ responses = @() } }
            { Complete-O365UserManagers -Users @([pscustomobject]@{ Id = 'user-1' }) } | Should -Throw '*incomplete*'
        }

        It 'rejects an incomplete successful manager response rather than treating it as no manager' {
            Mock Invoke-MgGraphRequest {
                @{ responses = @(@{ id = '1'; status = 200; body = @{ id = 'user-1' } }) }
            }
            { Complete-O365UserManagers -Users @([pscustomobject]@{ Id = 'user-1' }) } | Should -Throw '*unreadable manager*'
        }

        It 'accepts an empty filtered source without making manager requests' {
            Initialize-DefaultValuesO365
            Mock Get-MgUser { }
            Mock Invoke-MgGraphRequest { throw 'No manager request should be made.' }
            $result = Get-O365ExistingMembers -MemberTypes Member -RequireAccountEnabled:$false -RequireAssignedLicenses:$false -UserProvidedFilter {
                Sync-O365PersonalContactFilterOData -Filter "department eq 'Missing'"
            }
            $result | Should -BeOfType ([System.Collections.Specialized.OrderedDictionary])
            $result.Count | Should -Be 0
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly
        }

        It 'rejects unreadable manager objects rather than converting them into blanks' {
            Mock Invoke-MgGraphRequest {
                @{ responses = @(@{ id = '1'; status = 200; body = @{ id = 'manager-1'; displayName = $null } }) }
            }
            { Complete-O365UserManagers -Users @([pscustomobject]@{ Id = 'user-1' }) } | Should -Throw '*unreadable manager*'
        }

        It 'uses UPN when the manager display name is unavailable' {
            Get-O365ManagerName -Manager @{ displayName = $null; userPrincipalName = 'boss@contoso.com' } | Should -Be 'boss@contoso.com'
        }
    }
}
