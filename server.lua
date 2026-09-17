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
