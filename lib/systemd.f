#20220504
#build=0.0.2

function systemd.units.service {
    #accepts 0 args, returns systemd status as json.
    
    local lsystemd=`${cmd_systemctl} list-units --type=service --no-page --plain | ${cmd_head} -n -7 | ${cmd_tail} -n +2 | ${cmd_awk} '{print $1"|"$2"|"$3"|"$4"|"$5" "$6" "$7" "$8" "$9}' | ${cmd_jq} --raw-input -s 'split("\n") | map(split("|")) | .[0:-1] | map( { "unit": .[0],"load":.[1],"active":.[2],"sub":.[3],"description":.[4] } )'`
    echo ${lsystemd}
}
function systemd.units.service.isrunning {
    #accepts 1 arg, returns boolean true/false if service is running under systemd.

    local lservice_name=${1}                                                                        #service name to search for
                                                                                                    #get systemd services as json
    local lservice_json=`systemd.units.service | ${cmd_jq} '.[] | select(.unit == "'${lservice_name}'.service")' | ${cmd_jq} -s '.'`
    local lservice_json_length=`${cmd_echo} ${lservice_json} | ${cmd_jq} '. | length'`              #get array lengty, aka how many records
    local lservice_isrunning=${false}                                                               #set default value

    if [ ${lservice_json_length} -eq 1 ]; then
        case `${cmd_echo} ${lservice_json} | ${cmd_jq} -r '.[].sub'` in
            running)
                lservice_isrunning=${true}
            ;;
        esac
    fi

    ${cmd_echo} ${lservice_isrunning}
}
function systemd.units.state {
    #accepts 0 args, returns systemd state as json.

    local lsystemd=`${cmd_systemctl} list-unit-files --type=service --no-page --plain | ${cmd_head} -n -2 | ${cmd_tail} -n +2 | ${cmd_awk} '{print $1"|"$2}' | ${cmd_jq} --raw-input -s 'split("\n") | map(split("|")) | .[0:-1] | map( { "unit": .[0],"state":.[1] } )'`

    echo ${lsystemd}
}
function systemd.units.state.isenabled {
    #accepts 1 arg, returns boolean true/false if service is enabled under systemd.

    local lservice_name=${1}                                                                        #service name to search for
                                                                                                    #get systemd services as json
    local lservice_json=`systemd.units.state | ${cmd_jq} '.[] | select(.unit == "'${lservice_name}'.service")' | ${cmd_jq} -s '.'`
    local lservice_json_length=`${cmd_echo} ${lservice_json} | ${cmd_jq} '. | length'`              #get array lengty, aka how many records
    local lservice_isenabled=${false}                                                               #set default value

    if [ ${lservice_json_length} -eq 1 ]; then
        case `${cmd_echo} ${lservice_json} | ${cmd_jq} -r '.[].state'` in
            enabled)
                lservice_isenabled=${true}
            ;;
        esac
    fi

    ${cmd_echo} ${lservice_isenabled}
}