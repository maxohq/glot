# Live Reloading for Glot Modules - Specification

## Purpose & User Problem
Currently, when translation files change, developers must manually call `reload()` on their Glot modules. This creates friction in the development workflow. We need automatic live reloading that detects file changes and automatically reloads the affected modules.

## Success Criteria
1. **Opt-in Activation**: Live reloading is only enabled for modules that explicitly opt-in by passing `watch: true` as an argument to `use Glot` (e.g., `use Glot, ..., watch: true`).
2. **Automatic Detection**: File system watcher detects changes to translation files (`.jsonl` files) in the immediate base folder
3. **Self-Managing Modules**: Modules automatically register themselves for reloading when they start (if `watch: true`)
4. **Non-blocking**: Reloading happens in background without blocking the application
5. **Error Handling**: Keep old translations and log errors when reload fails
6. **Development Only**: Feature should only be active in development environment

## Scope & Constraints

**In Scope:**
- File system watching for `.jsonl` files in immediate `base` directories only
- Automatic self-registration of Glot modules when they start (if `watch: true`)
- Automatic reloading of affected modules
- Development environment detection
- Debounced file change handling
- Error logging for failed reloads
- Opt-in via `watch: true` argument

**Out of Scope:**
- Production environment activation
- Recursive directory watching
- Manual reload triggers
- UI for monitoring reload status
- Automatic watching for all modules (must be opted-in)

## Technical Considerations

**Implementation Steps:**
1. **File Watcher Service**: Create `Glot.Watcher` GenServer that watches base directories
2. **Module Self-Registration**: Modules register themselves when they start via `Glot.Translator` (only if `watch: true`)
3. **Change Detection**: Map file changes to affected modules using registry
4. **Debounced Reloading**: Trigger reloads with debouncing to handle rapid saves
5. **Error Handling**: Log errors and keep old translations

**Key Design Decisions:**
- Use `FileSystem` library for cross-platform file watching
- Registry pattern where modules register their file dependencies (if `watch: true`)
- Async reloading to avoid blocking
- Development-only activation via `Mix.env()`
- 500ms debounce for file changes
- Info-level logging for reload events
- Opt-in via `watch: true` argument to `use Glot`

**Dependencies:**
- Add `file_system` to `mix.exs`
- Create `Glot.Watcher` module
- Extend `Glot.Translator` for self-registration (only if `watch: true`)

## Questions for Clarification:

1. **File Watching Scope**: Should we watch all subdirectories recursively, or only the immediate `base` directory?
   - **Answer**: Immediate base folder only

2. **Module Discovery**: How should we discover which modules use which translation files? Options:
   - Static analysis of module configurations
   - Runtime registration when modules start
   - Configuration-based mapping
   - **Answer**: Self-registration when modules start (if `watch: true`)

3. **Error Recovery**: If a reload fails (invalid JSONL), should we:
   - Keep the old translations and log the error?
   - Stop watching that file?
   - Retry after a delay?
   - **Answer**: Keep old and log error

4. **Performance**: Should we debounce rapid file changes (e.g., multiple saves in quick succession)?
   - **Answer**: Yes, debounce

5. **Logging**: What level of logging do you want for reload events?
   - **Answer**: Info level

6. **Opt-in**: Should live reloading be opt-in or enabled for all modules?
   - **Answer**: Opt-in via `watch: true` argument to `use Glot` 