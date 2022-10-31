#variables
plugin_version=0.0.1

#functions
function plugin_intel {
    #declare local variables
    local ljson="{}"
    local ldocker_json=`docker.report`
    local limages_json=`${cmd_echo} ${ldocker_json} | ${cmd_jq} -c '.images'`
    local lps_json=`${cmd_echo} ${ldocker_json} | ${cmd_jq} -c '.ps'`
    local lstats_json=`${cmd_echo} ${ldocker_json} | ${cmd_jq} -c '.stats'`

    #main
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.images |=.+ '"${limages_json}"`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.ps |=.+ '"${lps_json}"`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats |=.+ '"${lstats_json}"`

    ${cmd_echo} "${ljson}" | ${cmd_jq} -c
}

function plugin_logging {
    #declare local variables
    local ljson=${1}
    local lmessage_json="{}"
    local lrunlog_json="{}"
    local limages_total_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.images| length'`           #get array length
    local lprocesses_total_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.ps| length'`            #get array length

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

        ${cmd_logger} --tag ${syslog_tag} ${lrunlog_json}										    #off to syslog facility

                                                                                                    #did it successfull log
        [ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}
    fi 

    if [ ! -z ${filelog} ]; then

        [ ! -d ${filelog} ] && ${cmd_mkdir} ${filelog}											    #if it aint there, make it!
        ${cmd_echo} ${lrunlog_json} >> ${filelog}/${plugin}										    #log it

                                                                                                    #did it successfully log
        [ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}
    fi

    #send logs for images
    for i in `${cmd_seq} 1 ${limages_total_count}`; do
        ii=$(( ${i} - 1 ))
                                                                                                    #get required values
        #get image json
        limage_json=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.images['${ii}']' | ${cmd_jq} -c`


        if ( [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ] ) || [ ! -z ${filelog} ]; then
																									#event log info
            lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
            lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.images |=.+ '"${limage_json}"`  
        fi

        if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then
            ${cmd_logger} --tag ${syslog_tag} "${lmessage_json}"
            
                                                                                                    #did the message send
            [ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}

                                                                                                    #update json to show log was sent
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.images['${ii}'].syslog |=.+ {"syslog":"'${lfile_syslog}'"}'`
        fi 

                                                                                                    #send logs to file log
        if [ ! -z ${filelog} ]; then
            ${cmd_echo} ${lmessage_json} >> ${filelog}/${plugin}									#log it

                                                                                                    #did the message send?
            [ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}

                                                                                                    #update json to show log was sent
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.images['${ii}'].syslog |=.+ {"filelog":"'${lfile_filelog}'"}'`
        fi
    done

    #send logs for processes
    for i in `${cmd_seq} 1 ${lprocesses_total_count}`; do
        ii=$(( ${i} - 1 ))
                                                                                                    #get required values
        #get image json
        lprocess_json=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.ps['${ii}']' | ${cmd_jq} -c`


        if ( [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ] ) || [ ! -z ${filelog} ]; then
																									#event log info
            lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
            lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.ps |=.+ '"${lprocess_json}"`  
        fi

        if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then
            ${cmd_logger} --tag ${syslog_tag} "${lmessage_json}"
            
                                                                                                    #did the message send
            [ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}

                                                                                                    #update json to show log was sent
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.ps['${ii}'].syslog |=.+ {"syslog":"'${lfile_syslog}'"}'`
        fi 

                                                                                                    #send logs to file log
        if [ ! -z ${filelog} ]; then
            ${cmd_echo} ${lmessage_json} >> ${filelog}/${plugin}									#log it

                                                                                                    #did the message send?
            [ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}

                                                                                                    #update json to show log was sent
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.ps['${ii}'].syslog |=.+ {"filelog":"'${lfile_filelog}'"}'`
        fi
    done

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}

function plugin_output {
    #decalare local variables
    local ljson=${1}
    local limages_total_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.images| length'`           #get array length
    local lprocesses_total_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.ps| length'`            #get array length

    #main
    #output images
    ${cmd_echo} --------------------------------------------------------------------------------

    [ ${dry_run} -eq ${true} ] && dry_run_marker=*


                                                                                                    #output images header
    ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"													\
		"${dry_run_marker}"																			\
		"Image"		    																		    \
		"ID"																				        \
		"Active"																				    \
		"Deleted"
       
                                                                                                    #loop images data
    for i in `${cmd_seq} 1 ${limages_total_count}`; do
        ii=$(( ${i} - 1 ))

                                                                                                    #get the image repository
        limage_repository=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.images['${ii}'].Repository'`               
        limage_tag=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.images['${ii}'].Tag'`              #get the image tag
        limage_id=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.images['${ii}'].ID'`                #get the image ID
        limage_active=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.images['${ii}'].active'`        #get the image status
        limage_deleted=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.images['${ii}'].deleted'`      #get the image delete status

                                                                                                    #get required values

                                                                                                    #output images table
        ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"                                                \
            "${i}"                                                                                  \
            "`${cmd_echo} ${limage_repository}:${limage_tag} | ${cmd_head} -c 40`"                  \
            "`${cmd_echo} ${limage_id} | ${cmd_head} -c 10`"                                        \
            "${limage_active}"                                                                      \
            "${limage_deleted}"
    done

                                                                                                    #get counters from stats in json
    limages_active_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.images.active'`
    limages_deleted_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.images.deleted.success'`


    ${cmd_echo}

    ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"												    \
		""																			                \
		"Totals"																				    \
		""																					        \
		"Active"																				    \
		"Deleted"

    ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"												    \
		""																			                \
		""										                							        \
		""																					        \
		"${limages_active_count}"																    \
		"${limages_deleted_count}"
    

    #output processes
    ${cmd_echo};${cmd_echo}
    ${cmd_echo} --------------------------------------------------------------------------------

    [ ${dry_run} -eq ${true} ] && dry_run_marker=*


                                                                                                    #output process header
    ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"													\
		"${dry_run_marker}"																			\
		"Process Name"		    																    \
		"ID"																				        \
		"State"																				        \
		"Deleted"
       
                                                                                                    #loop process data
    for i in `${cmd_seq} 1 ${lprocesses_total_count}`; do
        ii=$(( ${i} - 1 ))

                                                                                                    #get the process repository
        lprocess_id=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.ps['${ii}'].ID'`                  #get the processs id
        lprocess_name=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.ps['${ii}'].Names'`             #get the process name
        lprocess_state=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.ps['${ii}'].State'`            #get the process state
        lprocess_deleted=`${cmd_echo} "${ljson}" | ${cmd_jq} -r '.data.ps['${ii}'].deleted'`        #get the process delete status

                                                                                                    #get required values

                                                                                                    #output process table
        ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"                                                \
            "${i}"                                                                                  \
            "`${cmd_echo} ${lprocess_name} | ${cmd_head} -c 40`"                                    \
            "`${cmd_echo} ${lprocess_id} | ${cmd_head} -c 10`"                                      \
            "${lprocess_state}"                                                                     \
            "${lprocess_deleted}"
    done

                                                                                                    #get counters from stats in json
    lprocesses_running_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.ps.running'`
    lprocesses_deleted_count=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.stats.ps.deleted.success'`


    ${cmd_echo}

    ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"												    \
		""																			                \
		"Totals"																				    \
		""																					        \
		"Running"																				    \
		"Deleted"

    ${cmd_printf} "%-2s %-40s %-10s %10s %10s\n"												    \
		""																			                \
		""										                							        \
		""																					        \
		"${lprocesses_running_count}"															    \
		"${lprocesses_deleted_count}"


}

function plugin_remediate {
    #declare local variables
    local ljson=${1}
    local limages_total_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.images | length'`
    local limages_json=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.images' | ${cmd_jq} -c`
    local limages_delete_count=`${cmd_echo} "${limages_json}" | ${cmd_jq} '.[] | select(.active == '${false}')' | ${cmd_jq} -sc | ${cmd_jq} '. | length'`
    local limages_delete_failure_count=0
    local limages_delete_success_count=0

    local limage_delete=""
    local limage_delete_status=${false}
    local limage_id=""
    local limage_active=""

    local lprocesses_total_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.ps | length'`
    local lprocesses_json=`${cmd_echo} "${ljson}" | ${cmd_jq} '.data.ps' | ${cmd_jq} -c`
    local lprocesses_delete_count=`${cmd_echo} "${lprocesses_json}" | ${cmd_jq} '.[] | select(.state != "active")' | ${cmd_jq} -sc | ${cmd_jq} '. | length'`
    local lprocesses_delete_failure_count=0
    local lprocesses_delete_success_count=0

    local lprocess_delete=""
    local lprocess_delete_status=${false}
    local lprocess_id=""

    local ii=""

    #main
    ##delete unused images
    for i in `${cmd_seq} 1 ${limages_total_count}`; do
        ii=$(( ${i} - 1 ))
        limage_json=`${cmd_echo} "${limages_json}" | ${cmd_jq} '.['${ii}']' | ${cmd_jq} -c`
        limage_active=`${cmd_echo} "${limage_json}" | ${cmd_jq} '.active'`

        if [ ${limage_active} == ${true} ]; then
            limage_delete_status=${false}

        else
            if [ ${dry_run} -eq ${false} ]; then

                #${cmd_docker} rmi ${limage_id} > /dev/null 2>&1                                    #remove the image by its id
                                                                                 
                if [ ${?} -eq ${exitok} ]; then
                    (( limages_delete_success_count++ ))                                            #increment counters on success
                    limage_delete_status=${true}
                else
                    (( limages_delete_failure_count++ ))                                            #increment counters on failure
                    limage_delete_status=${false}
                fi
            else
                (( limages_delete_failure_count++ ))                                                #increment counters on dry_run
                limage_delete_status=${false}
            fi
        fi

        limage_json=`${cmd_echo} ${limage_json} | ${cmd_jq} '. |=.+ {"deleted":'${limage_delete_status}'}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.images['${ii}'] |=.+ '"${limage_json}"` 
    done

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.images.deleted |=.+ {"failure":'${limages_delete_failure_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.images.deleted |=.+ {"success":'${limages_delete_success_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.images |=.+ {"total":'${limages_total_count}'}'`


    ##delete stale containers(processes)
    for i in `${cmd_seq} 1 ${lprocesses_total_count}`; do
        ii=$(( ${i} - 1 ))
        lprocess_json=`${cmd_echo} "${lprocesses_json}" | ${cmd_jq} -c '.['${ii}']' | ${cmd_jq} -c`
        lprocess_active=`${cmd_echo} "${lprocess_json}" | ${cmd_jq} -r '.active'`

        if [ ${lprocess_active} == ${true} ]; then
            lprocess_delete_status=${false}

        else
            if [ ${dry_run} -eq ${false} ]; then

                #${cmd_docker} rm ${lprocess_id} > /dev/null 2>&1                                   #remove the process by its id
                                                                                    
                if [ ${?} -eq ${exitok} ]; then
                    (( lprocesses_delete_success_count++ ))                                         #increment counters on success
                    lprocess_delete_status=${true}
                else
                (( lprocesses_delete_failure_count++ ))                                             #increment counters on failure
                    lprocess_delete_status=${false}
                fi
            else
                (( lprocess_delete_failure_count++ ))                                               #increment counters on dry_run
                lprocess_delete_status=${false}
            fi
        fi


        lprocess_json=`${cmd_echo} ${lprocess_json} | ${cmd_jq} '. |=.+ {"deleted":'${lprocess_delete_status}'}'`
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.ps['${ii}'] |=.+ '"${lprocess_json}"` 
    done

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps.deleted |=.+ {"failure":'${lprocesses_delete_failure_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps.deleted |=.+ {"success":'${lprocesses_delete_success_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps |=.+ {"total":'${lprocesses_total_count}'}'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}