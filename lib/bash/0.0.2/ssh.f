function ssh.config.tojson {
    local lfile=${1}
    local ljson="{}"
    local lhost=""
    local lhost_ocid=""
    local lhost_name=""
    local lproxy=""
    local lproxy_host=""
    local lproxy_ocid=""

    if [ -f ${lfile} ]; then 

        oldifs=${IFS}                                                                                       #ifs sucks
        IFS=$'\n'                                                                                           #set ifs to newline from default space
        
        i=0
        j=0

        for line in `${cmd_cat} ${lfile}`; do 
        
            #reset looping variables to empty
            lhost=""
            lhost_ocid=""
            lhost_name=""
            lproxy_jump=""
            j=0

            #parse ssh cofig file
            if [ `${cmd_echo} ${line} | ${cmd_grep} ^Host` ]; then
                (( i++ ))
                ii=$(( ${i} - 1 ))

                lhost=`${cmd_echo} ${line} | ${cmd_awk} '{print $2}'`
                lhost_ocid=`${cmd_echo} ${line} | ${cmd_awk} '{print $3}'`
            
                ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.hosts['${ii}'] |=.+ {"name":"'${lhost}'"}'`
                ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.hosts['${ii}'] |=.+ {"ocid":"'${lhost_ocid}'"}'`
            fi

            if [ `${cmd_echo} ${line} | ${cmd_grep} -E '(^[[:space:]]+)HostName'` ]; then 
                lhost_name=`${cmd_echo} ${line} | ${cmd_awk} '{print $2}'`
                ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.hosts['${ii}'] |=.+ {"host":"'${lhost_name}'"}'`
            fi

            if [ `${cmd_echo} ${line} | ${cmd_grep} -E '(^[[:space:]]+)ProxyJump'` ]; then
                lproxy_jump=`${cmd_echo} ${line} |  ${cmd_awk} -F" " '{print $2}'`
                
                #get jumphosts
                for jumphost in `${cmd_echo} ${lproxy_jump} | ${cmd_sed} 's/,/\n/g'`; do
                    (( j++ ))
                    jj=$(( ${j} - 1 ))

                    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.hosts['${ii}'].jumphost['${jj}'] |=.+ {"name":"'${jumphost}'"}'`
                done
            fi

        done

        IFS=${oldifs}  
    fi
                                                                         
    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}
# function ssh.create.home {
#     # creates .ssh folder in usrs ~ folder.  
#     # returns boolean true/false for success, and exitcode

#     local lexitstring=${false}
#     local lexitcode=${exitcrit}

#     if [ ~/.ssh ]; then
#         lexitstring=${false}
#         lexitcode=${exitok}
#     else
#         lexi
# }
function ssh.strip.jumphost {
    # strips the jumphost line from the provided SSH config file
    # accepts 2 args.  1 is the file to read in, 2 is the path including file to output to.
    # returns boolean true/false for success, and exitcode.
    local lfile=${1}
    local lpath=${2}

    ${cmd_cat} ${lfile} | ${cmd_grep} -vE '(^[[:space:]]+)ProxyJump' > ${lpath} && { ${cmd_echo} ${true}; return ${exitok}; } || { ${cmd_echo} ${false}; return ${exitcrit}; }
}