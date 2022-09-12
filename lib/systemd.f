#20220504
#build=0.0.2

function systemd.service.report {
    local ljson="{}"

    ljson=$(${cmd_echo} {\"services\":`${cmd_osqueryi} 'select * from systemd_units' --json | ${cmd_jq} -c`})
    lunits_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.services | length'`

    for i in `${cmd_seq} 1 ${lunits_count}`; do
        ii=$(( ${i} - 1 ))
        
        lid=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.services['${ii}'].id'`

        lname=`${cmd_echo} ${lid} | ${cmd_awk} -F"." '{print "\""$1"\""}'`
        lname=$(${cmd_echo} ${lname} | ${cmd_sed} 's/\\/\\\\/g')


        ltype=`${cmd_echo} ${lid} | ${cmd_awk} -F"." '{print "\""$2"\""}'`
        ltype=$(${cmd_echo} ${ltype} | ${cmd_sed} 's/\\/\\\\/g')


        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.services['${ii}'] |=.+ {"name":'${lname}'}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.services['${ii}'] |=.+ {"type":'${ltype}'}'`
    done

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}

function systemd.services.service {
    #accepts 0 args, returns systemd status as json.
    
    local lsystemd=`${cmd_systemctl} list-services --type=service --no-page --plain | ${cmd_head} -n -7 | ${cmd_tail} -n +2 | ${cmd_awk} '{print $1"|"$2"|"$3"|"$4"|"$5" "$6" "$7" "$8" "$9}' | ${cmd_jq} --raw-input -s 'split("\n") | map(split("|")) | .[0:-1] | map( { "unit": .[0],"load":.[1],"active":.[2],"sub":.[3],"description":.[4] } )'`
    echo ${lsystemd}
}
function systemd.services.service.isrunning {
    #accepts 1 arg, returns boolean true/false if service is running under systemd.

    local lservice_name=${1}                                                                        #service name to search for
                                                                                                    #get systemd services as json
    local lservice_json=`systemd.services.service | ${cmd_jq} '.[] | select(.unit == "'${lservice_name}'.service")' | ${cmd_jq} -s '.'`
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
function systemd.services.state {
    #accepts 0 args, returns systemd state as json.

    local lsystemd=`${cmd_systemctl} list-unit-files --type=service --no-page --plain | ${cmd_head} -n -2 | ${cmd_tail} -n +2 | ${cmd_awk} '{print $1"|"$2}' | ${cmd_jq} --raw-input -s 'split("\n") | map(split("|")) | .[0:-1] | map( { "unit": .[0],"state":.[1] } )'`

    echo ${lsystemd}
}
function systemd.services.state.isenabled {
    #accepts 1 arg, returns boolean true/false if service is enabled under systemd.

    local lservice_name=${1}                                                                        #service name to search for
                                                                                                    #get systemd services as json
    local lservice_json=`systemd.services.state | ${cmd_jq} '.[] | select(.unit == "'${lservice_name}'.service")' | ${cmd_jq} -s '.'`
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