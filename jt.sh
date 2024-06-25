#!/bin/bash

#set -x

details=${HOME}/.config/jt/jt.csv
gauth_config=${HOME}/.config/gauth.csv

# custom marks
FA2_INPUT_AUTH_MARK="FA auth]:"
FA2_PASSED_AUTH_MARK=">"

function usage() {
cat << USAGE
usage: jt [OPTION] [PARAMS]

        [address]        jump to remote machine with ssh.
        -r|--register    register machine login information.   
        -l|--list        show address list.
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

function s() {
    ip=""
    user=""
    password=""
    port=""
    fa2_enable=0
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

    if [ ${fa2_enable} -ne 0 ]; then
        if [ -z ${fa2_tag} ]; then
            if [ $(type gauth >/dev/null 2>&1; echo $?) -ne 0 ]; then
                alert "2FA install gauth first"
                return
            fi
            echo -n "2FA tag: "
            if ! read -r fa2_tag; then
                echo ""
            fi
        else
            echo "2FA tag: ${fa2_tag}"
        fi

        if [ -z ${fa2_secret} ]; then
            if [ $(type gauth >/dev/null 2>&1; echo $?) -ne 0 ]; then
                alert "2FA install gauth first"
                return
            fi
            echo -n "2FA secret(ignore when 2FA tag already in gauth): "
            if ! read -r fa2_secret; then
                echo ""
            fi
        else
            echo "2FA secret: ${fa2_secret}"
        fi
    fi

    if [ ! -z "$(grep -E "^[^:]*{1}:${ip}:[^:]*{1}:[0-9]{1,5}{1}.*$" ${details} 2>/dev/null)" ]; then
        warn "ip already exist"
    fi
    
    if [ ${fa2_enable} -eq 0 ]; then
        if [ $(timeout 5s sshpass -p ${password} ssh ${user}@${ip} -p ${port} -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null 'exit' 2>/dev/null 1>&2; echo $?) -ne 0 ]; then
            alert "ssh check remote machine failed"
            return
        fi
    fi

    if [ ! -f ${details} ]; then
        mkdir -p $(dirname ${details})
    fi

    crypted=$(base64 <<< ${password})
    echo "${user}:${ip}:${crypted}:${port}:${fa2_tag}" >> ${details}
    if [ ${fa2_enable} -ne 0 ]; then
        if [ ! -z "${fa2_tag}" ]; then
            fa2 ${fa2_tag} ${fa2_secret}
        fi
    fi
    info "OK"
}

function e() {
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
            echo "${i}: ${matched_targets[i]}"
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

    read -r user ip crypted port fa2_tag <<< $(echo ${detail} | awk -F ':' '{print $1,$2,$3,$4,$5}' 2>/dev/null)
    info "match: ${user}@${ip}"
    sleep 0.5
    password=$(base64 -d <<< ${crypted})
    if [ -z "${fa2_tag}" ]; then
        timeout 5s sshpass -p ${password} ssh ${user}@${ip} -p ${port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
        err_code=$?
        if [ ${err_code} -ne 0 ]; then
            alert "${ip} login timeout"
            exit ${err_code}
        fi
        exit 0
    else
        fa2_auth=$(gauth 2>/dev/null | grep -E "^${fa2_tag} .*" 2>/dev/null | awk -F ' ' '{print $2}')
        if [ "${fa2_auth}" == "" ]; then
            warn "2FA secret not found, you need input manual"
        fi
        expect -c "
            log_user 0
            set timeout 60
            spawn ssh ${user}@${ip} -p ${port} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
            log_user 1
            expect {
                -re \".*(p|P)assword:\" {send \"${password}\r\";exp_continue}
                -re \".*${FA2_INPUT_AUTH_MARK}\" {send \"${fa2_auth}\r\"}
                -re \".*${FA2_PASSED_AUTH_MARK}\" {}
            }
            set timeout -1
            interact
        "
    exit 0
    fi
}

function l() {
    while read -r line
    do
        read -r user ip crypted port fa2_tag <<< $(echo ${line} | awk -F ':' '{print $1,$2,$3,$4,$5}' 2>/dev/null)
        info "${user}@${ip} ${fa2_tag}"
    done < ${details}
}

# $1: tag $2: secret
function fa2() {
    tag=$1
    secret=$2
    if [ -z $tag ]; then
        alert "2FA tag invalid"
        return
    fi

    if [ $(grep -E "^${tag}:.*" ${gauth_config} >/dev/null 2>&1; echo $?) -eq 0 ]; then
        return
    fi

    echo -en "\n$tag:$secret\n" >> ${gauth_config}
}

function main() {
    ARGS=$(getopt -o rlh -l help,list,register -- "$@")
    eval set -- "$ARGS"
    
    while true ; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -r|--register)
                shift
                s $@
                break
                ;;
            -l|--list)
                l
                shift
                break
                ;;
            *)
                shift
                e $1
                break
                ;;
        esac
    done

}

main $@
