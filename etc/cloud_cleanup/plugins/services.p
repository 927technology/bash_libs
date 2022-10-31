#variables
plugin_version=0.0.1

#functions
function plugin_intel {

    #declare local variables
    local ljson="{}"
    local lservices_json=""
    local lservices=$(${cmd_echo} ${services} | ${cmd_sed} 's/,/\|/g')
    
    #main
    lservices_json=`systemd.report service | ${cmd_jq} '.services[] | select(.id | test("'${lservices}'"))' | ${cmd_jq} -sc`

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '. |=.+ {"data":'"${lservices_json}"'}'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}

function plugin_logging {

    #declare local variables
    local ljson=${1}
    local lmessage_json="{}"
    local lrunlog_json="{}"
    local lservice_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.services| length'`             #get array length

    #main
    if ( [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ] ) || [ ! -z ${filelog} ]; then
                                                                                                #run log info
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"build":"'${build}'"}'`
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"date":"'${now}'"}'`
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"dry_run":"'${dry_run}'"}'`
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"tag":"'${syslog_tag}'"}'`
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"enabled":"'${syslog}'"}'`
        lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"filelog":"'${filelog}'"}'`
    fi

    if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then

        ${cmd_logger} --tag ${syslog_tag} ${lrunlog_json}										#off to syslog facility

                                                                                               #did it successfull log
        [ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}
    fi 

    if [ ! -z ${filelog} ]; then

        [ ! -d ${filelog} ] && ${cmd_mkdir} ${filelog}											#if it aint there, make it!
        ${cmd_echo} ${lrunlog_json} >> ${filelog}/${plugin}										#log it

                                                                                                #did it successfully log
        [ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}
    fi

    for i in `${cmd_seq} 1 ${lservice_count}`; do
        ii=$(( ${i} - 1 ))

        lname=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.stats.services['${ii}'].name'`               #get the service name

                                                                                                    #get required values
        #get services json
        services_json=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}']'`

        if ( [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ] ) || [ ! -z ${filelog} ]; then
																									#event log info
            lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
            lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.services |=.+ '"${services_json}"`  
        fi

        if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then
            ${cmd_logger} --tag ${syslog_tag} ${lmessage_json}
            
                                                                                                #did the message send
            [ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}

                                                                                                #update json to show log was sent
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'].syslog |=.+ {"syslog":"'${lfile_syslog}'"}'`
        fi 

                                                                                               #send logs to file log
        if [ ! -z ${filelog} ]; then
            ${cmd_echo} ${lmessage_json} >> ${filelog}/${plugin}									#log it

                                                                                                #did the message send?
            [ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}

                                                                                                #update json to show log was sent
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'].syslog |=.+ {"filelog":"'${lfile_filelog}'"}'`
        fi
    done
    
    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}
function plugin_output {

    #decalare local variables
    local ljson=${1}
    local lservice_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.services | length'`                    #get array length
    local lenabled=""
    local lenabled_output=""
    local lenabled_success=""
    local lstatus=""
    local lstatus_success=""
    local lname=""

    #main
    [ ${dry_run} -eq ${true} ] && dry_run_marker=*


    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		""																			                \
		"(+) Status Changed"																        \
		""																					        \
		""																				            \
		""
                                                                                                    #output service header
    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		"${dry_run_marker}"																			\
		"Service"																				    \
		""																					        \
		"Running"																				    \
		"Enabled"
       
                                                                                                    #loop services data
    for i in `${cmd_seq} 1 ${lservice_count}`; do
        ii=$(( ${i} - 1 ))

        lname=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.stats.services['${ii}'].name'`               #get the service name

                                                                                                    #get required values
        #enable service
        lenabled=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.stats.services['${ii}'].enabled'`
        lenable_success=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.stats.services['${ii}'].enabling'`

        [ ${lenable_success} -eq ${true} ] && lenable_success_marker="+" || lenable_success_marker=""

        #start service    
        lstatus=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.stats.services['${ii}'].started'`
        lstatus_success=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.stats.services['${ii}'].starting'`


        [ ${lstatus_success} -eq ${true} ] && lstatus_success_marker="+" || lstatus_success_marker=""

                                                                                                    #output services table
        ${cmd_printf} "%-2s %-50s %-7s %7s %10s\n"	                                                \
            "${i}"                                                                                  \
            "${lname}"                                                                              \
            ""                                                                                      \
            "${lstatus}${lstatus_success_marker}"                                                   \
            "${lenabled}${lenable_success_marker}"
    done

                                                                                                    #get counters from stats in json
    lenabled_success_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.enable.success'`
    lenabled_failure_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.enable.failed'`
    lstatus_success_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.status.success'`
    lstatus_failure_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.status.failed'`

    ${cmd_echo}

    ${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		""																			                \
		"Totals"																				    \
		""																					        \
		"Success"																				    \
		"Failed"

    ${cmd_printf} "%-2s %-50s %-7s %7s %10s\n"														\
		""																			                \
		"Services Enabled"																	        \
		""																					        \
		"${lenabled_success_count}"																    \
		"${lenabled_failure_count}"
    
    ${cmd_printf} "%-2s %-50s %-7s %7s %10s\n"														\
		""																			                \
		"Services Started"																	        \
		""																					        \
		"${lstatus_success_count}"																    \
		"${lstatus_failure_count}"
}

function plugin_remediate {

    #decalare local variables
    local lenabled=${false}
    local lenabled_failure_count=0
    local lenabled_output=""
    local lenabled_success=${false}
    local lenabled_success_count=0
    
    local ljson=${1}

    local lname=""
    local lname_short=""

    local lservices_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data | length'`                 #get array length

    local lstatus=${false}
    local lstatus_failure_count=0
    local lstatus_output=""
    local lstatus_success="${false}"
    local lstatus_success_count=0

    #main
    for i in `${cmd_seq} 1 ${lservices_count}`; do 

        #set variable defaults
        lenabled=${false}
        lenabled_failure_count=0
        lenabled_output=""
        lenabled_success=${false}
    
        lname=""
        lname_short=""

        lstatus=${false}
        lstatus_failure_count=0
        lstatus_output=""
        lstatus_success="${false}"

        ii=$(( ${i} - 1 ))                                                                          #array indexes alway run one less than integer length

        lname=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.data['${ii}'].id'` 
        lname_short=`${cmd_echo} ${lname} | ${cmd_awk} -F"." '{print $1}'`                          #get service name from json

        lenabled_output=`${cmd_systemctl} is-enabled ${lname_short}`                                #get enabled from json

        lstatus_output=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.data['${ii}'].active_state'`      #get status from json

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
        ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"name":"'${lname}'"}'`

        #enable service
                                                                                                    #enable service if disabled
        if [ ${lenabled} -eq ${false} ] && [ ${dry_run} -eq ${false} ]; then
            ${cmd_systemctl} enable ${lname} > /dev/null 2>&1

            lenabled_output=`${cmd_systemctl} is-enabled ${lname_short}`                            #get enabled from json

                                                                                                    #set bool value for enable
            case "${lenabled_output}" in
                "enabled")  lenabled=${true}    ;;
                "disabled") lenabled=${false}   ;;
                *)          lenabled=${true}    ;;                                                  #fail true to avoid err messages
            esac

            if [ ${lenabled} -eq ${true} ]; then
                lenabled_success=${true}                                                            #set success bit
                (( lenabled_success_count++ ))                                                      #increment successes
            else    
                lenabled_success=${false}                                                           #set failure bit
                (( lenabled_failure_count++ ))                                                      #increment failures
            fi
        fi

                                                                                                    #output stats to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"enabled":"'${lenabled}'"}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"enabling":"'${lenabled_success}'"}'`     

        #start service
        if [ ${lstatus} -eq ${false} ] && [ ${dry_run} -eq ${false} ]; then
            ${cmd_systemctl} start ${lname} > /dev/null 2>&1

                                                                                                    #get status from json
            lstatus_output=`${cmd_osqueryi} 'select active_state from systemd_units where id = "docker.service"' --json | ${cmd_jq} -r '.[].active_state'`  

                                                                                                    #set bool value for status
            case "${lstatus_output}" in
                "active")  lstatus=${true}      ;;
                *)         lstatus=${false}     ;;
            esac

            if [ ${lstatus} -eq ${true} ]; then
                lstatus_success=${true}                                                             #set success bit
                (( lstatus_success_count++ ))                                                       #increment successes
            else    
                lstatus_success=${false}                                                            #set failure bit
                (( lstatus_failure_count++ ))                                                       #increment failures
            fi
        fi

                                                                                                    #output stats to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"started":"'${lstatus}'"}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.services['${ii}'] |=.+ {"starting":"'${lstatus_success}'"}'`     
    done
                                                                                                    #output stats to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.enable |=.+ {"success":"'${lenabled_success_count}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.enable |=.+ {"failed":"'${lenabled_failure_count}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.status |=.+ {"success":"'${lstatus_success_count}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.status |=.+ {"failed":"'${lstatus_failure_count}'"}'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c      
}