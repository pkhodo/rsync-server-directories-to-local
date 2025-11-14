# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-11-14

### Added
- Example aliases and helper functions (`aliases.example`)
- Convenient shell commands: `syncserver`, `syncserverreal`, `syncserverstatus`, `killsyncserver`, `syncserverdiff`
- Status checking function to monitor sync progress
- Kill switch function to safely stop running syncs
- Quick diff preview function

### Documentation
- Added "Optional: Set Up Aliases" section to README
- Improved user experience documentation

## [1.0.0] - 2025-11-14

### Added
- Initial release of Server Sync Tool
- One-way sync from server to local using rsync over SSH
- Dry-run mode by default for safety
- SSH connection sharing to avoid multiple password prompts
- Comprehensive logging with timestamps
- Protection for common development files (`.git`, `.env`, `node_modules`, etc.)
- Support for custom exclusion patterns via `~/.sync-excludes`
- Cross-platform support (macOS and Linux)
- Lock file mechanism to prevent concurrent runs
- Safety checks to prevent running on the server
- Detailed README with troubleshooting guide

### Security
- Read-only operations: script only reads from server, never writes
- Path validation to prevent dangerous patterns
- Safety checks to ensure script runs from local machine only

