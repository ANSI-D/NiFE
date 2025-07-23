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
    statusMessage: ""
  )
  
  result.currentPanel = result.leftPanel.addr

  ## Process the user input. Return false if it quits
proc processInput*(fm: var FileManager): bool =
  let ch = getch()
  
  # Clear any previous status message
  fm.statusMessage = ""
  
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
  of '\x1b': # Escape sequence (arrow keys)
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
