use std assert
use std log

const CONFIG_PATH = ($nu.home-path | path join '.config' 'jt' 'jt.csv')

def alert [message: string] {
    print $"(ansi red)($message)(ansi reset)"
}

def warn [message: string] {
    print $"(ansi yellow)($message)(ansi reset)"
}

def info [message: string] {
    print $"(ansi green)($message)(ansi reset)"
}

export def --env main [
    --register (-r)  # Register new machine
    --list (-l)      # List all machines
    --delete (-d): int  # Delete machine by index
    address?: string  # Target machine address
] {
    if $register {
        register
    } else if $list {
        list
    } else if ($delete | is-not-empty) {
        delete-machine $delete
    } else if ($address | is-empty) {
        print-help
    } else {
        login $address
    }
}

def print-help [] {
    print (ansi green)
    print "Usage: jt [OPTION] [PARAMS]"
    print "Login different machines through IP or domain name and ssh"
    print ""
    print "Options:"
    print "  [address]        Jump to remote machine with ssh"
    print "  -r, --register   Register machine login information"
    print "  -l, --list       Show address list"
    print "  -d, --delete     Delete machine by index"
    print "  -h, --help       Show this help message"
    print (ansi reset)
}

def register [] {
    let ip = (input "Please input register ip: ")
    let user = (input "Please input register user: ")
    let password = (input "Please input register password: ")
    let port = (input "Please input register port: ")

    # Validate input
    if ($ip | is-empty) or ($user | is-empty) or ($password | is-empty) {
        alert "Invalid input: All fields except 2FA secret are required"
        return
    }

    # Encode password
    let crypted = ($password | encode base64)
    let line = $"($user),($ip),($crypted),($port)"

    # Append to config file
    let config_dir = ($CONFIG_PATH | path dirname)
    mkdir $config_dir
    $line | save $CONFIG_PATH --append

    info "Machine registered successfully!"
}

def list [] {
    if not ($CONFIG_PATH | path exists) {
        warn "No machines registered yet"
        return
    }

    let records = (open $CONFIG_PATH 
        | enumerate
        | each {|it| 
            {
                index: $it.index
                user: $it.item.user
                ip: $it.item.ip
                port: $it.item.port
            }
        }
    )

    $records | select index user ip port | table
}

def login [address: string] {
    if not ($CONFIG_PATH | path exists) {
        alert "No machines registered yet, use 'jt --register' first"
        return
    }

    let candidates = (open $CONFIG_PATH 
        | where ip =~ $address or user =~ $address
    )

    match ($candidates | length) {
        0 => { alert $"No machines found matching: ($address)" }
        1 => { connect ($candidates | first) }
        _ => {
            info "Multiple matches found:"
            let choices = ($candidates 
                | enumerate 
                | each {|it| 
                    {
                        index: $it.index
                        machine: $"($it.item.user)@($it.item.ip):($it.item.port)"
                    }
                }
            )
            let selected = (input "Select machine index: " | into int)
            connect ($candidates | get $selected)
        }
    }
}

def connect [record: record] {
    info $"Connecting to ($record.user)@($record.ip)..."
    
    let port = ($record.port? | default "22")
    ssh -o StrictHostKeyChecking=no -p $port $"($record.user)@($record.ip)"
}