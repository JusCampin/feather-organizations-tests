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
RegisterCommand('OrganizationsAuditBoundaryTest',function(source)
    if source~=0 then return end
    local called,reason=xpcall(function()
        local api=exports['feather-organizations']
        local foreign=api:FindOrganizationByKey({organizationKey='org_event_test_child'})
        local owned=api:FindOrganizationByKey({organizationKey='org_ownership_fixture'})
        assert(foreign.ok and owned.ok,'Run event and ownership acceptance first')
        local denied=api:InspectOrganizationHistory({organizationId=foreign.value.organizationId,limit=1})
        assert(not denied.ok and denied.code=='authorization_denied','Foreign history was not denied')
        local injected=api:InspectOrganizationHistory({organizationId=owned.value.organizationId,sourceResource='feather-organizations'})
        assert(not injected.ok and injected.code=='invalid_input','Caller injection not rejected')
        local first=api:InspectOrganizationHistory({organizationId=owned.value.organizationId,limit=1})
        assert(first.ok and #first.value.items==1 and first.value.nextCursor,'Own bounded history unavailable')
        local second=api:InspectOrganizationHistory({organizationId=owned.value.organizationId,limit=1,cursor=first.value.nextCursor})
        assert(second.ok and #second.value.items==1,'Second page unavailable')
        assert(first.value.items[1].eventId~=second.value.items[1].eventId,'Duplicate history event')
        for _,page in ipairs({first.value,second.value}) do
            local event=page.items[1]
            assert(event.organizationId==owned.value.organizationId and event.sourceResource==GetCurrentResourceName(),'Foreign attribution returned')
            assert(event.legalName==nil and event.displayName==nil,'Names returned in audit projection')
        end
        print('[OrganizationsAuditBoundaryTest] PASS foreignDenied=true spoofDenied=true ownAllowed=true bounded=true paginated=true attribution=true (read-only)')
    end,debug.traceback)
    if not called then print('[OrganizationsAuditBoundaryTest] FAIL '..tostring(reason)) end
end,true)
RegisterCommand('OrganizationsInterestBoundaryTest',function(source,args)
    if source~=0 then return end
    local called,reason=xpcall(function()
        assert(#args==2 and #args[1]<=100,'Use <stable requestId> <character UUID>')
        local api=exports['feather-organizations']
        local function Require(result)
            assert(result.ok,tostring(result.code)..': '..tostring(result.message));return result.value
        end
        local foreign=Require(api:FindOrganizationByKey({organizationKey='org_interest_test'}))
        local request={organizationId=foreign.organizationId,expectedRevision=foreign.revision,
            interestType='owner',holderType='character',holderId=args[2],
            requestId=args[1]..':foreign_grant',reasonCode='development.interest_boundary'}
        local deniedGrant=api:GrantOrganizationInterest(request)
        assert(not deniedGrant.ok and deniedGrant.code=='authorization_denied','Foreign grant not denied')
        request.requestId=args[1]..':foreign_revoke'
        local deniedRevoke=api:RevokeOrganizationInterest(request)
        assert(not deniedRevoke.ok and deniedRevoke.code=='authorization_denied','Foreign revoke not denied')
        local spoof={}
        for key,value in pairs(request) do spoof[key]=value end
        spoof.sourceResource='feather-organizations';spoof.requestId=args[1]..':spoof'
        local deniedSpoof=api:GrantOrganizationInterest(spoof)
        assert(not deniedSpoof.ok and deniedSpoof.code=='invalid_input','Caller injection not rejected')
        local after=Require(api:GetOrganization({organizationId=foreign.organizationId}))
        assert(after.revision==foreign.revision and after.status==foreign.status,'Foreign target changed')
        local owned=Require(api:CreateOrganization({requestId=args[1]..':create',organizationType='business',
            organizationKey='org_interest_fixture',legalName='Organization Interest Boundary Company',
            displayName='Interest Boundary',reasonCode='development.interest_boundary'}))
        local grant={organizationId=owned.organizationId,expectedRevision=1,requestId=args[1]..':grant',
            reasonCode='development.interest_boundary',interestType='owner',holderType='character',holderId=args[2]}
        local granted=Require(api:GrantOrganizationInterest(grant))
        local revoke={}
        for key,value in pairs(grant) do revoke[key]=value end
        revoke.expectedRevision=2;revoke.requestId=args[1]..':revoke'
        local revoked=Require(api:RevokeOrganizationInterest(revoke))
        local replay=Require(api:GrantOrganizationInterest(grant))
        local revokeReplay=Require(api:RevokeOrganizationInterest(revoke))
        local state=Require(api:GetOrganization({organizationId=owned.organizationId}))
        assert(granted.interestId==revoked.interestId and replay.interestId==granted.interestId
            and replay.replayed and revokeReplay.replayed and revoked.status=='revoked' and state.revision==3,
            'Owned change/replay inconsistent')
        print(('[OrganizationsInterestBoundaryTest] PASS id=%s interestId=%s foreignGrantDenied=true foreignRevokeDenied=true spoofDenied=true targetUnchanged=true ownAllowed=true replayed=true revision=3'):format(
            owned.organizationId,granted.interestId))
    end,debug.traceback)
    if not called then print('[OrganizationsInterestBoundaryTest] FAIL '..tostring(reason)) end
end,true)
RegisterCommand('OrganizationsInterestReadBoundaryTest',function(source)
    if source~=0 then return end
    local called,reason=xpcall(function()
        local api=exports['feather-organizations']
        local function Require(result)
            assert(result.ok,tostring(result.code)..': '..tostring(result.message));return result.value
        end
        local foreign=Require(api:FindOrganizationByKey({organizationKey='org_interest_read_test'}))
        local owned=Require(api:FindOrganizationByKey({organizationKey='org_interest_fixture'}))
        local denied=api:ListOrganizationInterests({organizationId=foreign.organizationId,limit=1})
        assert(not denied.ok and denied.code=='authorization_denied' and denied.value==nil,'Foreign interests not denied')
        local spoof=api:ListOrganizationInterests({organizationId=foreign.organizationId,sourceResource='feather-organizations'})
        assert(not spoof.ok and spoof.code=='invalid_input','Caller injection not rejected')
        local page=Require(api:ListOrganizationInterests({organizationId=owned.organizationId,status='revoked',limit=1}))
        assert(#page.items==1 and not page.nextCursor,'Own revoked interest page invalid')
        local item=page.items[1]
        local originalHolder=item.holderId
        assert(item.organizationId==owned.organizationId and item.holderType=='character' and item.interestType=='owner'
            and item.status=='revoked' and item.revision==3 and type(originalHolder)=='string','Own interest identity/state invalid')
        for field in pairs(item) do
            assert(field=='interestId' or field=='organizationId' or field=='interestType' or field=='holderType'
                or field=='holderId' or field=='status' or field=='revision','Private profile/account field returned')
        end
        local active=Require(api:ListOrganizationInterests({organizationId=owned.organizationId,status='active',limit=1}))
        assert(#active.items==0 and not active.nextCursor,'Active filter returned revoked interest')
        local filterMismatch=api:ListOrganizationInterests({organizationId=owned.organizationId,status='active',cursor=item.interestId})
        assert(not filterMismatch.ok and filterMismatch.code=='invalid_cursor','Filter mismatch not rejected')
        local cursorDenied=api:ListOrganizationInterests({organizationId=foreign.organizationId,cursor=item.interestId})
        assert(not cursorDenied.ok and cursorDenied.code=='authorization_denied','Cursor bypassed target authorization')
        item.holderId='tampered'
        local reread=Require(api:ListOrganizationInterests({organizationId=owned.organizationId,limit=1}))
        assert(#reread.items==1 and reread.items[1].holderId==originalHolder,'Caller mutation affected subsequent read')
        local afterForeign=Require(api:GetOrganization({organizationId=foreign.organizationId}))
        local afterOwned=Require(api:GetOrganization({organizationId=owned.organizationId}))
        assert(afterForeign.revision==foreign.revision and afterOwned.revision==owned.revision,'Read changed organization revisions')
        print('[OrganizationsInterestReadBoundaryTest] PASS foreignDenied=true spoofDenied=true ownRevokedReadable=true filters=true cursorAuthorization=true isolated=true privateFieldsExcluded=true unchanged=true (read-only)')
    end,debug.traceback)
    if not called then print('[OrganizationsInterestReadBoundaryTest] FAIL '..tostring(reason)) end
end,true)
RegisterCommand('OrganizationsServicePolicyBoundaryTest',function(source,args)
    if source~=0 then return end
    local called,reason=xpcall(function()
        assert(#args==2 and #args[1]<=100,'Use <stable requestId> <character UUID>')
        local api=exports['feather-organizations']
        local function Require(result) assert(result.ok,tostring(result.code)..': '..tostring(result.message));return result.value end
        local owned=Require(api:FindOrganizationByKey({organizationKey='org_interest_fixture'}))
        local history=Require(api:InspectOrganizationHistory({organizationId=owned.organizationId}))
        local before=Require(api:ListOrganizationInterests({organizationId=owned.organizationId}))
        assert(#history.items==3 and #before.items==1 and before.items[1].status=='revoked','Expected prior boundary fixture at revision 3')
        local request={organizationId=owned.organizationId,expectedRevision=owned.revision,interestType='owner',holderType='character',
            holderId=args[2],requestId=args[1]..':grant',reasonCode='development.service_boundary'}
        local function Denied(result)
            assert(not result.ok and result.code=='authorization_denied','Unconfigured service principal was not denied')
        end
        Denied(api:GrantOrganizationInterest(request))
        Denied(api:GrantOrganizationInterest(request))
        local revoke={}
        for key,value in pairs(request) do revoke[key]=value end
        revoke.requestId=args[1]..':revoke'
        Denied(api:RevokeOrganizationInterest(revoke))
        local create={requestId=args[1]..':create',organizationType='business',organizationKey='org_service_denied_fixture',
            legalName='Denied Service Fixture Company',displayName='Denied Service Fixture',reasonCode='development.service_boundary'}
        Denied(api:CreateOrganization(create))
        local notCreated=api:FindOrganizationByKey({organizationKey=create.organizationKey})
        assert(not notCreated.ok and notCreated.code=='organization_not_found','Denied creation persisted an entity')
        local spoof={}
        for key,value in pairs(request) do spoof[key]=value end
        spoof.sourceResource='feather-organizations'
        local injection=api:GrantOrganizationInterest(spoof)
        assert(not injection.ok and injection.code=='invalid_input','Principal injection accepted')
        local after=Require(api:GetOrganization({organizationId=owned.organizationId}))
        local afterHistory=Require(api:InspectOrganizationHistory({organizationId=owned.organizationId}))
        local afterInterests=Require(api:ListOrganizationInterests({organizationId=owned.organizationId}))
        assert(after.revision==owned.revision and after.status==owned.status and #afterHistory.items==#history.items
            and #afterInterests.items==1 and afterInterests.items[1].interestId==before.items[1].interestId
            and afterInterests.items[1].revision==before.items[1].revision and afterInterests.items[1].status=='revoked','Denied requests altered fixture state')
        local direct=exports['feather-core']:Authorize('organizations.interest.manage',{subject={resource='feather-organizations'}})
        assert(direct.ok and direct.value.allowed==false and direct.value.code=='service_forbidden','Direct Core caller spoof bypassed broker binding')
        print('[OrganizationsServicePolicyBoundaryTest] PASS trustedButUngrantable=true ownGrantDenied=true ownRevokeDenied=true creationDenied=true retryDenied=true spoofDenied=true directCallerDenied=true unchanged=true (no organizations or interests created)')
    end,debug.traceback)
    if not called then print('[OrganizationsServicePolicyBoundaryTest] FAIL '..tostring(reason)) end
end,true)
