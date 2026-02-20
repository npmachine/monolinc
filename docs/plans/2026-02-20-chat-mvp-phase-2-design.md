# Chat MVP Phase 2 Design

**Goal:** Implement rooms (schema, context, list, create) with strict auto-slugging and collision handling.

**Overview**
Phase 2 adds the Rooms domain and UI flows. The `Room` schema uses UUID primary keys, includes `name`, `slug`, `description`, and `created_by`. Rooms are created from a LiveView form that only accepts `name` and optional `description`. The `slug` is auto-generated from `name` and never editable. The rooms list displays room name and description; online count is deferred until Presence later.

**Data Model & Validation**
`rooms` table: `id (uuid)`, `name (string)`, `slug (string, unique)`, `description (string, nullable)`, `created_by (uuid)`, `timestamps`. The changeset enforces:
- `name` required
- `description` optional with sane max length
- `slug` derived via normalization: lowercase, alphanumeric + hyphen only, collapse hyphens, trim hyphens
If normalization produces an empty slug, return a validation error (e.g., “name must include letters or numbers”). DB enforces unique index on `slug`.

**Slug Collision Strategy**
Creation tries the base slug first. On unique constraint error for `slug`, append a short random suffix derived from UUID (e.g., 6–8 chars) and retry insert. Cap retries to a small number (e.g., 3) and return a friendly error if exhausted. This keeps UX simple while handling collisions and concurrency reliably.

**UI & Routing**
LiveViews:
- `/rooms` (index): list rooms, “Create room” CTA.
- `/rooms/new` (new): form with `name` and `description`.
On success, redirect to `/rooms/:slug` (stub for Phase 3). Both pages require authentication using existing `current_scope` and `require_authenticated_user`. Templates wrap with `<Layouts.app flash={@flash} current_scope={@current_scope}>` per Phoenix v1.8 guidance.

**Testing**
Add LiveView tests for:
- unauthenticated access redirects to login
- authenticated index/new render expected elements
- valid create inserts room and redirects to `/rooms/:slug`
- invalid names surface errors
- slug collision creates a unique slug (verify not equal, includes suffix)
Use DOM IDs for key elements and assert with `has_element?/2`.
