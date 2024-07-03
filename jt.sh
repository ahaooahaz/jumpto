#!/bin/bash

set -e

details=${HOME}/.config/jt/jt.csv

# custom marks
FA2_IN_AUTH_MARK=".*FA auth]:"
FA2_PASS_MARK=".*>"
FA2_IN_PASS_MARK=".*(p|P)assword:"

function usage() {
cat << USAGE
usage: jt [OPTION] [PARAMS]

        [address]        jump to remote machine with ssh.
        -r|--register    register machine login information.
        -l|--list        show address list.
        -d|--delete      delete machine login information by index which from list.

        -h|--help        show help.
USAGE
}

function alert() {
    echo -e "\033[31m$1\033[0m"
}

function warn() {
    echo -e "\033[33m$1\033[0m"
}

function info() {
    echo -e "\033[32m$1\033[0m"
}

function register() {
    ip=""
    user=""
    password=""
    port=""
    fa2_secret=0
    fa2_in_password_mark_e=""
    fa2_in_auth_mark_e=""
    fa2_pass_mark_e=""
    echo -n "please input register ip: "  
    if ! read -r ip ; then
        echo ""
    fi
    echo -n "please input register user: "
    if ! read -r user ; then
        echo ""
    fi
    echo -n "please input register password: "
    if ! read -r password ; then
        echo ""
    fi
    echo -n "please input register sshd service port: "
    if ! read -r port ; then
        echo ""
    fi
    echo -n "please input register 2fa secret, empty for no 2fa: "
    if ! read -r fa2_secret ; then
        echo ""
    fi


    if [ ! -z ${fa2_secret} ]; then
        if [ $(pip show pyotp > /dev/null 2>&1; echo $?) -ne 0 ]; then
            alert "2fa require pyotp, use: pip install pyotp"
            return
        fi

        echo -n "please input 2fa input password mark(default: '${FA2_IN_PASS_MARK}'): "
        if ! read -r fa2_in_password_mark ; then
            echo ""
        fi
        if [ -z ${fa2_in_password_mark} ]; then
            fa2_in_password_mark=${FA2_IN_PASS_MARK}
        fi
        fa2_in_password_mark_e=$(base64 <<< ${fa2_in_password_mark})

        echo -n "please input 2fa input verification code mark(default: '${FA2_IN_AUTH_MARK}'): "
        if ! read -r fa2_in_auth_mark ; then
            echo ""
        fi
        if [ -z ${fa2_in_auth_mark} ]; then
            fa2_in_auth_mark=${FA2_IN_AUTH_MARK}
        fi
        fa2_in_auth_mark_e=$(base64 <<< ${fa2_in_auth_mark})

        echo -n "please input 2fa pass mark(default: '${FA2_PASS_MARK}'): "
        if ! read -r fa2_pass_mark ; then
            echo ""
        fi
        if [ -z ${fa2_pass_mark} ]; then
            fa2_pass_mark=${FA2_PASS_MARK}
        fi
        fa2_pass_mark_e=$(base64 <<< ${fa2_pass_mark})
    else
        if [ $(timeout 5s sshpass -p ${password} ssh ${user}@${ip} -p ${port} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'exit' 2>/dev/null 1>&2; echo $?) -ne 0 ]; then
            alert "ssh check remote machine failed"
            return
        fi
    fi

    if [ ! -f ${details} ]; then
        mkdir -p $(dirname ${details})
    fi

    crypted=$(base64 <<< ${password})
    echo "${user}:${ip}:${crypted}:${port}:${fa2_secret}:${fa2_in_password_mark_e}:${fa2_in_auth_mark_e}:${fa2_pass_mark_e}" >> ${details}
    info "OK!"
}

function login() {
    if [ -z "$1" ]; then
        alert "input remote machine address or part of address"
        usage
        return
    fi
    
    if [ ! -f "${details}" ]; then
        alert "save remote machine details first, use 'jt s'"
        usage
        return
    fi
    while read -r target; do
        matched_targets+=("${target}")
    done < <(grep -E "^[^:]*{1}:[^:]*${1}.*{1}:[^:]*{1}:[0-9]{1,5}{1}.*$" ${details} 2>/dev/null)
    #declare -p matched_targets

    if [ ${#matched_targets[@]} -eq 0 ]; then
        warn "${1} not match"
        return
    elif [ ${#matched_targets[@]} -eq 1 ]; then
        detail=${matched_targets[0]}
    else
        for ((i=0;i<${#matched_targets[@]};i++)); do
            read -r tuser tip tcrypted _ tfa2_secret <<< $(echo ${matched_targets[i]} | awk -F ':' '{print $1,$2,$3,$4,$5}' 2>/dev/null)
            password=$(base64 -d <<< ${tcrypted} 2>/dev/null)
            info "* ${i}: ${tuser}@${tip}(${password}) 2FA: ${tfa2_secret}"
        done
        echo -ne "\033[32mmatch multi targets, please input address index: \033[0m"
        if ! read -r chosen; then
            echo ""
        fi
        if [[ "$chosen" =~ ^[0-9]+$ ]] && [ "$chosen" -lt "${#matched_targets[@]}" ]; then
            detail=${matched_targets[chosen]}
        else
            warn "invalid index, defaulting to 0"
            detail=${matched_targets[0]}
        fi
    fi

    read -r user ip crypted port fa2_secret fa2_in_password_mark_e fa2_in_auth_mark_e fa2_pass_mark_e <<< $(echo ${detail} | awk -F ':' '{print $1,$2,$3,$4,$5,$6,$7,$8}' 2>/dev/null)
    info "match: ${user}@${ip}"
    sleep 0.5
    password=$(base64 -d <<< ${crypted})
    if [ -z "${fa2_secret}" ]; then
        sshpass -p ${password} ssh ${user}@${ip} -p ${port} -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
        err_code=$?
        if [ ${err_code} -ne 0 ]; then
            alert "${ip} login timeout"
            exit ${err_code}
        fi
        exit 0
    else
        fa2_auth=$(fa2 ${fa2_secret})
        if [ "${fa2_auth}" == "" ]; then
            warn "2FA secret not found, you need input manual"
        fi
        expect -c "
            log_user 0
            set timeout 60
            spawn ssh ${user}@${ip} -p ${port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
            log_user 1
            expect {
                -re \"$(base64 -d <<< ${fa2_in_password_mark_e})\" {send \"${password}\r\";exp_continue}
                -re \"$(base64 -d <<< ${fa2_in_auth_mark_e})\" {send \"${fa2_auth}\r\"}
                -re \"$(base64 -d <<< ${fa2_pass_mark_e})\" {}
            }
            set timeout -1
            interact
        "
    exit 0
    fi
}

function list() {
    index=0
    while read -r line
    do
        read -r user ip crypted port fa2_secret <<< $(echo ${line} | awk -F ':' '{print $1,$2,$3,$4,$5}' 2>/dev/null)
        info "* ${index}: ${user}@${ip} ${fa2_secret}"
        ((index+=1))
    done < ${details}
}

# $1: tag $2: secret
function fa2() {
    secret=$1

    echo -en $(python3 - <<EOF
import pyotp
my_var = "$secret"
print(pyotp.TOTP(my_var).now())
EOF
    )
}

function delete() {
    index=$(($1 + 1))
    sed -i "${index}d" ${details}
}

function main() {
    ARGS=$(getopt -o rlhd: -l help,list,register,delete: -- "$@")
    eval set -- "$ARGS"
    
    while true ; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -r|--register)
                shift
                register $@
                break
                ;;
            -l|--list)
                list
                shift
                break
                ;;
            -d|--delete)
                shift
                delete $@
                break
                ;;
            *)
                shift
                login $1
                break
                ;;
        esac
    done
}

main $@
