Set WshShell = CreateObject("WScript.Shell")

' Run the first command synchronously to make sure wsl was started before starting Docker
WshShell.Run "wsl.exe --exec ""true""", 0, True

' Sleep for 10s for WSL to properly wake up ready for connection
WScript.Sleep 10000

' Run the Docker command asynchronously
WshShell.Run """C:\Program Files\Docker\Docker\resources\com.docker.backend.exe"" wsl-update", 0, False