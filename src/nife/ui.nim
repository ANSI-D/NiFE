## NiFE User Interface
## 
## This module contains all UI drawing and display functions.

import os
import strutils
import strformat
import terminal
import ./types
import ./file_utils

## Draw a file panel at the specified position

proc drawPanel*(panel: Panel, x, y: int, isActive: bool) =
  let borderColor = if isActive: fgGreen else: fgWhite
  
  # Draw border
  setCursorPos(x, y)
  setForegroundColor(borderColor)
  stdout.write("┌" & "─".repeat(panel.width - 2) & "┐")
  
  # Draw path header
  setCursorPos(x, y + 1)
  let pathDisplay = if panel.isSearchMode:
    "Search: " & panel.searchQuery
  elif panel.path.len > panel.width - 4:
    "..." & panel.path[^(panel.width - 7)..^0]
  else:
    panel.path
  stdout.write("│ " & pathDisplay & " ".repeat(panel.width - pathDisplay.len - 3) & "│")
  
  # Draw separator
  setCursorPos(x, y + 2)
  stdout.write("├" & "─".repeat(panel.width - 2) & "┤")
  
  # Draw files
  let visibleHeight = panel.height - 4
  for i in 0..<visibleHeight:
    let fileIndex = panel.startIndex + i
    setCursorPos(x, y + 3 + i)
    
    if fileIndex < panel.files.len:
      let file = panel.files[fileIndex]
      let isSelected = fileIndex == panel.selectedIndex and isActive
      
      # Set colors based on file type and selection
      if isSelected:
        setBackgroundColor(bgGreen)
        setForegroundColor(fgWhite)
      else:
        resetAttributes()
        case file.fileType:
        of ftDirectory:
          setForegroundColor(fgCyan)
        of ftExecutable:
          setForegroundColor(fgGreen)
        of ftSymlink:
          setForegroundColor(fgYellow)
        else:
          setForegroundColor(fgWhite)
      
      # Format file name and size
      let sizeStr = if file.fileType == ftDirectory: "<DIR>" else: formatFileSize(file.size)
      let maxNameLen = panel.width - sizeStr.len - 5
      let displayName = if file.name.len > maxNameLen:
        file.name[0..<maxNameLen-3] & "..."
      else:
        file.name
      
      let line = "│ " & displayName & " ".repeat(panel.width - displayName.len - sizeStr.len - 4) & sizeStr & "│"
      stdout.write(line)
      
      # Reset colors
      resetAttributes()
      setForegroundColor(borderColor)
    else:
      stdout.write("│" & " ".repeat(panel.width - 2) & "│")
  
  # Draw bottom border
  setCursorPos(x, y + panel.height - 1)
  setForegroundColor(borderColor)
  stdout.write("└" & "─".repeat(panel.width - 2) & "┘")
  resetAttributes()

## Draw the status bar at the bottom of the screen

proc drawStatusBar*(fm: FileManager) =
  setCursorPos(0, fm.terminalHeight - 1)
  setBackgroundColor(bgWhite)
  setForegroundColor(fgBlack)
  
  var statusText = ""
  if fm.currentPanel.selectedIndex < fm.currentPanel.files.len:
    let selectedFile = fm.currentPanel.files[fm.currentPanel.selectedIndex]
    statusText = fmt"File: {selectedFile.name} | Files: {fm.currentPanel.files.len}"
  else:
    statusText = fmt"Files: {fm.currentPanel.files.len}"
  
  # Show operation mode
  case fm.operationMode:
  of omCopy:
    statusText &= " | COPY MODE"
  of omMove:
    statusText &= " | MOVE MODE"
  of omDelete:
    statusText &= " | DELETE MODE"
  of omSearch:
    statusText &= " | SEARCH MODE - Type to search, ESC to exit"
  else:
    discard
  
  if fm.statusMessage.len > 0:
    statusText &= " | " & fm.statusMessage
  
  statusText &= " | Press ? for help"
  
  # Pad or truncate to terminal width
  if statusText.len > fm.terminalWidth:
    statusText = statusText[0..<fm.terminalWidth]
  else:
    statusText &= " ".repeat(fm.terminalWidth - statusText.len)
  
  stdout.write(statusText)
  resetAttributes()

## Draw the entire file manager interface

proc draw*(fm: var FileManager) =
  eraseScreen()
  
  let panelWidth = fm.terminalWidth div 2
  let panelHeight = fm.terminalHeight - 1  # Leave space for status bar
  
  # Update panel dimensions
  fm.leftPanel.width = panelWidth
  fm.leftPanel.height = panelHeight
  fm.rightPanel.width = panelWidth
  fm.rightPanel.height = panelHeight
  
  # Draw panels
  let isLeftActive = fm.currentPanel == fm.leftPanel.addr
  drawPanel(fm.leftPanel, 0, 0, isLeftActive)
  drawPanel(fm.rightPanel, panelWidth, 0, not isLeftActive)
  
  # Draw status bar
  drawStatusBar(fm)
  
  # Clear status message after displaying
  fm.statusMessage = ""

  ## Display help screen
proc showHelp*() =
  eraseScreen()
  setCursorPos(0, 0)
  echo HELP_TEXT
  echo "\nPress any key to continue..."
  discard getch()

## Show a preview of a text file
proc showPreview*(filePath: string, termWidth, termHeight: int) =
  eraseScreen()
  setCursorPos(0, 0)
  
  echo fmt"Preview: {filePath}"
  echo "─".repeat(termWidth)
  
  if not fileExists(filePath):
    echo "File does not exist"
    echo "\nPress any key to continue..."
    discard getch()
    return
  
  try:
    let content = readFile(filePath)
    let lines = content.splitLines()
    let maxLines = termHeight - 4
    
    for i, line in lines:
      if i >= maxLines:
        echo "... (file truncated)"
        break
      
      if line.len > termWidth:
        echo line[0..<termWidth-3] & "..."
      else:
        echo line
  except:
    echo "Cannot preview this file (binary or permission denied)"
  
  echo "\nPress any key to continue..."
  discard getch()
