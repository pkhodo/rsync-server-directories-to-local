# Server Sync Tool

<div align="center">

**A simple, safe bash script for one-way syncing directories from a remote server to your local machine using rsync over SSH.**

*Yes, it's probably over-engineered for what it does. But hey, at least it won't delete your cat photos! 🐱*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](https://github.com/pkhodo/rsync-server-directories-to-local/releases)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub stars](https://img.shields.io/github/stars/pkhodo/rsync-server-directories-to-local?style=social)](https://github.com/pkhodo/rsync-server-directories-to-local/stargazers)

Perfect for keeping local development environments in sync with production or staging servers.

[Quick Start](#quick-start) • [Features](#features) • [Documentation](#configuration) • [Contributing](./CONTRIBUTING.md)

</div>

## Features

✅ **One-way only**: Only reads from server, never writes (we're not monsters)  
✅ **Dry-run by default**: Safe testing mode - see what would happen before syncing (like a preview before buying)  
✅ **SSH connection sharing**: Password prompt only once (even for multiple folders - we're efficient like that)  
✅ **Protected files**: Won't delete local development files (`.git`, `.env`, `node_modules`, etc. - your secrets are safe)  
✅ **Simple config**: One file to configure all folder mappings (because life's complicated enough)  
✅ **Comprehensive logging**: All operations logged with timestamps (for when you need to prove it wasn't your fault)  
✅ **Safe by design**: Multiple safety checks prevent accidental data loss (we've seen things...)

## What This Script Does

- **Syncs files** from your server to your local machine (like a digital photocopier, but smarter)
- **Deletes local files** that don't exist on the server (unless excluded - we're not barbarians)
- **Preserves local-only files** that match exclusion patterns (your local experiments are safe)
- **Logs everything** to `~/Library/Logs/sync-server-to-local/` (macOS) or `~/.local/logs/sync-server-to-local/` (Linux)

## Quick Start

### 1. Clone or Download

```bash
git clone https://github.com/pkhodo/rsync-server-directories-to-local.git
cd rsync-server-directories-to-local
```

*Or just download the ZIP if you're not into the whole git thing. We don't judge.*

### 2. Configure Server Connection

Edit `sync.sh` and update these variables at the top:

```bash
SERVER="username@server.example.com"      # Your SSH server
REMOTE_BASE="/path/to/docs"                # Base path on server
```

*Pro tip: Make sure you can actually SSH to this server. Trust us on this one.*

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
- `local_destination` must be an absolute path (no relative paths - we're not mind readers)
- Use `|` (pipe) to separate remote and local paths (not a comma, not a semicolon, a pipe. Yes, really.)

### 4. Test (Dry-Run)

Always test first! The script runs in dry-run mode by default (because we've learned from experience):

```bash
chmod +x sync.sh
./sync.sh
```

This will show you what would be synced without making any changes. *It's like a dress rehearsal, but for your files.*

### 5. Run Actual Sync

When you're ready to actually sync (and you've double-checked everything, right?):

```bash
SYNC_DRY_RUN=0 ./sync.sh
```

You'll be prompted for your SSH password once (even if syncing multiple folders - we're not sadists).

### Optional: Set Up Aliases

Want to make your life easier? We've included example aliases and helper functions! 

Copy `aliases.example` to your shell config and customize it:

```bash
# Add to ~/.zshrc or ~/.bashrc
cat aliases.example >> ~/.zshrc

# Edit the SCRIPT_PATH variable in the file, then reload:
source ~/.zshrc
```

This gives you convenient commands like:
- `syncserver` - Dry-run sync (safe preview)
- `syncserverreal` - Actual sync
- `syncserverstatus` - Check if sync is running and see progress
- `killsyncserver` - Stop a running sync
- `syncserverdiff` - Quick preview of file differences

*Because typing long paths is so 2020.*

## Installation Script

Want to skip the manual setup? We've got you covered:

```bash
curl -fsSL https://raw.githubusercontent.com/pkhodo/rsync-server-directories-to-local/main/install.sh | bash
```

*Just kidding - we don't have that. But we could! Maybe in v2.0? 😏*

Actually, here's a simple one-liner to get you started:

```bash
git clone https://github.com/pkhodo/rsync-server-directories-to-local.git && \
cd rsync-server-directories-to-local && \
cp sync-config.txt.example sync-config.txt && \
chmod +x sync.sh && \
echo "✅ Done! Now edit sync.sh and sync-config.txt with your settings"
```

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

# Multiple folders (because one is never enough)
import|/Users/john/project/import
exports|/Users/john/project/exports
```

### Protecting Local-Only Files

The script automatically excludes common development files:
- `.git`, `.env`, `node_modules`, `.DS_Store`, `.idea`, `.vscode`, etc.

*We've got a whole list. It's like a VIP exclusion list for your files.*

To protect additional files, create `~/.sync-excludes`:

```bash
# ~/.sync-excludes
my-local-config.json
custom-dev-files/
*.local-only
secrets/
```

Each line is a pattern that will be excluded from deletion. *Think of it as a "do not delete" list for your files.*

## Understanding the Sync Behavior

### What Gets Synced

- **New files** on server → copied to local (like a digital Santa, but year-round)
- **Modified files** on server → updated locally (keeping things fresh)
- **Deleted files** on server → deleted locally (unless excluded - we're not heartless)

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
  .env (protected, not deleted - your secrets are safe!)
```

`file3.txt` would be deleted unless it matches an exclusion pattern. *RIP file3.txt (unless you protected it)*

## Logs

All operations are logged to:
- **macOS**: `~/Library/Logs/sync-server-to-local/sync-YYYYMMDD-HHMMSS.log`
- **Linux**: `~/.local/logs/sync-server-to-local/sync-YYYYMMDD-HHMMSS.log`

Each sync creates a new log file with a timestamp. *Because accountability is important, even for scripts.*

## Performance

### Benchmarks

*Okay, we don't have official benchmarks yet. But here's what we know:*

- **Small directories** (< 100 files): Usually completes in seconds
- **Medium directories** (100-10,000 files): Depends on file sizes, but typically under a minute
- **Large directories** (> 10,000 files): Grab a coffee ☕

*Actual performance depends on:*
- Network speed (obviously)
- File sizes (big files = longer sync)
- Server performance (is your server from 2003?)
- Number of folders being synced (more folders = more time)

**Pro tip**: Use dry-run mode first to see how long it would take. *It's like checking the weather before going outside.*

### Optimization Tips

- Sync only what you need (don't sync your entire server - that's what backups are for)
- Use exclusions for large directories you don't need locally
- Consider syncing during off-peak hours if you have bandwidth concerns
- The script uses rsync's delta algorithm, so only changed files are transferred

## Security

### Safety Features

1. **Read-only operations**: Script only reads from server, never writes
   - *We literally can't write to your server. It's physically impossible. Well, code-wise impossible.*

2. **Dry-run default**: Must explicitly set `SYNC_DRY_RUN=0` to sync
   - *We make you work for it. Safety first!*

3. **Protected files**: Common dev files automatically excluded
   - *Your `.env` files are safe. Your secrets are safe. Your sanity is... well, that's on you.*

4. **Path validation**: Checks for dangerous patterns
   - *No `../` shenanigans. We've seen that movie.*

5. **Lock file**: Prevents multiple simultaneous runs
   - *Because two syncs at once is like two cooks in a kitchen - chaos.*

6. **Comprehensive logging**: All operations logged for audit
   - *For when you need to prove it wasn't your fault (it probably wasn't).*

### Security Best Practices

- **Use SSH keys** instead of passwords when possible
  ```bash
  ssh-copy-id username@server.example.com
  ```
- **Review exclusions** before syncing sensitive data
- **Check logs** regularly to ensure expected behavior
- **Test with dry-run** before actual syncs (we can't stress this enough)

*Remember: This script syncs FROM server TO local. If you're worried about security, make sure your server is secure first. We're just the messenger here.*

## Creating Aliases (Optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# Dry-run (default) - the safe way
alias syncserver='cd /path/to/rsync-server-directories-to-local && ./sync.sh'

# Actual sync - when you're feeling brave
alias syncserver-now='cd /path/to/rsync-server-directories-to-local && SYNC_DRY_RUN=0 ./sync.sh'
```

Then reload: `source ~/.zshrc`

*Now you can sync with style! 🎩*

## Troubleshooting

### "Cannot reach server host"

- Make sure you're connected to VPN (if required)
- Check that the server hostname is correct
- Verify network connectivity: `ping server.example.com`
- *Is your internet working? Have you tried turning it off and on again?*

### "Permission denied (publickey,password)"

- The script will prompt for your SSH password
- If you want to use SSH keys, set them up first: `ssh-copy-id username@server.example.com`
- Make sure your SSH key is added to `ssh-agent`
- *SSH keys are like passwords, but cooler and more secure.*

### "Config file not found"

- Make sure `sync-config.txt` exists in the same directory as `sync.sh`
- Check that you copied it from the example: `cp sync-config.txt.example sync-config.txt`
- *Did you remember to copy it? We've all been there.*

### "No valid folder mappings found"

- Check your `sync-config.txt` format: `remote_folder|local_destination`
- Make sure there are no empty lines (or they're commented with `#`)
- Verify paths don't have extra spaces
- *Format matters. Like a good joke, timing and structure are everything.*

### Files are being deleted that shouldn't be

- Add patterns to `~/.sync-excludes`
- Check that your exclusion patterns match correctly
- Use dry-run mode first to see what would be deleted
- *When in doubt, exclude it out.*

### "Sync already running"

- Another instance of the script is running
- Wait for it to finish, or remove the lock file: `rm /tmp/sync-server-to-local.lock`
- Check for stuck processes: `ps aux | grep sync.sh`
- *Patience, young padawan. One sync at a time.*

## Requirements

- **Bash** 4.0+ (most systems have this - if you don't, you have bigger problems)
- **rsync** (usually pre-installed on macOS/Linux - if not, `brew install rsync` or `apt-get install rsync`)
- **SSH access** to your server (obviously)
- **macOS or Linux** (tested on macOS, should work on Linux - Windows users, we're sorry, but WSL is your friend)

## Safety Features

1. **Read-only operations**: Script only reads from server, never writes
2. **Dry-run default**: Must explicitly set `SYNC_DRY_RUN=0` to sync
3. **Protected files**: Common dev files automatically excluded
4. **Path validation**: Checks for dangerous patterns
5. **Lock file**: Prevents multiple simultaneous runs
6. **Comprehensive logging**: All operations logged for audit

*We take safety seriously. Probably too seriously. But better safe than sorry, right?*

## Use Cases

- **Development**: Sync production data to local environment for testing
  - *"But it works on my machine!" - Now it can work on your machine too!*
- **Backup**: Keep local copies of important server directories
  - *Because backups are like insurance - you hope you never need them, but you're glad they're there*
- **Content Management**: Sync uploaded files from production to local
  - *All those cat memes need to be synced too, right?*
- **Database Files**: Sync database dumps or data files
  - *For when you need production data but don't want to ask the DBA nicely*
- **Media Assets**: Sync images, videos, or other media files
  - *Because sometimes you need that 4K video of a cat playing piano locally*

## Why This Tool?

- ✅ **Safe by default**: Dry-run mode prevents accidental changes
- ✅ **Simple configuration**: One file to configure all folder mappings
- ✅ **No dependencies**: Just bash and rsync (usually pre-installed)
- ✅ **Cross-platform**: Works on macOS and Linux
- ✅ **Well documented**: Comprehensive README and troubleshooting guide (you're reading it!)
- ✅ **Protected files**: Automatically excludes common development files
- ✅ **Over-engineered**: We admit it. But at least it works! 😅

## Alternatives

If you need bidirectional sync, consider:
- [rsync](https://rsync.samba.org/) - Manual bidirectional sync (the OG)
- [rclone](https://rclone.org/) - Cloud storage sync tool (for the cloud enthusiasts)
- [syncthing](https://syncthing.net/) - Continuous file synchronization (set it and forget it)

This tool is specifically designed for **one-way server-to-local** sync with safety features built-in. *We're not trying to replace rsync - we're just making it easier and safer to use.*

## Contributing

Found a bug or have a suggestion? Please open an issue or submit a pull request!

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

*We welcome contributions! Even if it's just fixing a typo. Every little bit helps.*

## Contributors

<div align="center">

**Made with ❤️ (and probably too much coffee ☕)**

[![Contributors](https://img.shields.io/github/contributors/pkhodo/rsync-server-directories-to-local)](https://github.com/pkhodo/rsync-server-directories-to-local/graphs/contributors)

*Want to see your name here? Contribute! We're friendly, we promise.*

</div>

## License

MIT License - see [LICENSE](LICENSE) file for details.

*Free as in speech, free as in beer. Use it, modify it, make it better!*

## Disclaimer

**Use at your own risk.** Always test with dry-run mode first. The script will delete local files that don't exist on the server (unless excluded). Make sure you have backups of important local files before running actual syncs.

*We're not responsible for deleted cat photos, lost code, or existential crises caused by syncing. But we'll try to help if something goes wrong!*

---

<div align="center">

**Made with ❤️ and probably too much over-engineering**

*If you find this useful, consider giving it a ⭐. It makes us feel warm and fuzzy inside.*

[Report Bug](https://github.com/pkhodo/rsync-server-directories-to-local/issues) • [Request Feature](https://github.com/pkhodo/rsync-server-directories-to-local/issues) • [View Changelog](./CHANGELOG.md)

</div>
