## NiFE Types and Constants
## 
## This module contains all type definitions and constants used throughout NiFE.

type
  FileType* = enum
    ftDirectory, ftFile, ftSymlink, ftExecutable
  
  OperationMode* = enum
    omNormal, omCopy, omMove, omDelete
  
  FileItem* = object
    name*: string
    path*: string
    fileType*: FileType
    size*: int64
    permissions*: string
    isHidden*: bool

  Panel* = object
    path*: string
    files*: seq[FileItem]
    selectedIndex*: int
    startIndex*: int
    width*: int
    height*: int

  FileManager* = object
    leftPanel*: Panel
    rightPanel*: Panel
    currentPanel*: ptr Panel
    terminalWidth*: int
    terminalHeight*: int
    statusMessage*: string
    operationMode*: OperationMode
    sourceFile*: string  # For copy/move operations

const
  VERSION* = "0.1.0"
  HELP_TEXT* = """
NiFE - Nim File Explorer v""" & VERSION & """

Keybindings:
  h, Left Arrow   - Move to parent directory
  l, Right Arrow  - Enter directory / Open file
  j, Down Arrow   - Move down
  k, Up Arrow     - Move up
  Tab             - Switch between panels
  g               - Go to top
  G               - Go to bottom
  R               - Refresh current directory
  q               - Quit
  ?               - Show this help
  Enter           - Open file with default application
  Space           - Preview file content

File Operations:
  c               - Copy file/directory
  x               - Cut (move) file/directory
  v               - Paste file/directory
  d               - Delete file/directory
  Escape          - Cancel operation
"""
