# Open Items (Monsters feature)

## 1) Real Admin Auth (replace dev bypass)
- Status: NOT STARTED
- Why: /admin requires real auth; dev bypass (?as_admin=1) is only for local.
- Plan:
  - Run `mix phx.gen.auth Accounts User users`
  - Migrate; add `is_admin:boolean, default: false`
  - Seed an admin; wire `fetch_current_user` + `RequireAdmin` to real user
  - Update controller tests to log in via session helper
- Acceptance:
  - Visiting /admin/* without session redirects to login
  - Admin user can CRUD monsters; non-admin blocked

## 2) Monster Spawn System
- Status: DESIGN DRAFT
- Why: Admin CRUD exists, but monsters don't appear in-world yet.
- Plan:
  - Add `spawn_points` or use room link + `spawn_rate`
  - Implement periodic job (GenServer/Oban) to roll spawns
  - Cap per-room monster counts; despawn on inactivity
- Acceptance:
  - Given a room with spawnable monsters, new instances appear over time
  - Admin-tunable spawn rate affects frequency

## 3) Combat / Stats Balance
- Status: NOT READY
- Why: Stats exist (hp/attack/defense/speed) but no combat loop.
- Plan:
  - Define damage formula + element multipliers
  - Add AI behaviors (passive/aggressive/defensive/cowardly) to turn logic
  - Module tests for edge cases; property tests for damage ranges
- Acceptance:
  - Deterministic results given seed; unit tests pass for core formulas

## 4) Loot / XP Tables
- Status: NOT READY
- Why: `xp_drop` present, but no item/loot system.
- Plan:
  - Create `loot_tables` and `drops` with rarity weights
  - Hook into post-combat to award loot + xp
- Acceptance:
  - Defeating a monster yields XP and drops matching configured weights

## 5) Admin UX polish
- Status: NICE-TO-HAVE
- Plan:
  - Filters/search on index, pagination, bulk delete
  - Validations surfacing (level 1–50, spawn_rate 0–100) with helper text
- Acceptance:
  - Admin can find monsters by name/species/element quickly; pagination works

## 6) Public API (read-only)
- Status: OPTIONAL
- Plan:
  - `GET /api/monsters` (paginated, safe fields)
  - Rate limit; ETag/If-None-Match
- Acceptance:
  - Clients can list monsters without admin privileges
