# Package

version       = "0.1.5"
author        = "ANSI-D"
description   = "Minimal terminal file manager inspired by Ranger FM"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nife"]
binDir        = "bin"
installExt    = @["nim"]

# Dependencies

requires "nim >= 1.6.0"

# Make nimble install put binary in system-wide location
after install:
  exec "sudo cp ~/.nimble/bin/nife /usr/local/bin/"
  echo "NiFE installed to /usr/local/bin/nife (system-wide)"

before uninstall:
  exec "sudo rm -f /usr/local/bin/nife"
  echo "NiFE uninstalled from /usr/local/bin"

task installGlobal, "Install NiFE system-wide":
  exec "nimble build"
  exec "sudo install -m 755 bin/nife /usr/local/bin/"
  echo "NiFE installed to /usr/local/bin/nife"

task uninstallGlobal, "Uninstall NiFE from system":
  exec "sudo rm -f /usr/local/bin/nife"
  echo "NiFE uninstalled from /usr/local/bin"
