@echo off
echo Starting Ollama Tunnel Service at %DATE% %TIME%
SET PATH=D:\Program Files\Git\bin;D:\Program Files\Git\usr\bin;%PATH%
"D:\Program Files\Git\bin\bash.exe" --login -i -c "bash '/d/workspaces/localQwen_ollama/ollama-server/scripts/windows/start_tunnel.sh'" > "D:\workspaces\localQwen_ollama\ollama-server\logs\tunnel.log" 2>&1
