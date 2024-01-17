# jt

`jt` means `jumpto`, in order to improve the efficiency of switching between multiple machines.

jump to remote machine by ssh and sshpass, suitable for scenarios where multiple jump to different machines in a safe environment, password and details will save in `${HOME}/.config/jt/jt.csv`, make sure it will not leak.

## 2FA

If you want to login a machine that requires two-factor authentication, you need to install [gauth](https://github.com/pcarrier/gauth) first, then configure the verification information corresponding to the machine and set a special tag, finally, use the corresponding tag when saving jt.

### [MIT LICENSE](LICENSE)
