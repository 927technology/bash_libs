#20221027
#version=0.0.1

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
    #accepts 0 args.  returns json of docker ps and image status

    local ljson="{}"
    
    local limage_active_key=""
    local limage_id=""
    local limage_repository=""
    local limage_tag=""
    local limages_active_count=0
    local limages_json=""
    local limages_json_indexed=""
    local limages_total_count=0

    local lps_exited_count=0
    local lps_image=0
    local lps_json=""
    local lps_other_count=0
    local lps_running_count=0
    local lps_stopped_count=0
    local lps_total_count=0

    local lserver_json=""
    local lserver_version=""

    #get docker server info
    if [ ${odo} -eq ${true} ]; then                                                                                           
        lserver_json=`${cmd_odoctl} docker system info --format="{{ json . }}" | ${cmd_jq} -c`      #get docker process json from odoctl
    else
        lserver_json=`${cmd_docker} system info --format="{{ json . }}" | ${cmd_jq} -c`             #get docker process json  
    fi

    lserver_version=`${cmd_echo} ${lserver_json} | ${cmd_jq} -r '.ServerVersion'`

    #docker image info 
    if [ ${odo} -eq ${true} ]; then                                                                                      
        limages_json=`${cmd_odoctl} docker images --format="{{ json . }}" | ${cmd_jq} -sc`          #get docker process json from odoctl
    else
        limages_json=`${cmd_docker} images --format="{{ json . }}" | ${cmd_jq} -sc`                 #get docker process json
    fi

                                                                                                    #set the default active status for the image
    limages_json=`${cmd_echo} "${limages_json}" | ${cmd_jq} '.[] |=.+ {"active":'${false}'}'`

    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.images |=.+ '"${limages_json}"`                     #add docker image to json
                                                                                                    
    limages_total_count=`${cmd_echo} "${limages_json}" | ${cmd_jq} '. | length'`                    #get the number of images

                                                                                                    #add image totals to json
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.images |=.+ {"total":'"${limages_total_count}"'}'`

    #docker process info   
    if [ ${odo} -eq ${true} ]; then                                                                                           
        lps_json=`${cmd_odoctl} docker ps -aq --format="{{ json . }}" | ${cmd_jq} -sc`              #get docker process json from odoctl
    else
        lps_json=`${cmd_docker} ps -aq --format="{{ json . }}" | ${cmd_jq} -sc`                     #get docker process json  
    fi
                                                                                                                                                                                                     
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.ps |=.+ '"${lps_json}"`                             #add docker ps to json

    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.ps |=.+ {"total":'"${lps_total_count}"'}'`

                                                                                                    #get the number of processes
    lps_total_count=`${cmd_echo} "${lps_json}" | ${cmd_jq} '. | length'`
    lps_exited_count=`${cmd_echo} "${lps_json}" | ${cmd_jq} '.[] | select(.State == "exited")' | ${cmd_jq} -s '. | length'`
    
    case ${lserver_version} in
        18.*)
            lps_running_count=`${cmd_echo} "${lps_json}" | ${cmd_jq} '.[] | select(.Status | contains("Up "))' | ${cmd_jq} -s '. | length'`
        ;;
        20.* | *)
            lps_running_count=`${cmd_echo} "${lps_json}" | ${cmd_jq} '.[] | select(.State == "running")' | ${cmd_jq} -s '. | length'`
        ;;
    esac

    lps_other_count=$(( ${lps_total_count} - ${lps_running_count} - ${lps_exited_count} ))

                                                                                                    #find out if an image is in use
    for i in `${cmd_seq} 1 ${lps_total_count}`; do
        #set variable default values
        limage_active_key=""

        ii=$(( ${i} -1 ))

        lps_image=`${cmd_echo} "${lps_json}" | ${cmd_jq} -r '.['${ii}'].Image'`                     #get image id for the container
        lps_image_repository=`${cmd_echo} ${lps_image} | ${cmd_awk} -F":" '{print $1}'`             #get image id for the container
        lps_image_tag=`${cmd_echo} ${lps_image} | ${cmd_awk} -F":" '{print $2}'`                    #get image id for the container


        limages_json_indexed=`${cmd_echo} "${limages_json}" | ${cmd_jq} -c '. | to_entries'`

                                                                                                    #get the image key that matches
        limage_active_key=`${cmd_echo} ${limages_json_indexed} | ${cmd_jq} '.[] | select((.value.Repository == "'${lps_image_repository}'" and .value.Tag == "'${lps_image_tag}'") or (.value.ID == "'${lps_image_id}'")).key'`

                                                                                                    #if key is not empty change active to true
        if [ ! -z ${limage_active_key} ]; then
            ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.images['${limage_active_key}'] |=.+ {"active":'${true}'}'`
        fi
    done

                                                                                                    #count active images
    limages_active_count=`${cmd_echo} "${ljson}" | ${cmd_jq} '.images[] | select(.active == '${true}')' | ${cmd_jq} -s '. | length'`

                                                                                                    #add process totals to json
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.ps |=.+ {"total":'${lps_total_count}'}'`
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.ps |=.+ {"exited":'${lps_exited_count}'}'`
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.ps |=.+ {"running":'${lps_running_count}'}'`
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.ps |=.+ {"other":'${lps_other_count}'}'`
    
                                                                                                    #add active images to json
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.images |=.+ {"active":'${limages_active_count}'}'`

                                                                                                    #add server info to json
    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.stats.server |=.+ '"${lserver_json}"`

    ${cmd_echo} "${ljson}" | ${cmd_jq} -c
}