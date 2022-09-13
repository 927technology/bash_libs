version=0.2.0

function systemd.report {
    #accepts 1 args, comma seperated,  no white space list of units, returns systemd status of units as json

    #declare local variables
    local ljson="{}"
    local lunit_json=""
    local lunits=${1}
    local lunits_success="${true}"
    
    for unit in `${cmd_echo} ${lunits} | ${cmd_sed} 's/,/\ /g'`; do  
        if [ "${unit}" == "device" ] || [ "${unit}" == "mount" ] || [ "${unit}" == "service" ] || [ "${unit}" == "socket" ] || [ "${unit}" == "target" ] || [ "${unit}" == "timer" ]; then
            
            #set default values
            lunit_json=""
                                                                                                    #get unit json
            lunit_json=`${cmd_osqueryi} 'select * from systemd_units where id like "%.'${unit}'"' --json`
                                                                                                    #add unit json to json
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.'${unit}'s |=.+ '"${lunit_json}"`
            
                                                                                                    #set the success bool for the unit
            if [ ${?} == ${exitok} ]; then
                                                                                                    #set success true for unit in json
                ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.'${unit}'s |=.+ {"success":"'${true}'"}'`
            else
                                                                                                    #set success to false for unit in json
                ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.'${unit}'s |=.+ {"success":"'${false}'"}'`
                lunits_success=${false}                                                             #set global success to false if one unit fails in json
            fi 
        else
                                                                                                    #set global success to false if unit name is not matched
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.'${unit}'s |=.+ {"success":"'${false}'"}'`
            lunits_success=${false}                                                                 #set global success to false if one unit fails in json

        fi
    done
    
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats |=.+ {"success":"'${lunits_success}'"}'`        #set global success in json

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