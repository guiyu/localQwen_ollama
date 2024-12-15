@echo off
SET PATH=D:\Program Files\Git\bin;D:\Program Files\Git\usr\bin;%PATH%
"D:\Program Files\Git\bin\bash.exe" --login -i -c "bash '/d/workspaces/localQwen_ollama/ollama-server/scripts/windows/start_tunnel.sh'"
