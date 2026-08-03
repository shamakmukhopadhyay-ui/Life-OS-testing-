# LifeOS — Document Architecture
**Sprint 10 | Design + Foundation**

> **Sprint 15 update:** `ObsidianDocumentRepository` (§1, §2) is now implemented —
> see its class doc comment for the read/write design. The YAML risk in §10 is
> addressed. Everything else below is unchanged from Sprint 10 and still
> reflects the pre-Vault-refactor `DocumentSource` enum in a few places (the
> class diagram in §2, §5's provider names, `getOrCreate`'s signature in §4) —
> those are pre-existing staleness from before the Vault model landed, not
> something this sprint's diff touches. Flagging rather than fixing silently,
> since a full pass is a bigger, separate cleanup than one feature's worth.

> **Sprint 21 update:** Global Search and the Tag Explorer are built *on top*
> of this design, not a change to it. `SearchService`
> (`lib/features/documents/logic/search_service.dart`) and the two new
> screens it feeds consume `DocumentRepository.getAll()` results exactly as
> every other feature does — neither `DocumentRepository.search()` nor
> `getByTag()` (§3) is called by them. See `search_service.dart`'s own doc
> comment for why an in-memory scan is sufficient at this app's scale.
> Everything else in this document is unchanged and carries the same
> Sprint-10/15 staleness already flagged above.

---

## 1. Folder Structure

```
lib/features/documents/
  data/
    document_model.dart              ← Document entity, DocumentSource enum
    document_repository.dart         ← Abstract interface (the contract)
    internal_document_repository.dart ← Stub: SQLite + local filesystem
    obsidian_document_repository.dart ← Implemented (Sprint 15): FileSystemService-backed Obsidian adapter
  logic/
    daily_note_service.dart          ← Path conventions, get-or-create logic
    document_provider.dart           ← Riverpod providers
  presentation/
    (empty — editor UI is a future sprint)
```

---

## 2. Class Diagram

```
         ┌──────────────────────────────────┐
         │         DocumentRepository        │  ← abstract interface
         │  + getByPath(path): Document?     │
         │  + search(query): List<Document>  │
         │  + getAll(): List<Document>       │
         │  + getByTag(tag): List<Document>  │
         │  + save(doc): Document            │
         │  + delete(path): void             │
         │  + exists(path): bool             │
         └──────────────────┬───────────────┘
                            │ implements
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
  InternalDocument   ObsidianDocument   (future)
    Repository         Repository       GoogleDriveDocumentRepository
  (SQLite + fs)     (vault filesystem)

         ┌───────────────────────────────────┐
         │             Document              │  ← immutable model
         │  path: String         (PK)        │
         │  title: String                    │
         │  content: String      (markdown)  │
         │  source: DocumentSource           │
         │  frontmatter: Map<String,dynamic> │
         │  tags: List<String>               │
         │  backlinks: List<String>          │
         │  metadata: Map<String,dynamic>    │
         │  createdAt: DateTime              │
         │  updatedAt: DateTime              │
         └───────────────────────────────────┘

         ┌───────────────────────────────────┐
         │          DailyNoteService         │  ← pure Dart service
         │  + dailyNotePath(date): String    │
         │  + getOrCreate(repo, date): Doc   │
         └───────────────────────────────────┘
```

---

## 3. Repository Interface

`DocumentRepository` is the sole abstraction every consumer uses.
No widget, provider, or service outside `features/documents/` imports
a concrete repository class.

```dart
abstract class DocumentRepository {
  Future<Document?> getByPath(String path);
  Future<List<Document>> search(String query);
  Future<List<Document>> getAll();
  Future<List<Document>> getByTag(String tag);
  Future<Document> save(Document document);
  Future<void> delete(String path);
  Future<bool> exists(String path);
}
```

---

## 4. Service Interface

`DailyNoteService` owns the naming convention and get-or-create pattern.
No screen or provider computes a daily note path directly.

```dart
class DailyNoteService {
  static String dailyNotePath(DateTime date);
  static Future<Document?> get(DocumentRepository repo, DateTime date);
  static Future<Document> getOrCreate(DocumentRepository repo, DateTime date);
}
```

---

## 5. Provider Structure

```
activeDocumentSourceProvider   StateProvider<DocumentSource>
  → user setting (internal | obsidian | googleDrive)

documentRepositoryProvider     Provider<DocumentRepository>
  → switches on activeDocumentSourceProvider
  → throws UnimplementedError until source is registered

dailyNoteProvider(DateTime)    FutureProvider.family<Document?, DateTime>
  → reads documentRepositoryProvider
  → calls DailyNoteService.get(repo, date)
```

Consumers (e.g. `DayWorkspaceScreen`) watch `dailyNoteProvider(date)`.
They never import a concrete repository.

---

## 6. Data Flow

```
DayWorkspaceScreen
  │  watches dailyNoteProvider(date)
  ▼
dailyNoteProvider
  │  reads documentRepositoryProvider
  │  calls DailyNoteService.dailyNotePath(date)
  ▼
DocumentRepository (abstract)
  │
  ├─ InternalDocumentRepository  →  SQLite (metadata) + local .md files
  │
  └─ ObsidianDocumentRepository  →  reads vault path from Settings
                                     parses frontmatter + backlinks
```

The screen sees only `Document?`. Source switching is a provider override.

---

## 7. Path Convention

Daily notes follow a deterministic path regardless of source:

```
daily/YYYY-MM-DD.md
```

- **Internal**: stored as a file under the app's documents directory
  at `{appDocDir}/lifeos/daily/YYYY-MM-DD.md`, metadata in SQLite.
- **Obsidian**: the same relative path inside the configured vault root,
  with no path mapping — Sprint 15 deliberately assumes a standard vault
  layout. A user whose vault uses a different convention (e.g.
  `Journal/YYYY/...`) isn't supported yet; a configurable mapping
  remains future scope, not attempted here.

---

## 8. Document Model — Key Decisions

| Field | Type | Rationale |
|---|---|---|
| `path` | `String` (PK) | Natural for Obsidian; backlinks reference paths |
| `content` | `String` | Raw markdown; never parsed in this layer |
| `frontmatter` | `Map<String,dynamic>` | YAML parsed by adapter; `tags` derived from it |
| `tags` | `List<String>` | Denormalized from frontmatter for fast filtering |
| `backlinks` | `List<String>` | Paths of other docs that link to this one |
| `source` | `DocumentSource` | Lets UI show provenance badge if needed |
| `metadata` | `Map<String,dynamic>` | Adapter-specific data (vault path, Drive ID, …) |

**`path` as PK trade-off:** A rename breaks all backlinks. This matches
Obsidian's own behaviour; a rename-aware link-updater is future scope.

---

## 9. Future Compatibility

| Capability | How the current design supports it |
|---|---|
| NotebookLM-style AI | `search(query)` returns `List<Document>`; AI reads content without knowing the source |
| Semantic search | Add `searchSemantic(embedding)` to `DocumentRepository`; existing callers unaffected |
| Knowledge Base | A knowledge base is a `List<Document>` with curated tags; no model change |
| Obsidian vaults | `ObsidianDocumentRepository` already in the interface |
| Internal documents | `InternalDocumentRepository` already in the interface |
| Google Drive | Implement `GoogleDriveDocumentRepository`; register in provider |
| Multiple vaults | `documentRepositoryProvider` can become a family; deferred |

---

## 10. Risks

| Risk | Severity | Note |
|---|---|---|
| YAML frontmatter parsing edge cases | ~~Medium~~ Addressed (Sprint 15) | `parseFrontmatter` (`core/utils/frontmatter_parser.dart`) uses the `yaml` package and degrades to `{}` on malformed input; content is never re-serialized from the parsed map, so parsing risk can't corrupt a write |
| Obsidian file-change detection | Medium | Requires platform file-system watchers (not in scope until a future sync sprint) |
| Daily note path mismatch | Medium | Sprint 15 explicitly assumes a standard vault layout with no mapping; a user with a non-standard structure isn't supported until a configurable path template is built |
| Rename breaks backlinks | Low | Accepted trade-off; rename-aware update deferred |
| Frontmatter write-back | Low | Resolved for Sprint 15's scope — `save()` never reconstructs YAML, so there is no partial-overwrite path to begin with |
| Obsidian `createdAt`/`updatedAt` fidelity | Low | `FileSystemService` has no stat/mtime accessor; both are read-time placeholders today. See `obsidian_document_repository.dart`'s class doc and Sprint 15 Technical Debt |

---

## 11. Trade-offs

| Decision | Alternative | Reason chosen |
|---|---|---|
| `path` as PK | UUID | Obsidian compatibility; deterministic daily note paths |
| Raw markdown in model | Parsed AST | Keeps model source-agnostic; parsing is a presentation concern |
| Single `DocumentRepository` interface | Per-source service | Enables transparent source switching in one provider override |
| `metadata: Map<String,dynamic>` | Typed per-source subclass | Avoids sealed class explosion while still carrying adapter data |
| Frontmatter as `Map<String,dynamic>` | Typed class | Obsidian frontmatter is user-defined; a typed class would be too rigid |
