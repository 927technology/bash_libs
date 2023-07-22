function patching.get.validation {

    #local variables
    local lpatching_json=../lib/validate.json
    local lhostname=${1}                                                                            #prs-au-ap-0.node.ad1.ap-sydney-1
    local lhostname_command=""
    local lhostname_command_success=${false}
    local lhostname_host=""
    local lhostname_type=""
    local lhostname_node=""
    local lhostname_ad=""
    local lhostname_region=""
    local lhostname_validation=${false}
    local ljson="{}"

    #main

                                                                                                    #parse hostname
    lhostname_host=`${cmd_echo} ${lhostname} | ${cmd_awk} -F"." '{print $1}'`
    lhostname_type=`${cmd_echo} ${lhostname_host} | ${cmd_awk} -F"-" '{print $(NF - 1)}'`
    lhostname_node=`${cmd_echo} ${lhostname_host} | ${cmd_awk} -F"-" '{print $NF}'`
    lhostname_name=`${cmd_echo} ${lhostname_host} | ${cmd_sed} -e 's/-'${lhostname_type}'//g' -e 's/-'${lhostname_node}'//g'`
    lhostname_ad=`${cmd_echo} ${lhostname} | ${cmd_awk} -F"." '{print $3}'`
    lhostname_region=`${cmd_echo} ${lhostname} | ${cmd_awk} -F"." '{print $NF}' | ${cmd_awk} -F"-" '{print $2}'`

                                                                                                    #add host details to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.name |=.+ {"type":"'${lhostname}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.host |=.+ {"type":"'${lhostname_type}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.host |=.+ {"node":"'${lhostname_node}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.host |=.+ {"name":"'${lhostname_name}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.host |=.+ {"ad":"'${lhostname_ad}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.host |=.+ {"region":"'${lhostname_region}'"}'`

                                                                                                    #get the application for the host type
    lhostname_application=`${cmd_cat} ${lpatching_json} | ${cmd_jq} -r '.hosts[] | select((.name == "'${lhostname_name}'") and (.type == "'${lhostname_type}'")).application'`
    
    if [ ! -z ${lhostname_application} ]; then
                                                                                                    #set validation based on host type
        case ${lhostname_type} in
            ap | apex | customer-ap | idp | splunk)
                lhostname_validation=${true}
            ;;
            none)
                #no validation hosts
                ${cmd_echo} no validation for this application type
            ;;
            *)
                #everybody else
                lhostname_type=unknown
            ;;
        esac
        
                                                                                                    #validate host
        if [ ${lhostname_validation} -eq ${true} ]; then
            lhostname_command=`${cmd_cat} ${lpatching_json} | ${cmd_jq} -r '.validation[] | select(.type == "'${lhostname_type}'").command'`
       

            if [ ! -z ${lhostname_command} ]; then


            case ${lhostname_type} in
                ap)
                    lhostname_command_output=$( ${cmd_ssh} ${lhostname} -o stricthostkeychecking=no -o connecttimeout=15 'output=$(sudo odoctl exec -i -a '${lhostname_application}' '${lhostname_command}' 2>&1; echo ${output})')
                    echo $lhostname_command_output
                ;;
                *)
                    lhostname_command_output=`${cmd_ssh} ${lhostname} -o stricthostkeychecking=no -o connecttimeout=15 "sudo odoctl exec -i -a ${lhostname_application} ${lhostname_command}"` 2>/dev/null
                ;;
            esac



                
  
                if [ ${?} -eq ${exitok} ]; then
                    lhostname_command_success=${true}
                else
                    lhostname_command_output=failure   
                fi
            else
                lhostname_command_output=failure
            fi
        fi
    fi

                                                                                                    #output command status to json
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.command |=.+ {"validation":"'"sudo odoctl exec -i -a ${lhostname_application} ${lhostname_command}"'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.command |=.+ {"success":"'${lhostname_command_success}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.command |=.+ {"output":"'"${lhostname_command_output}"'"}'`
 
    ${cmd_echo} ${ljson} #| ${cmd_jq} -c

}