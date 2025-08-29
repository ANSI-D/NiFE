## NiFE - Nim File Explorer
## 
## A minimal terminal file manager inspired by Ranger FM
## Main application logic and entry point

import os
import terminal
import nife/types
import nife/file_utils
import nife/ui

## Initialize the file manager (with default settings, might create a config file later)
proc initFileManager*(): FileManager =
  
  let (termWidth, termHeight) = terminalSize()
  let currentDir = getCurrentDir()
  let panelWidth = termWidth div 2
  let panelHeight = termHeight - 1
  
  result = FileManager(
    leftPanel: initPanel(currentDir, panelWidth, panelHeight),
    rightPanel: initPanel(currentDir, panelWidth, panelHeight),
    terminalWidth: termWidth,
    terminalHeight: termHeight,
    statusMessage: "",
    operationMode: omNormal,
    sourceFile: "",
    searchQuery: ""
  )
  
  result.currentPanel = result.leftPanel.addr

  ## Process the user input. Return false if it quits
proc processInput*(fm: var FileManager): bool =
  let ch = getch()
  
  # Clear any previous status message
  fm.statusMessage = ""
  
  # Handle search input first (if in search mode)
  if fm.operationMode == omSearch:
    case ch:
    of '\x1b': # Escape - could be exit or arrow keys
      # For simplicity, just exit search mode on escape
      exitSearchMode(fm.currentPanel[])
      fm.operationMode = omNormal
      fm.searchQuery = ""
      fm.statusMessage = "Search cancelled"
      return true
    of '\b', '\x7f': # Backspace
      if fm.searchQuery.len > 0:
        fm.searchQuery = fm.searchQuery[0..^2]
        updateSearchResults(fm.currentPanel[], fm.searchQuery)
      return true
    of '\r', '\n': # Enter - open selected file/directory
      if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
        let selectedFile = fm.currentPanel.files[fm.currentPanel.selectedIndex]
        if selectedFile.fileType == ftDirectory:
          # Store the selected file path before exiting search mode
          let targetPath = selectedFile.path
          exitSearchMode(fm.currentPanel[])
          fm.operationMode = omNormal
          fm.searchQuery = ""
          # Manually navigate to the selected directory
          fm.currentPanel.path = targetPath
          fm.currentPanel.selectedIndex = 0
          fm.currentPanel.startIndex = 0
          updatePanel(fm.currentPanel[])
        else:
          openFile(selectedFile.path)
      return true
    of 'j':
      moveDown(fm.currentPanel[])
      return true
    of 'k':
      moveUp(fm.currentPanel[])
      return true
    of 'l': # Right arrow alternative - open file/directory
      if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
        let selectedFile = fm.currentPanel.files[fm.currentPanel.selectedIndex]
        if selectedFile.fileType == ftDirectory:
          # Store the selected file path before exiting search mode
          let targetPath = selectedFile.path
          exitSearchMode(fm.currentPanel[])
          fm.operationMode = omNormal
          fm.searchQuery = ""
          # Manually navigate to the selected directory
          fm.currentPanel.path = targetPath
          fm.currentPanel.selectedIndex = 0
          fm.currentPanel.startIndex = 0
          updatePanel(fm.currentPanel[])
        else:
          openFile(selectedFile.path)
      return true
    of 'h': # Left arrow alternative - go to parent
      exitSearchMode(fm.currentPanel[])
      fm.operationMode = omNormal
      fm.searchQuery = ""
      goToParent(fm.currentPanel[])
      return true
    else:
      # Add character to search query if it's printable
      if ch >= ' ' and ch <= '~':
        fm.searchQuery.add(ch)
        updateSearchResults(fm.currentPanel[], fm.searchQuery)
      return true
  
  # Normal mode input handling
  case ch:
  of 'q':
    return false
  of 'h':
    goToParent(fm.currentPanel[])
  of 'l':
    if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
      let file = fm.currentPanel.files[fm.currentPanel.selectedIndex]
      if file.fileType == ftDirectory:
        enterDirectory(fm.currentPanel[])
      else:
        openFile(file.path)
  of '\x1b': # Escape sequence (arrow keys) or cancel operation
    # First check if we're in an operation mode
    if fm.operationMode != omNormal:
      fm.operationMode = omNormal
      fm.sourceFile = ""
      fm.statusMessage = "Operation cancelled"
    else:
      # Handle arrow keys
      if getch() == '[':
        case getch():
        of 'A': # Up arrow
          moveUp(fm.currentPanel[])
        of 'B': # Down arrow
          moveDown(fm.currentPanel[])
        of 'C': # Right arrow
          if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
            let file = fm.currentPanel.files[fm.currentPanel.selectedIndex]
            if file.fileType == ftDirectory:
              enterDirectory(fm.currentPanel[])
            else:
              openFile(file.path)
        of 'D': # Left arrow
          goToParent(fm.currentPanel[])
        else:
          discard
  of 'j':
    moveDown(fm.currentPanel[])
  of 'k':
    moveUp(fm.currentPanel[])
  of 'g':
    moveToTop(fm.currentPanel[])
  of 'G':
    moveToBottom(fm.currentPanel[])
  of '\t': # Tab
    if fm.currentPanel == fm.leftPanel.addr:
      fm.currentPanel = fm.rightPanel.addr
    else:
      fm.currentPanel = fm.leftPanel.addr
  of 'R':
    updatePanel(fm.currentPanel[])
    fm.statusMessage = "Directory refreshed"
  of '?':
    showHelp()
  of ' ': # Space for preview
    if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
      let file = fm.currentPanel.files[fm.currentPanel.selectedIndex]
      if file.fileType == ftFile:
        showPreview(file.path, fm.terminalWidth, fm.terminalHeight)
  of 'c': # Copy file
    if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
      let file = fm.currentPanel.files[fm.currentPanel.selectedIndex]
      fm.operationMode = omCopy
      fm.sourceFile = file.path
      fm.statusMessage = "Copy mode: " & file.name & " (press 'v' to paste, ESC to cancel)"
  of 'x': # Cut/move file
    if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
      let file = fm.currentPanel.files[fm.currentPanel.selectedIndex]
      fm.operationMode = omMove
      fm.sourceFile = file.path
      fm.statusMessage = "Move mode: " & file.name & " (press 'v' to paste, ESC to cancel)"
  of 'v': # Paste file
    if fm.operationMode in [omCopy, omMove] and fm.sourceFile.len > 0:
      let fileName = extractFilename(fm.sourceFile)
      let destPath = fm.currentPanel.path / fileName
      
      if fileExists(destPath) or dirExists(destPath):
        if confirmAction("Destination exists. Overwrite?"):
          discard deleteFileOrDir(destPath)
        else:
          fm.operationMode = omNormal
          fm.sourceFile = ""
          fm.statusMessage = "Operation cancelled"
          return true
      
      var success = false
      if fm.operationMode == omCopy:
        success = copyFileOrDir(fm.sourceFile, destPath)
        if success:
          fm.statusMessage = "Copied: " & fileName
      else: # omMove
        success = moveFileOrDir(fm.sourceFile, destPath)
        if success:
          fm.statusMessage = "Moved: " & fileName
      
      if not success:
        fm.statusMessage = "Operation failed!"
      
      fm.operationMode = omNormal
      fm.sourceFile = ""
      updatePanel(fm.currentPanel[])
  of 'd': # Delete file
    if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
      let file = fm.currentPanel.files[fm.currentPanel.selectedIndex]
      if confirmAction("Delete " & file.name & "?"):
        if deleteFileOrDir(file.path):
          fm.statusMessage = "Deleted: " & file.name
          updatePanel(fm.currentPanel[])
        else:
          fm.statusMessage = "Delete failed!"
  of '/': # Search
    if fm.operationMode == omNormal:
      fm.operationMode = omSearch
      enterSearchMode(fm.currentPanel[])
      fm.searchQuery = ""
      fm.statusMessage = "Search mode: Type to search, ESC to exit"
  else:
    discard
  
  return true

  # Entry point

proc main() =
  hideCursor()
  defer: showCursor()
  
  var fm = initFileManager()
  
  while true:
    draw(fm)
    if not processInput(fm):
      break
  
  eraseScreen()
  setCursorPos(0, 0)
  echo "Exited NiFE"

when isMainModule:
  main()
