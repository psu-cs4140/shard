# Monster Design Notes

## Fields
- name (unique, required), slug (unique, autogen)
- species, description
- level: 1..50 (CHECK constraint + validation)
- hp >=1, attack >=1, defense >=0, speed >=1, xp_drop >=0
- element: enum [:neutral, :fire, :water, :earth, :air, :lightning, :poison]
- ai: enum [:passive, :aggressive, :defensive, :cowardly]
- spawn_rate: 0..100 (meaning: % weight for spawning)
- optional room_id (FK) for spawn hints

## Constraints/Indexes
- unique(name), unique(slug), idx(room_id)
- database CHECKs mirror validations

## Open Questions
- Should `spawn_rate` be weights per-room instead of global?
- Elemental multipliers matrix (e.g., fire>earth, water>fire)?
- Per-level scaling curves for hp/atk/def?
- Do we need `rarity` or `boss` flag?

## Test Strategy
- Changeset boundary tests (done)
- Property tests for damage once combat exists
- Controller tests with admin session helper (done)
