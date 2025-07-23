import terminal

# Test available terminal colors
echo "Available foreground colors:"
echo "fgBlack, fgRed, fgGreen, fgYellow, fgBlue, fgMagenta, fgCyan, fgWhite"

echo "\nAvailable background colors:"
echo "bgBlack, bgRed, bgGreen, bgYellow, bgBlue, bgMagenta, bgCyan, bgWhite"

echo "\nTesting if extended colors exist..."

# Test bright colors (these might not exist)
when declared(fgBrightGreen):
  echo "fgBrightGreen exists!"
else:
  echo "fgBrightGreen does NOT exist"

when declared(fgLightGreen):
  echo "fgLightGreen exists!"
else:
  echo "fgLightGreen does NOT exist"

when declared(fgDarkGreen):
  echo "fgDarkGreen exists!"
else:
  echo "fgDarkGreen does NOT exist"

# Show actual color test
echo "\nColor demo:"
setForegroundColor(fgGreen)
echo "This is fgGreen"
setForegroundColor(fgCyan)
echo "This is fgCyan (blue-green)"
setForegroundColor(fgYellow)
echo "This is fgYellow"
resetAttributes()
echo "Back to normal"
