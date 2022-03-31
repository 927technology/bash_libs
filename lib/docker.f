#dependancies cmd.v, bools.f

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