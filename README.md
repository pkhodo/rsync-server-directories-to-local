# Simple Server Sync Script

**One-way sync from server to local. Manual execution only.**

A simple, safe bash script for syncing specific folders from a remote server to your local machine using rsync over SSH. Perfect for keeping local development environments in sync with production or staging servers.

## Features

✅ **One-way only**: Only reads from server, never writes  
✅ **Dry-run by default**: Safe testing mode - see what would happen before syncing  
✅ **SSH connection sharing**: Password prompt only once (even for multiple folders)  
✅ **Protected files**: Won't delete local development files (`.git`, `.env`, `node_modules`, etc.)  
✅ **Simple config**: One file to configure all folder mappings  
✅ **Comprehensive logging**: All operations logged with timestamps  
✅ **Safe by design**: Multiple safety checks prevent accidental data loss  

## What This Script Does

- **Syncs files** from your server to your local machine
- **Deletes local files** that don't exist on the server (unless excluded)
- **Preserves local-only files** that match exclusion patterns
- **Logs everything** to `~/Library/Logs/sync-server-to-local/` (macOS) or `~/.local/logs/sync-server-to-local/` (Linux)

## Quick Start

### 1. Clone or Download

```bash
git clone https://github.com/pkhodo/rsync-server-directories-to-local.git
cd rsync-server-directories-to-local
```

### 2. Configure Server Connection

Edit `sync.sh` and update these variables at the top:

```bash
SERVER="username@server.example.com"      # Your SSH server
REMOTE_BASE="/path/to/docs"                # Base path on server
```

### 3. Configure Folder Mappings

Copy the example config and edit it:

```bash
cp sync-config.txt.example sync-config.txt
# Edit sync-config.txt with your actual paths
```

Edit `sync-config.txt` with your folder mappings (one per line):

```
# Format: remote_folder|local_destination
# Remote folders are relative to REMOTE_BASE on the server

backups|/Users/username/local/backups
import|/Users/username/local/import
web/sites/default/files|/Users/username/local/web/sites/default/files
```

**Important:**
- `remote_folder` is relative to `REMOTE_BASE` (e.g., `backups` means `REMOTE_BASE/backups`)
- `local_destination` must be an absolute path
- Use `|` (pipe) to separate remote and local paths

### 4. Test (Dry-Run)

Always test first! The script runs in dry-run mode by default:

```bash
chmod +x sync.sh
./sync.sh
```

This will show you what would be synced without making any changes.

### 5. Run Actual Sync

When you're ready to actually sync:

```bash
SYNC_DRY_RUN=0 ./sync.sh
```

You'll be prompted for your SSH password once (even if syncing multiple folders).

## Configuration

### sync-config.txt Format

```
remote_folder|local_destination
```

**Examples:**

```
# Simple folder sync
backups|/Users/john/project/backups

# Nested folder sync
web/sites/default/files|/Users/john/project/web/sites/default/files

# Multiple folders
import|/Users/john/project/import
exports|/Users/john/project/exports
```

### Protecting Local-Only Files

The script automatically excludes common development files:
- `.git`, `.env`, `node_modules`, `.DS_Store`, `.idea`, `.vscode`, etc.

To protect additional files, create `~/.sync-excludes`:

```bash
# ~/.sync-excludes
my-local-config.json
custom-dev-files/
*.local-only
secrets/
```

Each line is a pattern that will be excluded from deletion.

## Understanding the Sync Behavior

### What Gets Synced

- **New files** on server → copied to local
- **Modified files** on server → updated locally
- **Deleted files** on server → deleted locally (unless excluded)

### What's Protected

- Files matching exclusion patterns (see above)
- Files listed in `~/.sync-excludes`
- Local-only files that don't exist on server (if excluded)

### Example Scenario

**Server has:**
```
backups/
  file1.txt
  file2.txt
```

**Local has:**
```
backups/
  file1.txt (older version)
  file2.txt
  file3.txt (local-only)
  .env (local config)
```

**After sync:**
```
backups/
  file1.txt (updated from server)
  file2.txt (unchanged)
  .env (protected, not deleted)
```

`file3.txt` would be deleted unless it matches an exclusion pattern.

## Logs

All operations are logged to:
- **macOS**: `~/Library/Logs/sync-server-to-local/sync-YYYYMMDD-HHMMSS.log`
- **Linux**: `~/.local/logs/sync-server-to-local/sync-YYYYMMDD-HHMMSS.log`

Each sync creates a new log file with a timestamp.

## Creating Aliases (Optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Dry-run (default)
alias syncserver='cd /path/to/rsync-server-directories-to-local && ./sync.sh'

# Actual sync
alias syncserver-now='cd /path/to/rsync-server-directories-to-local && SYNC_DRY_RUN=0 ./sync.sh'
```

Then reload: `source ~/.zshrc`

## Troubleshooting

### "Cannot reach server host"

- Make sure you're connected to VPN (if required)
- Check that the server hostname is correct
- Verify network connectivity: `ping server.example.com`

### "Permission denied (publickey,password)"

- The script will prompt for your SSH password
- If you want to use SSH keys, set them up first: `ssh-copy-id username@server.example.com`
- Make sure your SSH key is added to `ssh-agent`

### "Config file not found"

- Make sure `sync-config.txt` exists in the same directory as `sync.sh`
- Check that you copied it from the example: `cp sync-config.txt.example sync-config.txt`

### "No valid folder mappings found"

- Check your `sync-config.txt` format: `remote_folder|local_destination`
- Make sure there are no empty lines (or they're commented with `#`)
- Verify paths don't have extra spaces

### Files are being deleted that shouldn't be

- Add patterns to `~/.sync-excludes`
- Check that your exclusion patterns match correctly
- Use dry-run mode first to see what would be deleted

### "Sync already running"

- Another instance of the script is running
- Wait for it to finish, or remove the lock file: `rm /tmp/sync-server-to-local.lock`
- Check for stuck processes: `ps aux | grep sync.sh`

## Requirements

- **Bash** 4.0+ (most systems have this)
- **rsync** (usually pre-installed on macOS/Linux)
- **SSH access** to your server
- **macOS or Linux** (tested on macOS, should work on Linux)

## Safety Features

1. **Read-only operations**: Script only reads from server, never writes
2. **Dry-run default**: Must explicitly set `SYNC_DRY_RUN=0` to sync
3. **Protected files**: Common dev files automatically excluded
4. **Path validation**: Checks for dangerous patterns
5. **Lock file**: Prevents multiple simultaneous runs
6. **Comprehensive logging**: All operations logged for audit

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Found a bug or have a suggestion? Please open an issue or submit a pull request!

## Disclaimer

**Use at your own risk.** Always test with dry-run mode first. The script will delete local files that don't exist on the server (unless excluded). Make sure you have backups of important local files before running actual syncs.
