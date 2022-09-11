#20220504
#build=0.0.2

function docker.true {
    #accepts 0 args.  returns true/false if is a container under docker

    local lcgroup_pid1=`${cmd_cat} /proc/self/cgroup | ${cmd_grep} ^1:`

                                                                                                    #for those running docker daemon
    [ `${cmd_echo} "${lcgroup_pid1}" | ${cmd_grep} -ci docker` -gt 0 ] && local lexitstring=${true} || local lexitstring=${false}
                                                                                                    #for those running docker engine
    [ `${cmd_echo} "${lcgroup_pid1}" | ${cmd_grep} -ci ^1:` -eq 0 ] && local lexitstring=${true} || local lexitstring=${false}

    ${cmd_echo} ${lexitstring}
}
function docker.report {
    local ljson="{}"
    local ldocker_ps_total_count=0
    local ldocker_ps_running_count=0
    local ldocker_ps_stopped_count=0
    local ldocker_ps_other_count=0
    local ldocker_ps_json=""




    #docker image info                                                                                       
    ldocker_images_json=`${cmd_docker} images --format="{{ json . }}" | ${cmd_jq} -sc`              #get docker process json

                                                                                                    #set the default active status for the image
    ldocker_images_json=`${cmd_echo} ${ldocker_images_json} | ${cmd_jq} '.[] |=.+ {"active":'${false}'}'`

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.images |=.+ '"${ldocker_images_json}"`                #add docker image to json
                                                                                                    
    ldocker_images_total_count=`${cmd_echo} ${ldocker_images_json} | ${cmd_jq} '. | length'`        #get the number of images

                                                                                                    #add image totals to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.images |=.+ {"total":'"${ldocker_images_total_count}"'}'`











    #docker process info                                                                                              
    ldocker_ps_json=`${cmd_docker} ps -aq --format="{{ json . }}" | ${cmd_jq} -sc`                  #get docker process json  
                                                                                                                                                                                                     
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.ps |=.+ '"${ldocker_ps_json}"`                        #add docker ps to json

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps |=.+ {"total":'"${ldocker_ps_total_count}"'}'`

                                                                                                    #get the number of processes
    ldocker_ps_total_count=`${cmd_echo} ${ldocker_ps_json} | ${cmd_jq} '. | length'`
    ldocker_ps_exited_count=`${cmd_echo} ${ldocker_ps_json} | ${cmd_jq} '.[] | select(.State == "exited")' | ${cmd_jq} -s '. | length'`
    ldocker_ps_running_count=`${cmd_echo} ${ldocker_ps_json} | ${cmd_jq} '.[] | select(.State == "running")' | ${cmd_jq} -s '. | length'`
    ldocker_ps_other_count=$(( ${ldocker_ps_total_count} - ${ldocker_ps_running_count} - ${ldocker_ps_exited_count} ))

                                                                                                    #find out if an image is in use
    for i in `${cmd_seq} 1 ${ldocker_ps_total_count}`; do
        ii=$(( ${i} -1 ))

        ldocker_ps_image=`${cmd_echo} ${ldocker_ps_json} | ${cmd_jq} -r '.['${ii}'].Image'`         #get image id for the container

        for j in `${cmd_seq} 1 ${ldocker_images_total_count}`; do
            jj=$(( ${j} -1 ))

            ldocker_image_id=`${cmd_echo} ${ldocker_images_json} | ${cmd_jq} -r '.['${jj}'].ID'`    #get the image id  
            ldocker_image_tag=`${cmd_echo} ${ldocker_images_json} | ${cmd_jq} -r '.['${jj}'].Tag'`  #get the image tag
                                                                                                    #get the image id 
            ldocker_image_repository=`${cmd_echo} ${ldocker_images_json} | ${cmd_jq} -r '.['${jj}'].Repository'`

                                                                                                    #set image to active if it is in use
            if [ "${ldocker_ps_image}" == "${ldocker_image_id}" ] || [ "${ldocker_ps_image}" == "${ldocker_image_repository}:${ldocker_image_tag}" ]; then
                ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.images['${jj}'] |=.+ {"active":'${true}'}'`
                break
            fi
        done
    done

                                                                                                    #count active images
    ldocker_images_active_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.images[] | select(.active == '${true}')' | ${cmd_jq} -s '. | length'`

                                                                                                    #add process totals to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps |=.+ {"total":'${ldocker_ps_total_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps |=.+ {"exited":'${ldocker_ps_exited_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps |=.+ {"running":'${ldocker_ps_running_count}'}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.ps |=.+ {"other":'${ldocker_ps_other_count}'}'`
    
                                                                                                    #add active images to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.stats.images |=.+ {"active":'${ldocker_images_active_count}'}'`

    ${cmd_echo} [${ljson}] | ${cmd_jq} -c
}