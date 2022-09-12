#variables
plugin_version=0.0.1

#functions
function plugin_intel {

    #declare local variables
    local ljson="{}"
    local lservices_json=""
    local lservices=$(${cmd_echo} ${services} | ${cmd_sed} 's/,/\|/g')
    
    #main
    lservices_json=`systemd.report service | ${cmd_jq} '.services[] | select(.id | test("'${lservices}'"))' | ${cmd_jq} -s`

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.services |=.+ {"'${lservices_json}'"}'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}

function plugin_logging {

    #declare local variables
    local ljson=${1}

    #main
    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}
function plugin_output {

    #decalare local variables
    local ljson=${1}
    local lservice_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.services | length'`                    #get array length
    local lenabled=""
    local lenabled_output=""
    local lenabled_success=""
    local lstatus=""
    local lstatus_success=""
    local lname=""

    #main
    [ ${dry_run} -eq ${true} ] && dry_run_marker=*

                                                                                                    #output service header
    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		"${dry_run_marker}"																			\
		"Service"																				    \
		""																					        \
		"Running"																				    \
		"Enabled"
        
                                                                                                    #loop services data
    for i in `${cmd_seq} 0 ${lservice_count}`; do
        ii=$(( ${i} - 1 ))

        name=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.services['${ii}'].name'`                  #get the service name

                                                                                                    #get required values
        #enable service
        lenabled=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.['${i}'].enabled'`
        lenable_success=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.['${i}'].enabling'`

        [ ${lenable_success} -eq ${true} ] && lenable_success_marker="+" || lenable_success_marker="-"

        #start service
     
        lstatus=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.['${i}'].started'`
        lstatus_success=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.['${i}'].starting'`


        [ ${lstatus_success} -eq ${true} ] && lstatus_success_marker="+" || lstatus_success_marker="-"

                                                                                                    #output services table
        ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"	                                                \
            "$(( ${ii}  ))"                                                                         \
            "${lname}"                                                                              \
            ""                                                                                      \
            "${lstatus}${lstatus_success_marker}"                                                   \
            "${lenabled}${lenable_success_marker}"
    done

                                                                                                    #get counters from stats in json
    lenabled_success_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.enabled.success'`
    lenabled_failure_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.enabled.failed'`
    lstatus_success_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.status.success'`
    lstatus_failure_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.status.failed'`

    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		""																			                \
		"Totals"																				    \
		""																					        \
		"Success"																				    \
		"Failed"

    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		""																			                \
		"Services Enabled"																	        \
		""																					        \
		"${lenabled_success_count}"																    \
		"${lenabled_failure_count}"
    
    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"                                                     \   
		""																			                \
		"Services Started"																	        \
		""																					        \
		"${lstatus_success_count}"																    \
		"${lstatus_failure_count}"
}

function plugin_remediate {

    #decalare local variables
    local ljson=${1}
    local lservice_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.services | length'`                       #get array length
    local lenabled=${false}
    local lenabled_success_count=0
    local lenabled_failure_count=0
    local lenabled_output=""
    local lenabled_success=${false}
    local lstatus=""
    local lstatus_success=""
    local lstatus_success_count=0
    local lstatus_failure_count=0
    local lname=""

    #main
    for i in `${cmd_seq} 1 ${lservice_count}`; do 

        #set variable defaults
        local lenabled=${false}
        local lenabled_output=""
        local lenabled_success=${false}
        local lstatus=""
        local lname=""

        ii= $(( ${i} - 1 ))                                                                         #array indexes alway run one less than integer length

        lname=`${cmd_echo} ${ljson} | ${cmd_jq} '.services['${ii}'].id'`                            #get service name from json
        lenabled_output=`${cmd_systemctl} is-enabled ${id}`                                         #get enabled from json
        lstatus_output=`${cmd_echo} ${ljson} | ${cmd_jq} '.services['${ii}'].active_state'`         #get status from json

                                                                                                    #set bool value for enable
        case "${lenabled_output}" in
            "enabled")  lenabled=${true}    ;;
            "disabled") lenabled=${false}   ;;
            *)          lenabled=${true}    ;;                                                      #fail true to avoid err messages
        esac

                                                                                                    #set bool value for status
        case "${lstatus_output}" in
            "active")  lstatus=${true}      ;;
            *)         lstatus=${false}     ;;
        esac

                                                                                                    #add service name to stats output in json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"name":"'${lname}'"}'`

        #enable service
                                                                                                    #enable service is disabled
        if [ ${lenabled} -eq ${false} ]; then
            [ ${dry_run} -eq ${true} ] ${cmd_systemctl} enable ${lname}
                                                                                                    #did we success enabling the service
            if [ ${?} -eq ${exitok} ] && [ ${dry_run} -eq ${false} ]; then
                lenabled_success=${true}                                                            #set success bit
                $(( ${lenabled_success_count}++ ))                                                  #increment successes
            else    
                lenabled_success=${false}                                                           #set failure bit
                $(( ${lenabled_failure_count}++ ))                                                  #increment failures
            fi
        else
            lenabled_success=${true}                                                                #set success bit for services already enabled
            $(( ${lenabled_success_count}++ ))                                                      #increment successes
        fi

                                                                                                    #output stats to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"enabled":"'${lenabled}'"}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"enabling":"'${lenabled_success}'"}'`     

        #start service
        if [ ${lstatus} -eq ${false} ]; then
            [ ${dry_run} -eq ${true} ] ${cmd_systemctl} start ${lname}
                                                                                                    #did we success starting the service
            if [ ${?} -eq ${exitok} ] && [ ${dry_run} -eq ${false} ]; then
                lstatus_success=${true}                                                            #set success bit
                $(( ${lstatus_success_count}++ ))                                                  #increment successes
            else    
                lstatus_success=${false}                                                           #set failure bit
                $(( ${lstatus_failure_count}++ ))                                                  #increment failures
            fi
        else
            lstatus_success=${true}                                                                #set success bit for services already enabled
            $(( ${lstatus_success_count}++ ))                                                      #increment successes
        fi

                                                                                                    #output stats to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"started":"'${lstatus}'"}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"starting":"'${lstatus_success}'"}'`     
    done

                                                                                                    #output stats to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.enabled |=.+ {"success":"'${lenabled_success_count}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.enabled |=.+ {"failed":"'${lenabled_failure_count}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.status |=.+ {"success":"'${lstatus_success_count}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.status |=.+ {"failed":"'${lstatus_failure_count}'"}'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c      
}