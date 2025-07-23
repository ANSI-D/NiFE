# 🔪 NiFE - Nim File Explorer

A simple terminal file manager for Linux and MacOS inspired by Ranger FM, written in Nim.

## Features

- **Dual-pane interface** - Navigate with two panels like traditional file managers
- **Vim-like keybindings** - Familiar navigation for vim users
- **File type recognition** - Different colors for directories, executables, and symlinks
- **File preview** - Preview text files with the spacebar
- **Cross-platform** - Works on both Linux and MacOS
- **Lightweight** - Fast and responsive terminal interface

## Installation

### Prerequisites

- Nim
- Git

### Method 1: System-wide Installation (Recommended)

```bash
git clone <repository-url>
cd NiFE
nimble installGlobal
```

This will install `nife` to `/usr/local/bin/` and make it available system-wide.

### Method 2: User Installation

```bash
git clone <repository-url>
cd NiFE
nimble install
```

This installs to `~/.nimble/bin/`. You'll need to add `~/.nimble/bin` to your PATH.

### Method 3: Build Only

```bash
git clone <repository-url>
cd NiFE
nimble build
./nife  # Run from current directory
```

## Usage

After installation, run the file manager:

```bash
nife
```

Or if you built locally without installing:

```bash
./nife
```

## Keybindings

| Key | Action |
|-----|--------|
| `h`, `←` | Move to parent directory |
| `l`, `→` | Enter directory / Open file |
| `j`, `↓` | Move down |
| `k`, `↑` | Move up |
| `Tab` | Switch between panels |
| `g` | Go to top |
| `G` | Go to bottom |
| `R` | Refresh current directory |
| `Enter` | Open file with default application |
| `Space` | Preview file content |
| `?` | Show help |
| `q` | Quit |

## File Type Colors

- **Blue** - Directories
- **Green** - Executable files
- **Magenta** - Symbolic links
- **White** - Regular files

## Window Example

```
┌─────────────────────────────────────┐┌─────────────────────────────────────┐
│ /home/user/documents                ││ /home/user/documents/projects       │
├─────────────────────────────────────┤├─────────────────────────────────────┤
│ projects/                    <DIR>  ││ nife/                        <DIR>  │
│ notes.txt                      2K   ││ config.nim                     1K   │
│ backup/                      <DIR>  ││ main.nim                       5K   │
│ readme.md                      4K   ││ utils.nim                      3K   │
└─────────────────────────────────────┘└─────────────────────────────────────┘
File: projects | Files: 4 | Press ? for help
```

## Architecture

The file manager consists of several key components:

- **FileItem**: Represents individual files and directories with metadata
- **Panel**: Manages file listings and navigation state for each pane
- **FileManager**: Main application state and UI coordination
- **Drawing System**: Terminal-based UI rendering with borders and colors
- **Input Handler**: Keyboard input processing and command execution



## Roadmap

- [ ] File operations (copy, move, delete)
- [ ] Search functionality
- [ ] Better file preview (images, binary files)
- [ ] Multiple tabs
- [ ] File permissions editing

## Dependencies

- `terminal` (built-in) - For terminal control and input handling
- Standard library modules: `os`, `strutils`, `strformat`, `tables`, `sequtils`, `algorithm`

## Troubleshooting

### Terminal Issues

If you experience display issues, ensure your terminal supports:
- ANSI color codes
- Cursor positioning
- UTF-8 box drawing characters

### File Access

The file manager respects system permissions. If you cannot access certain directories, check your user permissions.

### Performance

For directories with thousands of files, initial loading may take a moment. Use `R` to refresh if needed.
