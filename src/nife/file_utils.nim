## NiFE File Utilities
## 
## This module contains file system operations and utilities.

import os
import strutils
import strformat
import algorithm
import ./types

proc getFileType*(path: string): FileType =
  ## Determine the type of a file or directory
  if dirExists(path):
    return ftDirectory
  elif symlinkExists(path):
    return ftSymlink
  elif fpUserExec in getFilePermissions(path):
    return ftExecutable
  else:
    return ftFile

proc formatFileSize*(size: int64): string =
  ## Format file size in human-readable format
  if size < 1024:
    return $size & "B"
  elif size < 1024 * 1024:
    return fmt"{size div 1024}K"
  elif size < 1024 * 1024 * 1024:
    return fmt"{size div (1024 * 1024)}M"
  else:
    return fmt"{size div (1024 * 1024 * 1024)}G"

proc getFileItems*(path: string): seq[FileItem] =
  ## Get all files and directories in the given path
  result = @[]
  
  if not dirExists(path):
    return result
  
  try:
    for kind, filePath in walkDir(path):
      let fileName = extractFilename(filePath)
      if fileName == "." or fileName == "..":
        continue
        
      var item = FileItem(
        name: fileName,
        path: filePath,
        fileType: getFileType(filePath),
        isHidden: fileName.startsWith(".")
      )
      
      try:
        let info = getFileInfo(filePath)
        item.size = info.size
      except:
        item.size = 0
      
      result.add(item)
  except:
    discard
  
  # Sort: directories first, then files, alphabetically
  result.sort do (a, b: FileItem) -> int:
    if a.fileType == ftDirectory and b.fileType != ftDirectory:
      return -1
    elif a.fileType != ftDirectory and b.fileType == ftDirectory:
      return 1
    else:
      return cmp(a.name.toLowerAscii(), b.name.toLowerAscii())

proc updatePanel*(panel: var Panel) =
  ## Update panel contents by rescanning the directory
  panel.files = getFileItems(panel.path)
  if panel.selectedIndex >= panel.files.len:
    panel.selectedIndex = max(0, panel.files.len - 1)

proc initPanel*(path: string, width, height: int): Panel =
  ## Initialize a new panel with the given path and dimensions
  result = Panel(
    path: path,
    selectedIndex: 0,
    startIndex: 0,
    width: width,
    height: height
  )
  updatePanel(result)

proc openFile*(filePath: string) =
  ## Open a file with the system's default application
  when defined(linux):
    discard execShellCmd("xdg-open " & quoteShell(filePath) & " >/dev/null 2>&1 &")
  elif defined(macosx):
    discard execShellCmd("open " & quoteShell(filePath))
  else:
    echo "File opening not supported on this platform"

proc goToParent*(panel: var Panel) =
  ## Navigate to the parent directory
  let parentPath = parentDir(panel.path)
  if parentPath != panel.path and dirExists(parentPath):
    panel.path = parentPath
    updatePanel(panel)

proc enterDirectory*(panel: var Panel) =
  ## Enter the selected directory
  if panel.selectedIndex < panel.files.len:
    let selectedFile = panel.files[panel.selectedIndex]
    if selectedFile.fileType == ftDirectory:
      panel.path = selectedFile.path
      panel.selectedIndex = 0
      panel.startIndex = 0
      updatePanel(panel)

proc moveUp*(panel: var Panel) =
  ## Move selection up in the file list
  if panel.selectedIndex > 0:
    panel.selectedIndex.dec
    if panel.selectedIndex < panel.startIndex:
      panel.startIndex = panel.selectedIndex

proc moveDown*(panel: var Panel) =
  ## Move selection down in the file list
  if panel.selectedIndex < panel.files.len - 1:
    panel.selectedIndex.inc
    let visibleHeight = panel.height - 4
    if panel.selectedIndex >= panel.startIndex + visibleHeight:
      panel.startIndex = panel.selectedIndex - visibleHeight + 1

proc moveToTop*(panel: var Panel) =
  ## Move selection to the top of the file list
  panel.selectedIndex = 0
  panel.startIndex = 0

proc moveToBottom*(panel: var Panel) =
  ## Move selection to the bottom of the file list
  if panel.files.len > 0:
    panel.selectedIndex = panel.files.len - 1
    let visibleHeight = panel.height - 4
    if panel.files.len > visibleHeight:
      panel.startIndex = panel.files.len - visibleHeight
    else:
      panel.startIndex = 0
