# LifeOS — Project Checkpoint

Maintained per Sprint 22's Checkpoint Protocol. Purpose: let another
session resume this project without redoing completed work. Updated
after each completed task within the current sprint; superseded by the
next sprint's own checkpoint updates once that sprint output is
delivered.

## How to use this file

1. Treat the most recently delivered ZIP as the actual source of truth
   for file *contents* — this file describes *state and decisions*,
   not a substitute for reading the code.
2. Read "Current Sprint" below first — it says exactly what's done,
   what's in progress, and what's left.
3. Don't re-read every prior sprint's full history to get oriented;
   "Established Architecture" and "Completed Sprints" below are the
   condensed version of what you'd otherwise re-derive from scratch.

---

## Established Architecture (unchanged since early sprints)

- Three-layer: Presentation → Logic → Data. UI has no business logic;
  Services (Logic) hold it; Providers only connect layers; Repository
  owns persistence; Models are pure Dart.
- State management: Riverpod. Simple mutable state uses `Notifier<T>`
  (e.g. `CalendarMonthNotifier`), not `StateProvider`. Derived,
  ephemeral computations use `Provider.autoDispose` (family when keyed).
  Long-lived lists use `AsyncNotifier` (e.g. `DocumentsNotifier`).
- Persistence: sqflite (internal vault, SQLite) and a filesystem-backed
  adapter (Obsidian vault, `.md` files). Both implement the same
  `DocumentRepository` interface, frozen since Sprint 15/16 — no sprint
  since has added a method to it.
- Every new service this project has built is static and
  dependency-free (a pure function of its input) *unless* it needs to
  hold state across calls, in which case it's a plain class exposed via
  a non-`.autoDispose` `Provider` (e.g. `FileChangeDetector`).
- Convention for small helper/pairing types used by exactly one service
  (`DocumentWithMetadata`, `TagCount`, `SearchSnippet`, and now
  `WikiLink`/`DocumentIndex`): they live in `logic/`, alongside that
  service — *not* in `data/`, which is reserved for first-class,
  broadly-used domain models (`Document`, `Vault`, `DocumentMetadata`).
- New screens get their own route in `app_router.dart` but are
  deliberately *not* wired into bottom-nav or linked from elsewhere —
  bottom nav has been a fixed 4 tabs with no free slot since it was
  built. This is a running, explicitly-flagged decision, not an
  oversight, repeated in every sprint that's added a screen.

## Completed Sprints (condensed)

- **15** — Obsidian vault adapter (`ObsidianDocumentRepository`),
  frontmatter parser (`core/utils/frontmatter_parser.dart`, read-only,
  never reconstructs YAML — this guarantee is load-bearing for several
  later sprints).
- **16** — Document rename/duplicate/delete (`DocumentManagementService`),
  the first document list screen + `DocumentListCard`/`EmptyState`/
  `ErrorState` (all reused constantly since).
- **17** — Metadata Foundation: `DocumentMetadata` model,
  `DocumentMetadataService.parse(document)` (parses frontmatter fresh
  from `Document.content` every time — deliberately doesn't trust
  `Document.frontmatter`/`.tags`, which are only reliably populated for
  Obsidian-backed documents).
- **18** — Dynamic Views: `MetadataQueryService` (favorites/pinned/
  byType/byTag, plus `withMetadata()` — the "parse once, filter many"
  pattern every later sprint reuses), `ViewsScreen`.
- **19** — Shared Vault Compatibility audit + `FileChangeDetector` /
  `VaultSyncService` foundations (in-memory content-hash change
  detection; no file watching). Fixed a real BOM-handling bug in the
  frontmatter parser during this sprint's audit.
- **20** — Manual vault refresh (`VaultStatusScreen`), Obsidian launcher
  (`ObsidianLauncherService` — builds a correct `obsidian://` URI,
  verified against Obsidian's own docs, but can't actually launch it
  yet — no `url_launcher`/platform channel added).
- **21** — Global Search (`SearchService`, `SearchScreen`,
  `SearchResultCard`) and Tag Explorer (`tag_provider.dart`,
  `TagExplorerScreen`, `TagDocumentsScreen`). Search query is plain
  `TextEditingController` widget state, *not* a Riverpod provider —
  explicit precedent set for "don't build a keystroke-driven provider."
  Tag flow is fully separate screens (`/tags` → `/tag`), not a filter
  bar embedded in Search.
- **22** — Wiki Links & Backlinks: `WikiLinkService` (parse/resolve,
  path → basename → title fallback), `BacklinkEngine` (whole-vault
  graph; outgoing/broken are per-occurrence, incoming deduplicated by
  source document), `backlink_provider.dart` (path-keyed, not
  `Document`-keyed — better cache sharing), `DocumentLinksSheet` (modal
  bottom sheet from a new AppBar button on DocumentEditorScreen — body
  left untouched). Fully read-only/additive; no repository or schema
  change.
- **23** — Daily Notes & Calendar Integration. `dailyNoteProvider`
  upgraded from `.get` to `.getOrCreate` (auto-creates a missing daily
  note). Fixed a pre-existing compile bug in `_DailyNoteSection`'s
  wiring while verifying Task 2. Calendar → Day Workspace routing and
  the open-note navigation already worked and needed no new code.

Full detail for any of these: read that file's own doc comment first —
every service/screen this project has built explains its own reasoning
inline, not just in a sprint summary.

---

## Current Sprint: V2-01 — App Shell Migration

**Goal:** Replace the 4-tab shell (Dashboard/Calendar/AI-placeholder/
Settings-placeholder) with the V2 navigation (Home/Today/Learn/Library),
per the V2 Product Architecture doc. Shell only — no Learning features,
no AI, no Library logic, per this sprint's explicit scope.

### Verified before starting (not assumed)
`home_screen.dart`'s actual structure was *not* an IndexedStack of four
screens as the V2 architecture doc's Navigation section might suggest —
before this sprint, only "Dashboard" content ever rendered; "Calendar"
was a real `context.push('/calendar')`, and "AI"/"Settings" only
changed which nav icon was highlighted, with the body never varying by
`_navIndex`. Confirmed by reading the file fresh rather than assuming
the architecture doc's description matched the code.

### Completed Tasks

**Task 1 — Bottom Navigation.** ✅
`home_bottom_nav_bar.dart`'s four `NavigationDestination`s swapped to
Home/Today/Learn/Library. `home_screen.dart` gained the tab-switching
mechanism that didn't exist before (an `IndexedStack`, keyed by
`_navIndex`) — required, not optional, since Today/Learn/Library each
need genuinely different content, which the old "highlight only" nav
couldn't support.

**Task 2 — Home Screen.** ✅
Added four new placeholder sections (Quick Clipboard, Focus Mode, AI
Suggestions, Quick Actions) via a new shared `PlaceholderCard` widget.
**Kept, did not remove,** Home's existing real Objectives and Tasks
sections (renamed "Today's Tasks" → "Remaining Tasks" as a label-only
change; the underlying `tasksProvider` wiring is untouched) — additive,
not a replacement, since ripping out real working functionality wasn't
asked for and conflicts with "do not refactor working code." The "add
task" FAB now shows only on the Home tab (previously it was
unconditional, but conditioned on nothing meaningful either, since nav
selection never used to change the body).

**Task 3 — Today Screen.** ✅
New `features/today/presentation/today_screen.dart` — six
`PlaceholderCard` sections (Objectives, Tasks, Daily Notes, Journal,
Daily Score, Timeline), reusing `SectionHeader` from `core/widgets`.
Does not touch `DayWorkspaceScreen` or `/calendar/:date` — both remain
fully intact and reachable on their own; folding them together is
future integration work, not this sprint's.

**Task 4 — Learn Screen.** ✅
New `features/learn/presentation/learn_screen.dart` — reuses the
existing `EmptyState` widget plus an inert "Create Learning Space"
button (shows a SnackBar, no state/model/persistence).

**Task 5 — Library Screen.** ✅
New `features/library/presentation/library_screen.dart` — nine
`PlaceholderCard` sections (All, Documents, Daily Notes, Study Guides,
Flashcards, Quizzes, AI Chats, Attachments, Archive). No filtering.

**Task 6 — Floating AI Bubble.** ✅
New `home/presentation/widgets/ai_bubble_button.dart` — lives in
`HomeScreen`'s `floatingActionButton` (alongside the conditional task
FAB, via a `Column`; distinct `heroTag` to avoid the duplicate-hero
error), so it's visible on all four tabs from one mount point rather
than once per screen. Tap opens a bottom sheet reading "AI Assistant
coming soon." — replacing that later means editing this one file.

**Task 7 — Settings.** ✅
Removed from the bottom nav (Task 1). New
`settings/presentation/settings_screen.dart` (filling the existing
empty stub folder), reachable via a Settings icon in Home's `AppBar`
— shown only when `_navIndex == 0`, matching "Home AppBar" literally.

**Task 8 — Router.** ✅
Added `/home`, `/today`, `/learn`, `/library` (each `HomeScreen` with a
different `initialIndex` — a new optional constructor parameter,
default `0`, so the existing `/` route needed zero changes) and
`/settings`. All 11 pre-existing routes diffed byte-identical.

**Task 9 — Regression Review.** ✅
Diffed against the pre-sprint checkpoint: exactly 3 files modified
(`app_router.dart`, `home_screen.dart`, `home_bottom_nav_bar.dart`) and
6 created. Explicitly confirmed byte-identical: `document_repository.dart`,
both concrete repositories, `database_service.dart`, `search_service.dart`,
`backlink_engine.dart`, `wiki_link_service.dart`, `document_model.dart`.
No provider redesign — the only provider-adjacent change is
`HomeBottomNavBar`'s callback losing its index==1 special case, a
simplification forced by Task 1, not a redesign.

### Known issues / accepted limitations
- The new `/home` `/today` `/learn` `/library` routes aren't yet linked
  from anywhere in the app (no code calls `context.push` on them) —
  they exist for future deep-linking; the bottom nav bar itself still
  drives tab switching via local `setState`, not routing. Consistent
  with this sprint's "shell only" scope.
- Today's placeholder "Daily Notes" section does not link to the real,
  working Sprint 23 daily-note flow — deliberately, to keep this
  sprint's placeholders uniformly inert rather than selectively wiring
  one of six sections while leaving the other five static.
- `PlaceholderCard` has no `onTap` — Learn's and the AI bubble's "coming
  soon" SnackBar/sheet pattern wasn't extended to it, since Task 5
  explicitly said "only placeholders."

### Files created this sprint
- `lib/core/widgets/placeholder_card.dart`
- `lib/features/today/presentation/today_screen.dart`
- `lib/features/learn/presentation/learn_screen.dart`
- `lib/features/library/presentation/library_screen.dart`
- `lib/home/presentation/widgets/ai_bubble_button.dart`
- `lib/settings/presentation/settings_screen.dart`

### Files modified this sprint
- `lib/home/presentation/home_screen.dart` — added `initialIndex`,
  `IndexedStack` body, `AppBar`, four new Home sections, combined FAB.
  Every existing provider read, the delete-confirmation dialog, and
  Objectives/Tasks rendering logic are unchanged.
- `lib/home/presentation/widgets/home_bottom_nav_bar.dart` — four
  destinations swapped; nav bar's own widget shape unchanged.
- `lib/core/router/app_router.dart` — 5 new routes, additive only.

### V2-01 status: complete
All 9 tasks done and verified. Next sprint should fold this into
Completed Sprints above and start a fresh Current Sprint section.

---

## V2-02 — Home Dashboard. COMPLETE (all 8 tasks).

Verified before starting: Sprint 21/22's search/wiki-link/backlink work
is intact in this codebase (checked directly, not assumed).

- **Task 1** — `GreetingHeader` already had date+greeting; added a
  static motivational subtitle line (additive).
- **Task 2** — `DailyProgressCard` already covered score+ring; added
  `RemainingSummaryRow` (new, separate widget) for remaining
  objectives/tasks counts, from lists Home already fetches (no
  duplicated calculation).
- **Task 3** — found a real gap: `tasksProvider` returns *all* tasks,
  so "Remaining Tasks" was showing completed ones too. Filtered to
  `!isCompleted` at the point of use. `TaskCard` and its behavior
  were already correct, untouched.
- **Task 4** — new `lib/features/quick_clipboard/` (repository/
  provider/widget). Added `path_provider` — the only new package,
  genuinely needed since SQLite is off-limits per this sprint's own
  regression check and nothing else durable/cross-platform existed.
  Autosave mirrors the editor's exact 800ms debounce.
- **Task 5** — added an optional `trailing` slot to `PlaceholderCard`
  (additive; every other call site unaffected) for the "Start
  Session" button, which shows a "coming soon" snackbar only.
- **Task 6** — new `QuickActionsCard` (pure UI, takes callbacks).
  "New Task" reuses the existing `showTaskFormSheet` call already on
  Home. "Today's Note" reuses `DailyNoteService.getOrCreate` exactly
  as Day Workspace does. "New Note" builds a blank `Document` and
  pushes to the existing editor route, unsaved until the editor's own
  autosave persists it — avoids littering empty files from an
  untouched new-note tap.
- **Task 7** — one-line addition of the exact required subtitle text.
- **Task 8** — confirmed via diff against V2-01: repository/SQLite/
  markdown/vault/search/backlink code is absent from this sprint's
  diff; no AI logic added.

### Files created (V2-02)
- `lib/features/quick_clipboard/data/quick_clipboard_repository.dart`
- `lib/features/quick_clipboard/logic/quick_clipboard_provider.dart`
- `lib/features/quick_clipboard/presentation/widgets/quick_clipboard_card.dart`
- `lib/home/presentation/widgets/quick_actions_card.dart`
- `lib/home/presentation/widgets/remaining_summary_row.dart`

### Files modified (V2-02)
- `lib/home/presentation/home_screen.dart` (main integration)
- `lib/core/widgets/placeholder_card.dart` (additive `trailing`)
- `lib/home/presentation/widgets/greeting_header.dart` (additive subtitle)
- `pubspec.yaml` (added `path_provider`)

### Known issues
- No test added — this sprint is UI + a small file-I/O repository,
  neither fitting this project's established unit-test pattern (pure
  Logic-layer services), unlike Sprints 21/22.
- Focus Mode's button is inert beyond a snackbar, matching "no
  blocking functionality yet" literally.
