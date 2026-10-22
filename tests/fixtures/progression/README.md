# Authentic progression and encounter migration fixtures

These shell saves were produced by the native v0.2 integration route before attribute progression was implemented. They are preserved rather than reconstructed from the new rules. The town save has no expedition; the combat save includes the original registered pending encounter and live ActionRules snapshot; the earned equipment save includes a real first vault clear, 120 XP, wounds, and earned loot. Tests unwrap the `realm` and `action` JSON fields and verify migration without changing the original pending contract.

These small fixtures contain game state only, with no credentials or personal data.

`v2-invested-combat-save.json` was subsequently generated through the verified v2 rules: three Finesse points, registered vault departure, and four live movement ticks. It preserves the pre-class-identity contract for the next migration test.

`v2-legacy-ember-save.json` was generated using the actual pre-class v2 rules. Its live Ember projectile had already committed at tick nine. The class migration must preserve that committed effect while rejecting new off-class casts and never expanding Mara's current kit.

`v3-oathwarden-combat-save.json` was generated before the repeatable hunt schema: one point each in Might, Vitality, and Spirit; a registered story-vault departure; and a legally committed Ward at tick six. The v4 migration creates a fresh hunt board without rewriting the original pending encounter or the live action state.

The fixtures' file sizes and SHA-256 hashes are recorded in `manifest.json`. They are genuine earlier-version saves, not reconstructed snapshots made to pass the latest validator.
