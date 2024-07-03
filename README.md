# JumpTo

`jumpto` in order to improve the efficiency of switching between multiple machines.

jump to remote machine by ssh and sshpass, suitable for scenarios where multiple jump to different machines in a safe environment, password and details will save in `${HOME}/.config/jt/jt.csv`.

## Install

1. `wget https://raw.githubusercontent.com/ahaooahaz/JumpTo/main/jt.sh -O jt`
2. `chmod +x jt`
3. add `jt` into `${PATH}`

## Usage

### Register

`jt -r` or `jt --register` to register remote matchine information to `${HOME}/.config/jt/jt.csv`.

### Login

`jt ${ip}` to jump to remote machine, you can use part of the ip address.

### List

`jt -l` or `jt --list` to list all saved information.

## 2FA

2FA reqire to `pyotp`, use `pip install pyotp` to install.

### [MIT LICENSE](LICENSE)
