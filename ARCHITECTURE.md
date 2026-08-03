# LifeOS — Architecture (Living Document)
**Last updated: Sprint 6**

---

## Module Map

| # | Module | Status | Notes |
|---|---|---|---|
| 1 | Dashboard | ✅ Complete | Home screen; aggregates data from all modules |
| 2 | Objectives | ✅ Complete | CRUD, status lifecycle, SQLite-backed |
| 3 | Tasks | ✅ Complete | CRUD, objective linking, SQLite-backed |
| 4 | Calendar | ✅ Complete | Monthly grid, colour indicators, Day Workspace entry point |
| 5 | Day Workspace | 🟡 Placeholder | Central per-date hub — see §Day Workspace below |
| 6 | AI Assistant | ⬜ Deferred | Not yet scoped |
| 7 | Obsidian Sync | ⬜ Deferred | Not yet scoped |
| 8 | Google Sync | ⬜ Deferred | Not yet scoped |
| 9 | Knowledge | ⬜ Deferred | Not yet scoped |
| 10 | Settings | ⬜ Deferred | Theme toggle, data export — not yet built |

---

## Day Workspace

The Day Workspace is the **central hub for a specific date**. In a future sprint it will be a full Daily Planner/Journal page containing:

- Objectives active on that day
- Tasks due that day
- Notes and free-form journal entry
- AI-generated day summary
- Daily score and breakdown
- Attachments and document links
- Reflection section

**Current state:** `DaySummaryScreen` (`/calendar/:date`) serves as the structural placeholder. It has the correct navigation path, screen scaffold, and section layout — only the section bodies are placeholders. The Journal sprint replaces those bodies without touching navigation or routing.

---

## Folder Structure

```
lib/
  core/
    database/       ← DatabaseService, databaseProvider, schema & migrations
    router/         ← go_router config (Riverpod provider)
    theme/          ← AppTheme (light + dark, MD3)
    utils/          ← Pure Dart helpers (date, time, id generation)
    widgets/        ← Shared, feature-agnostic widgets
  features/
    objectives/
      data/         ← ObjectivesRepository (abstract)
                       SqliteObjectivesRepository (active)
                       MockObjectivesRepository (tests only)
      logic/        ← ObjectivesNotifier (AsyncNotifier), derived providers
      presentation/ ← ObjectivesScreen, ObjectiveCard, form sheet
    tasks/
      data/         ← TasksRepository (abstract)
                       SqliteTasksRepository (active)
                       MockTasksRepository (tests only)
      logic/        ← TasksNotifier (AsyncNotifier)
      presentation/ ← TaskCard, form sheet
    calendar/
      data/         ← DayScore model, CalendarRepository (mock — Score Engine sprint)
      logic/        ← CalendarMonthNotifier, monthScoresProvider
      presentation/ ← CalendarScreen, DaySummaryScreen (Day Workspace placeholder)
  home/
    presentation/   ← HomeScreen (dashboard), home-specific widgets
  settings/
    presentation/   ← (empty — Settings sprint pending)
  app.dart          ← Root widget (theme + router)
  main.dart         ← Async entry: DB init → ProviderScope override → runApp
```

---

## Layer Rules

```
Presentation → Logic → Data → SQLite
```

- Presentation talks to Logic only (via Riverpod providers).
- Logic talks to Data only (via abstract repository interface).
- Data (SqliteXRepository) owns all SQL.
- `DatabaseService.openDatabase()` is called once in `main()`.
- The resulting `Database` is injected via `ProviderScope(overrides: [databaseProvider.overrideWithValue(db)])`.

---

## State Management

**Riverpod `AsyncNotifier`** for features with real persistence (Objectives, Tasks).

- Every mutation: write to SQLite → reload from SQLite into `state`.
- "Reload after write" keeps state always consistent with the DB and
  naturally picks up computed fields (e.g. linked task counts from subqueries).
- Derived providers (`activeObjectivesProvider`, etc.) use `.valueOrNull ?? []`
  so consumers always receive `List<T>` — never `AsyncValue`. Loading/error
  UI is gated at the screen level via `objectivesAsync.when(...)`.

---

## Database

**SQLite** via `sqflite ^2.4.2` + `path ^1.9.0`.

- Single file: `lifeos.db` in the platform documents directory.
- Schema version: **1**. Tables: `objectives`, `tasks`.
- Migrations: `DatabaseService._onUpgrade` — versioned, additive ALTER TABLE only.

### Schema decisions

| Decision | Rationale |
|---|---|
| Enums as TEXT (`.name`) | Human-readable in the file; `Enum.values.byName()` restores them. Renaming an enum requires a migration. |
| Booleans as INTEGER 0/1 | SQLite has no native bool. |
| Nullable DateTimes as INTEGER (ms-since-epoch) | SQL ordering/comparison works directly; no string parsing. |
| `linked_tasks_total/completed` NOT stored | Computed at read time via correlated SQL subqueries in `SqliteObjectivesRepository.getAll`. Eliminates redundant data that can fall out of sync. |
| Soft FK for `linked_objective_id` | No `REFERENCES` constraint — cascade/nullify policy not yet decided. Orphan detection handled defensively in `task_form_sheet.dart`. |
| `created_at` / `updated_at` on every row | Required for default sort order; essential for future sync conflict resolution. Cheaper to add now than to migrate later. |
| `created_at` never overwritten | `SqliteObjectivesRepository` and `SqliteTasksRepository` use separate `_toInsertMap` / `_toUpdateMap` methods to make this explicit. |

---

## Navigation

**`go_router ^16.2.0`** — declarative, URL-based.

| Sprint | Route |
|---|---|
| Phase 1 | `/` (Dashboard) |
| Sprint 3 | `/objectives` |
| Sprint 5 | `/calendar`, `/calendar/:date` (Day Workspace placeholder) |

---

## Accepted Cross-Feature Dependencies

| From | To | Layer | Reason | Status |
|---|---|---|---|---|
| Tasks form sheet | Objectives providers | Presentation | Populates linked-objective dropdown | Existing |
| Tasks notifier | Objectives provider | Logic | `ref.invalidate` after mutations keeps linked-task counts live | Added Sprint 6 |
| Dashboard | Objectives + Tasks providers | Presentation | Aggregation is the dashboard's job | Existing |

All cross-feature dependencies are documented here rather than hidden.
Data layers (SqliteXRepository) remain independent of each other.
