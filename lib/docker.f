function docker.true {
    #accepts 0 args.  returns true/false if is a container under docker

    local lcgroup_pid1=`${cmd_cat} /proc/self/cgroup | ${cmd_grep} ^1:`

                                                                                                    #for those running docker daemon
    [ `${cmd_echo} "${lcgroup_pid1}" | ${cmd_grep} -ci docker` -gt 0 ] && local lexitstring=${true} || local lexitstring=${false}
                                                                                                    #for those running docker engine
    [ `${cmd_echo} "${lcgroup_pid1}" | ${cmd_grep} -ci ^1:` -eq 0 ] && local lexitstring=${true} || local lexitstring=${false}

    ${cmd_echo} ${lexitstring}
function docker.images {
    #accepts 0 args, returns json string of all containers including exited

    local loutput=`${cmd_docker} images --format '{{json .}}' | ${cmd_jq} -c`

    echo ${loutput}
}
function docker.images.inspect {
    #accepts 1 arg string id of docker container, returns json string of all containers including exited

    local lid=${1}
    local loutput=`${cmd_docker} inspect images ${lid} --format '{{json .}}' | ${cmd_jq} -c`

    echo ${loutput}
}
function docker.ps.all {
    #accepts 0 args, returns json string of all containers including exited

    local loutput=`${cmd_docker} ps -a --format '{{json .}}' | ${cmd_jq} -c`

    echo ${loutput}
}
function docker.ps.running {
    #accepts 0 args, returns json string of all containers including exited

    local loutput=`${cmd_docker} ps --format '{{json .}}' | ${cmd_jq} -c`

    echo ${loutput}
}