#variables
plugin_version=0.0.1

#functions
function plugin_intel {
    #declare local variables
    local ljson=""
    local lyum_repo_root=/var/cache/yum
    local lyum_max_cacheB=$(( ${yum_max_cache} * 1024 * 1024 ))
    
    #main
    ljson=`shell.directory.size ${lyum_repo_root}`
    
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.cache.maximumB |=.+ '${lyum_max_cacheB}`

    ${cmd_echo} ${ljson}
}

function plugin_logging {
    #declare local variables
    local lcache_cleanup_message=
    local lcache_cleanup_success=${false}
    local lcache_exists=${false}
    local lcache_path=
    local lcache_sizeB=0
    local lcache_size_maxB=${yum_max_cache}
	local ljson=${1}
    local lmessage_json="{}"
    local lrunlog_json="{}"

    #main
                                                                                                    #get the required values from the array and variablize them
    lcache_cleanup_message=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.status.message'`
    lcache_cleanup_success=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.status.success'`
    lcache_exists=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.exists'`																	
    lcache_path=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.path'`
    lcache_sizeB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.sizeB'`
    lcache_sizeB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.sizeB'`
    lcache_size_maxB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.cache.maximumB'` 
 
    
                                                                                                    #run log info
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"build":"'${build}'"}'`
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"date":"'${now}'"}'`
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"dry_run":"'${dry_run}'"}'`
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"tag":"'${syslog_tag}'"}'`
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"enabled":"'${syslog}'"}'`
    lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"filelog":"'${filelog}'"}'`


                                                                                                    #event log info
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}' |=.+ {"message":"'${lcache_cleanup_message}'"}'`
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}' |=.+ {"success":"'${lcache_cleanup_success}'"}'`
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}' |=.+ {"exists":"'${lcache_exits}'"}'`
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}' |=.+ {"path":"'${lcache_path}'"}'`
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}' |=.+ {"sizeB":"'${lcache_sizeB}'"}'`
    lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}'.cache |=.+ {"maxiumB":"'${lcache_size_maxB}'"}'`
    

    if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then
        ${cmd_logger} --tag ${syslog_tag} ${lmessage_json}
        
                                                                                            #did the message send
        [ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}

                                                                                            #update json to show log was sent
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.log.syslog |=.+ '${lfile_syslog}`
    fi 

                                                                                            #send logs to file log
    if [ ! -z ${filelog} ]; then
        [ ! -d ${filelog} ] && ${cmd_mkdir} ${filelog}									    #if it aint there, make it!
        ${cmd_echo} ${lrunlog_json} >> ${filelog}/${plugin}							        #log it
        ${cmd_echo} ${lmessage_json} >> ${filelog}/${plugin}							    #log it

                                                                                            #did the message send?
        [ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}

                                                                                            #update json to show log was sent
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.log.filelog |=.+ '${lfile_filelog}`
    fi


    ${cmd_echo} ${ljson} | ${cmd_jq} -c 
}

function plugin_output {
    #declare local variables
    local lcache_cleanup_message=
    local lcache_cleanup_success=${false}
    local lcache_exists=${false}
    local lcache_path=
    local lcache_sizeB=0
    local lcache_size_maxB=${yum_max_cache}
	local ljson=${1}

    #main

                                                                                                        #get the required values from the array and variablize them
    lcache_cleanup_message=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.status.message'`
    lcache_cleanup_success=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.status.success'`
    lcache_exists=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.exists'`																	
    lcache_path=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.path'`
    lcache_sizeB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.sizeB'`
    lcache_sizeB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.sizeB'`
    lcache_size_maxB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.cache.maximumB'` 

    [ ${dry_run} -eq ${true} ] && dry_run_marker=*

    ${cmd_echo}
    ${cmd_echo} `shell.ucase ${plugin}`
    ${cmd_echo} ---------------------------------------------------------------------------------

																									#output yum header
	${cmd_printf} "%-2s %-30s %-24s %-10s %10s\n"														\
		"${dry_run_marker}"																			\
		"Path"																						\
		"Status"																					\
	    "Max CacheM"																				\
	    "SizeM"
	
																								    #output yum data
	${cmd_printf} "%-2s %-30s %-24s %-10s %10s\n"														\
        ""                                                                                          \
        "${lcache_path}"                                                                            \
        "${lcache_cleanup_message}"                                                                 \
        "$(( ${lcache_size_maxB} / 1024 / 1024 ))"                                                 \
        "$(( ${lcache_sizeB} / 1024 / 1024 ))"
}

function plugin_remediate {
    #declare local variables
    local lcache_cleanup_run=${false}
    local lcache_cleanup_message=
    local lcache_cleanup_success=${false}
    local lcache_exists=${false}
    local lcache_path=
    local lcache_sizeB=0
    local lcache_size_maxB=${yum_max_cache}
	local ljson=${1}

    #main
                                                                                                    #get the required values from the array and variablize them
    lcache_exists=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.exists'`																	
    lcache_path=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.path'`
    lcache_size_maxB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.cache.maximumB'`    
    lcache_sizeB=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.sizeB'`

                                                                                                    #cache is bigger than max
    if [ ${lcache_sizeB} -gt ${lcache_size_maxB} ] && [ ${dry_run} -eq ${false} ]; then
        lcache_cleanup=${true}
        lcache_cleanup_message=run

                                                                                                    #clean yum cache
        ${cmd_yum} clean all > /dev/null 2>&1

        [ ${?} -eq ${exitok} ] && lcache_cleanup_success=${true} || lcache_cleanup_success=${false}

        lcache_sizeB_new=`shell.directory.size ${lcache_path}`                                      #get new cache size
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.size |=.+ '${lcache_sizeB_new}`
    else
        [ ${dry_run} -eq ${true} ] && lcache_cleanup_message=dry_run_enabled || lcache_cleanup_message=cache_size_too_small
    fi

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.status |=.+ {"run":"'${lcache_cleanup_run}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.status |=.+ {"success":"'${lcache_cleanup_success}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.status |=.+ {"message":"'${lcache_cleanup_message}'"}'`

    ${cmd_echo} ${ljson}
}