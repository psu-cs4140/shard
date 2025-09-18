# Auth Plan (replace dev bypass)

## Steps
1) `mix phx.gen.auth Accounts User users`
2) Add `is_admin:boolean, default:false`
3) Seed an admin user; add UI to toggle is_admin (admin-only)
4) Router: use real `fetch_current_user`; remove dev `?as_admin=1` path
5) Tests: use generated session helpers to log in as admin

## Risks
- Route changes may touch existing scopes
- Controller tests need session helpers adjusted

## Done When
- Unauthorized users redirected to login on /admin/*
- Admin user can access all admin routes
