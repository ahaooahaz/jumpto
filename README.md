# JumpTo

`jumpto` in order to improve the efficiency of switching between multiple machines.

jump to remote machine by ssh and sshpass, suitable for scenarios where multiple jump to different machines in a safe environment, password and details will save in `${HOME}/.config/jt/jt.csv`.

## Install

For Linux (example):

```
# Set your platform variables (adjust as needed)
VERSION=v0.1.0
PLATFORM=linux-amd64

# Download plain binary
wget https://github.com/ahaooahaz/jumpto/releases/download/${VERSION}/yq-${PLATFORM} -O jt &&\
    chmod +x jt
```

Latest version (Linux AMD64):

```
wget https://github.com/ahaooahaz/jumpto/releases/latest/download/jt-linux-amd64 -O jt &&\
    chmod +x jt
```

## Usage

![example](/example.gif)

### [MIT LICENSE](LICENSE)
