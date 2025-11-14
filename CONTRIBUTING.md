# Contributing to Server Sync Tool

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Your operating system and version
- Any relevant error messages or logs

### Suggesting Enhancements

Feature suggestions are welcome! Please open an issue with:
- A clear description of the enhancement
- Use case or problem it would solve
- Any examples or mockups if applicable

### Pull Requests

1. **Fork the repository** and create a new branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the coding style:
   - Use bash best practices
   - Add comments for complex logic
   - Test your changes on both macOS and Linux if possible
   - Update documentation if needed

3. **Test your changes**:
   - Test in dry-run mode first
   - Verify the script works with your configuration
   - Check that error handling works correctly

4. **Update documentation**:
   - Update README.md if you add features or change behavior
   - Update CHANGELOG.md with your changes
   - Add comments to code if needed

5. **Commit your changes**:
   ```bash
   git commit -m "Add: description of your change"
   ```
   Use clear, descriptive commit messages.

6. **Push and create a Pull Request**:
   - Push your branch to your fork
   - Create a PR with a clear description
   - Reference any related issues

## Code Style

- Use `set -euo pipefail` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Follow existing code structure and patterns
- Keep functions focused and small

## Testing

Before submitting:
- Test in dry-run mode
- Test with actual sync (on a test directory)
- Verify error messages are helpful
- Check that logging works correctly

## Questions?

Feel free to open an issue for any questions about contributing!

