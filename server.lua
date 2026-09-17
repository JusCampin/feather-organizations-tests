RegisterCommand('OrganizationsOwnershipBoundaryTest',function(source,args)
    if source~=0 then return end
    local base=args[1]
    if #args~=1 or type(base)~='string' or #base>100 or not base:match('^[A-Za-z0-9][A-Za-z0-9._:%-]*$') then
        print('[OrganizationsOwnershipBoundaryTest] FAIL use <stable requestId>');return
    end
    local called,result=xpcall(function()
        local api=exports['feather-organizations']
        local ready=api:AwaitReady(0)
        if not ready.ok then print('[OrganizationsOwnershipBoundaryTest] FAIL not ready');return end
        -- Every API call crosses the real Cfx boundary: no supplied caller/resource.
        local target=api:FindOrganizationByKey({organizationKey='org_creation_test'})
        if not target.ok then print('[OrganizationsOwnershipBoundaryTest] FAIL run creation acceptance first');return end
        local request={ organizationId=target.value.organizationId,expectedRevision=target.value.revision,
            status='active',requestId=base .. ':foreign',reasonCode='development.ownership_boundary' }
        local foreign=api:ChangeOrganizationStatus(request)
        local injected={organizationId=request.organizationId,expectedRevision=request.expectedRevision,
            status=request.status,requestId=base .. ':injected',reasonCode=request.reasonCode,
            sourceResource='feather-organizations'}
        local spoof=api:ChangeOrganizationStatus(injected)
        local after=api:GetOrganization({organizationId=target.value.organizationId})
        local created=api:CreateOrganization({requestId=base .. ':create',organizationType='business',
            organizationKey='org_ownership_fixture',legalName='Organization Ownership Fixture Company',
            displayName='Organization Ownership Fixture',reasonCode='development.ownership_boundary'})
        if not created.ok then print('[OrganizationsOwnershipBoundaryTest] FAIL create code=' .. created.code);return end
        local owned={organizationId=created.value.organizationId,expectedRevision=1,status='active',
            requestId=base .. ':activate',reasonCode='development.ownership_boundary'}
        local activated=api:ChangeOrganizationStatus(owned)
        local replay=api:ChangeOrganizationStatus(owned)
        local good=not foreign.ok and foreign.code=='authorization_denied'
            and not spoof.ok and spoof.code=='invalid_input' and after.ok
            and after.value.revision==target.value.revision and after.value.status==target.value.status
            and activated.ok and activated.value.revision==2 and replay.ok and replay.value.replayed==true
        print(('[OrganizationsOwnershipBoundaryTest] %s foreignDenied=%s spoofDenied=%s targetUnchanged=%s ownAllowed=%s replayed=%s fixtureId=%s'):format(
            good and 'PASS' or 'FAIL',tostring(not foreign.ok and foreign.code=='authorization_denied'),
            tostring(not spoof.ok and spoof.code=='invalid_input'),tostring(after.ok and after.value.revision==target.value.revision),
            tostring(activated.ok),tostring(replay.ok and replay.value.replayed),created.value.organizationId))
    end,debug.traceback)
    if not called then print('[OrganizationsOwnershipBoundaryTest] FAIL ' .. tostring(result)) end
end,true)

RegisterCommand('OrganizationsHierarchyBoundaryTest',function(source,args)
    if source~=0 then return end
    local base=args[1]
    if #args~=1 or type(base)~='string' or #base>100 or not base:match('^[A-Za-z0-9][A-Za-z0-9._:%-]*$') then
        print('[OrganizationsHierarchyBoundaryTest] FAIL use <stable requestId>');return
    end
    local called,result=xpcall(function()
        local api=exports['feather-organizations']
        local foreign=api:FindOrganizationByKey({organizationKey='org_hierarchy_test_1'})
        local owned=api:FindOrganizationByKey({organizationKey='org_ownership_fixture'})
        if not foreign.ok or not owned.ok then print('[OrganizationsHierarchyBoundaryTest] FAIL run earlier hierarchy/fixture acceptance first');return end
        local created=api:CreateOrganization({requestId=base .. ':create',organizationType='business',
            organizationKey='org_hierarchy_fixture_parent',legalName='Hierarchy Fixture Parent Company',
            displayName='Hierarchy Fixture Parent',reasonCode='development.hierarchy_boundary'})
        if not created.ok then print('[OrganizationsHierarchyBoundaryTest] FAIL create code=' .. created.code);return end
        local deniedChild=api:SetParentOrganization({organizationId=foreign.value.organizationId,
            parentOrganizationId=created.value.organizationId,expectedRevision=foreign.value.revision,
            requestId=base .. ':foreign_child',reasonCode='development.hierarchy_boundary'})
        local deniedParent=api:SetParentOrganization({organizationId=owned.value.organizationId,
            parentOrganizationId=foreign.value.organizationId,expectedRevision=3,
            requestId=base .. ':foreign_parent',reasonCode='development.hierarchy_boundary'})
        local request={organizationId=owned.value.organizationId,parentOrganizationId=created.value.organizationId,
            expectedRevision=3,requestId=base .. ':set',reasonCode='development.hierarchy_boundary'}
        local set=api:SetParentOrganization(request)
        local replay=api:SetParentOrganization(request)
        local children=api:ListOrganizationChildren({organizationId=created.value.organizationId,limit=1})
        local after=api:GetOrganization({organizationId=foreign.value.organizationId})
        local good=not deniedChild.ok and deniedChild.code=='authorization_denied'
            and not deniedParent.ok and deniedParent.code=='authorization_denied' and set.ok and set.value.revision==4
            and replay.ok and replay.value.replayed==true and children.ok and #children.value.items==1
            and children.value.items[1].organizationId==owned.value.organizationId and after.ok
            and after.value.revision==foreign.value.revision and after.value.parentOrganizationId==foreign.value.parentOrganizationId
        print(('[OrganizationsHierarchyBoundaryTest] %s foreignChildDenied=%s foreignParentDenied=%s ownAllowed=%s replayed=%s childrenBounded=%s targetUnchanged=%s'):format(
            good and 'PASS' or 'FAIL',tostring(not deniedChild.ok and deniedChild.code=='authorization_denied'),
            tostring(not deniedParent.ok and deniedParent.code=='authorization_denied'),tostring(set.ok),
            tostring(replay.ok and replay.value.replayed),tostring(children.ok and #children.value.items==1),
            tostring(after.ok and after.value.revision==foreign.value.revision)))
    end,debug.traceback)
    if not called then print('[OrganizationsHierarchyBoundaryTest] FAIL ' .. tostring(result)) end
end,true)

RegisterCommand('OrganizationsIdentityBoundaryTest',function(source,args)
    if source~=0 then return end
    local base=args[1]
    if #args~=1 or type(base)~='string' or #base>100 or not base:match('^[A-Za-z0-9][A-Za-z0-9._:%-]*$') then
        print('[OrganizationsIdentityBoundaryTest] FAIL use <stable requestId>');return
    end
    local called,result=xpcall(function()
        local api=exports['feather-organizations']
        local target=api:FindOrganizationByKey({organizationKey='org_identity_test'})
        if not target.ok then print('[OrganizationsIdentityBoundaryTest] FAIL run identity acceptance first');return end
        local denied=api:UpdateOrganizationIdentity({organizationId=target.value.organizationId,
            expectedRevision=target.value.revision,requestId=base .. ':foreign',reasonCode='development.identity_boundary',
            legalName='Foreign Edit Company',displayName='Foreign Edit'})
        local after=api:GetOrganization({organizationId=target.value.organizationId})
        local page=api:ListOrganizations({limit=1,organizationType='business'})
        local owned=api:FindOrganizationByKey({organizationKey='org_ownership_fixture'})
        if not owned.ok then print('[OrganizationsIdentityBoundaryTest] FAIL run ownership acceptance first');return end
        -- Ownership fixture was activated at revision 2. Keep this original edit
        -- payload on all retries rather than take a new expected revision.
        local request={organizationId=owned.value.organizationId,expectedRevision=2,requestId=base .. ':edit',
            reasonCode='development.identity_boundary',legalName='Renamed Ownership Fixture Company',displayName='Renamed Ownership Fixture'}
        local edit=api:UpdateOrganizationIdentity(request)
        local replay=api:UpdateOrganizationIdentity(request)
        local good=not denied.ok and denied.code=='authorization_denied' and after.ok
            and after.value.revision==target.value.revision and after.value.legalName==target.value.legalName
            and after.value.displayName==target.value.displayName and page.ok and #page.value.items<=1
            and edit.ok and edit.value.revision==3 and replay.ok and replay.value.replayed==true
        print(('[OrganizationsIdentityBoundaryTest] %s foreignDenied=%s targetUnchanged=%s boundedList=%s ownAllowed=%s replayed=%s'):format(
            good and 'PASS' or 'FAIL',tostring(not denied.ok and denied.code=='authorization_denied'),
            tostring(after.ok and after.value.revision==target.value.revision),tostring(page.ok and #page.value.items<=1),
            tostring(edit.ok),tostring(replay.ok and replay.value.replayed)))
    end,debug.traceback)
    if not called then print('[OrganizationsIdentityBoundaryTest] FAIL ' .. tostring(result)) end
end,true)
