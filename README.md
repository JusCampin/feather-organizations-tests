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

Stop the fixture after testing:

```text
stop feather-organizations-tests
```
