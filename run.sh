#!/bin/bash
# wt.exe -p "Ubuntu 22.04.3 LTS" wsl --help "cd dev" ";" new-tab -p "Ubuntu 22.04.3 LTS" ";" new-tab -p "Ubuntu 22.04.3 LTS"
if ! pgrep -x "sgpiom" > /dev/null
then
    make runSGPIOM &
fi
make runQEMU