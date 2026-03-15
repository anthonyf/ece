## ADDED Requirements

### Requirement: PC-to-block lookup cache
The compaction system SHALL provide a cached PC-to-block-range lookup that returns the same `(start . end)` range as `find-block-for-pc` but avoids repeated linear scans by caching results in an `%eq-hash-table`.

#### Scenario: Cache miss triggers linear scan and caches result
- **WHEN** a target PC is looked up and is not yet in the cache
- **THEN** the system performs a linear scan of all block ranges to find the containing range, stores the mapping `target-pc → (start . end)` in the cache, and returns the range

#### Scenario: Cache hit returns immediately
- **WHEN** a target PC is looked up and is already in the cache
- **THEN** the system returns the cached `(start . end)` range without scanning

#### Scenario: Lookup result matches linear scan
- **WHEN** any target PC is looked up via the cache
- **THEN** the returned range SHALL be identical to what `find-block-for-pc` would return for the same PC and ranges

### Requirement: transitively-retain-blocks uses cached lookup
`transitively-retain-blocks` SHALL use the PC-to-block cache for all block lookups instead of calling `find-block-for-pc` directly for each label reference.

#### Scenario: Transitive retention with cached lookups
- **WHEN** `transitively-retain-blocks` resolves label references to target PCs
- **THEN** it SHALL use the cache for block lookups, resulting in at most 228 linear scans (one per unique block) rather than one per label reference

#### Scenario: Output unchanged
- **WHEN** `transitively-retain-blocks` completes with cached lookups
- **THEN** the returned set of retained block ranges SHALL be identical to the result without caching

### Requirement: mark-reachable-blocks uses cached lookup
`mark-reachable-blocks` SHALL use the same cached lookup pattern to avoid linear scans when mapping reachable PCs to their containing blocks.

#### Scenario: Reachable block marking with cache
- **WHEN** `mark-reachable-blocks` maps reachable entry PCs to block ranges
- **THEN** it SHALL use a PC-to-block cache for lookups

#### Scenario: Output unchanged
- **WHEN** `mark-reachable-blocks` completes with cached lookups
- **THEN** the returned set of live block ranges SHALL be identical to the result without caching
