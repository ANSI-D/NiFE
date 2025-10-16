## NiFE File Utilities
## 
## This module contains file system operations and utilities.

import os
import strutils
import strformat
import algorithm
import terminal
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
      
      # Small optimization: walkDir's kind parameter instead of calling getFileType
      let fileType = case kind
        of pcFile, pcLinkToFile: 
          if fpUserExec in getFilePermissions(filePath):
            ftExecutable
          else:
            ftFile
        of pcDir, pcLinkToDir: ftDirectory
      
      var item = FileItem(
        name: fileName,
        path: filePath,
        fileType: fileType,
        isHidden: fileName.startsWith(".")
      )
      
      try:
        let info = getFileInfo(filePath, followSymlink = false)
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
    height: height,
    searchQuery: "",
    isSearchMode: false
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

proc filterFiles*(files: seq[FileItem], query: string): seq[FileItem] =
  ## Filter files based on search query (case-insensitive)
  result = @[]
  if query.len == 0:
    return files
  
  let lowerQuery = query.toLowerAscii()
  for file in files:
    if lowerQuery in file.name.toLowerAscii():
      result.add(file)

proc enterSearchMode*(panel: var Panel) =
  ## Enter search mode for the panel
  panel.isSearchMode = true
  panel.allFiles = panel.files  # Backup current files
  panel.searchQuery = ""
  panel.selectedIndex = 0
  panel.startIndex = 0

proc exitSearchMode*(panel: var Panel) =
  ## Exit search mode and restore all files
  panel.isSearchMode = false
  panel.files = panel.allFiles
  panel.searchQuery = ""
  panel.selectedIndex = 0
  panel.startIndex = 0

proc updateSearchResults*(panel: var Panel, query: string) =
  ## Update search results based on query
  panel.searchQuery = query
  if query.len == 0:
    panel.files = panel.allFiles
  else:
    panel.files = filterFiles(panel.allFiles, query)
  
  panel.selectedIndex = 0
  panel.startIndex = 0

## Navigate to the parent directory
proc goToParent*(panel: var Panel) =
  let parentPath = parentDir(panel.path)
  if parentPath != panel.path and dirExists(parentPath):
    panel.path = parentPath
    if panel.isSearchMode:
      exitSearchMode(panel)
    updatePanel(panel)
    
    
## Enter the selected directory
proc enterDirectory*(panel: var Panel) =
  if panel.selectedIndex < panel.files.len:
    let selectedFile = panel.files[panel.selectedIndex]
    if selectedFile.fileType == ftDirectory:
      panel.path = selectedFile.path
      panel.selectedIndex = 0
      panel.startIndex = 0
      updatePanel(panel)

## Move selection up in the file list
proc moveUp*(panel: var Panel) =
  if panel.selectedIndex > 0:
    panel.selectedIndex.dec
    if panel.selectedIndex < panel.startIndex:
      panel.startIndex = panel.selectedIndex

## Move selection down in the file list
proc moveDown*(panel: var Panel) =
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

## File Operations

proc deleteFileOrDir*(filePath: string): bool =
  ## Delete a file or directory
  ## Returns true on success, false on failure
  try:
    if dirExists(filePath):
      removeDir(filePath)
    else:
      removeFile(filePath)
    return true
  except:
    return false

proc copyFileOrDir*(srcPath, destPath: string): bool =
  ## Copy a file or directory from source to destination
  ## Returns true on success, false on failure
  try:
    if dirExists(srcPath):
      # For directories, we need to copy recursively
      copyDir(srcPath, destPath)
    else:
      # For files, simple copy
      copyFile(srcPath, destPath)
    return true
  except:
    return false

proc moveFileOrDir*(srcPath, destPath: string): bool =
  ## Move/rename a file or directory from source to destination
  ## Returns true on success, false on failure
  try:
    moveFile(srcPath, destPath)
    return true
  except:
    # If move fails, try copy then delete
    if copyFileOrDir(srcPath, destPath):
      return deleteFileOrDir(srcPath)
    return false

proc getUserInput*(prompt: string): string =
  ## Get user input with a prompt
  eraseScreen()
  setCursorPos(0, 0)
  stdout.write(prompt & ": ")
  stdout.flushFile()
  return readLine(stdin)

## Ask user for confirmation (y/n)
proc confirmAction*(message: string): bool =
  eraseScreen()
  setCursorPos(0, 0)
  stdout.write(message & " (y/n): ")
  stdout.flushFile()
  let response = getch()
  return response == 'y' or response == 'Y'
