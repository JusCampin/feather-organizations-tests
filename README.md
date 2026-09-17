# Organizations development acceptance fixture

Optional `feather-organizations-tests` resource. Do not add it to the recipe or
production startup. It exists only to call Organizations through real Cfx exports.
Organizations grants this exact resource reader/creator/mutator trust only while
`Config.DevMode` is true; it never grants privileged cross-owner override. Disable
DevMode and stop/remove this fixture before production.

After creation acceptance has made `org_creation_test`, deploy this fixture to
the development server alongside Organizations and run:

```text
refresh
ensure feather-organizations-tests
OrganizationsOwnershipBoundaryTest org-ownership-001
```

The test denies changing the original creation-test organization, rejects injected
caller identity, and verifies its status/revision stayed unchanged. It creates
one separate real fixture-owned entity at key `org_ownership_fixture`, activates
it, and verifies exact activation replay. It does not alter money/items. Repeat
the exact request ID after restart; never use a fresh ID to recover its fixed key.
This tests creator ownership, not player membership or Authority policy decisions.

After directory/identity live acceptance, run
`OrganizationsIdentityBoundaryTest org-identity-boundary-001`. It denies renaming
the main resource's identity-test entity, checks exported bounded listing, then
renames/replays the fixture-owned entity from revision 2 to 3. Retain that exact
ID on restart. It creates no additional entity and changes no money/items.

After hierarchy live acceptance, `OrganizationsHierarchyBoundaryTest
org-hierarchy-boundary-001` verifies foreign-child and foreign-parent rejection,
then links the fixture-owned entity (revision 3 from identity acceptance) to a
separate new fixture-owned parent. It checks set replay and bounded children
reads through real exports. Repeat its original ID after restart. Parent links
do not grant privileged cross-owner access. Neither this fixture nor its trust
belongs in production/default recipe startup.

Stop the fixture after testing:

`OrganizationsInterestReadBoundaryTest` is read-only after interest mutation and
multi-page read acceptance. It denies foreign interest reads and identity spoofing,
reads the fixture's own revoked interest, checks filters, cursor authorization,
projection privacy/isolation and unchanged organization revisions. Repeat after
restarting the fixture.

`OrganizationsInterestBoundaryTest org-interest-boundary-001 <character UUID>`
uses actual exports to deny foreign grant/revoke and caller spoofing, then creates
one fixture-owned fixed-key organization and grants/revokes/replays an owner
interest. Expect revision 3 and stable interest identity. Repeat the exact request
ID and character UUID after fixture restart. No money/items/permissions change.

Before stopping, run `OrganizationsAuditBoundaryTest` after event and ownership
acceptance. It verifies creator-scoped history access, rejects caller injection,
and checks bounded pagination and attribution through actual exports (read-only).
Repeat after restarting the fixture.

```text
stop feather-organizations-tests
```
