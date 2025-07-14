# Changelog

All notable changes to this project will be documented in this file.

## [0.1.2] - 2025-07-15
### Changed
- Updated lexicon file pattern to match any locale (e.g., be-nl, si-sl) using `*.jsonl` wildcard.
- Added fixtures and test coverage for Belgium Dutch (be-nl) locale.
- Adjusted tests to support multi-part locale codes and order-independent file path assertions.

## [0.1.1] - 2025-07-15

- Glot.loaded_files() function to see, which files were loaded
- some code cleanup

## [0.1.0] - 2025-07-15
### Added
- Initial release: minimalistic translation system for Elixir using JSONL glossaries. 