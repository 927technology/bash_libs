function odo.docker.images {
    #accepts 0 args, returns json string of images

    local loutput=`${cmd_odoctl} docker images --format '{{json .}}' | ${cmd_jq} -c '.'`

    echo ${loutput}
}
function odo.docker.images.inspect {
    #accepts 1 arg string id of docker container, returns json string 

    local lid=${1}
    local loutput=`${cmd_odoctl} docker inspect images ${lid} --format '{{json .}}' | ${cmd_jq} -c '.'`

    echo ${loutput}
}
function odo.docker.ps.all {
    #accepts 0 args, returns json string of all containers including exited

    local loutput=`${cmd_odoctl} docker ps -a --format '{{json .}}' | ${cmd_jq} -c '.'`

    echo ${loutput}
}
function odo.docker.ps.running {
    #accepts 0 args, returns json string of all running containers

    local loutput=`${cmd_odoctl} docker ps --format '{{json .}}' | ${cmd_jq} -c '.'`

    echo ${loutput}
}
function odo.list {
    #accepts 0 args, returns json string of all odo apps

    local loutput=`${cmd_odoctl} list --format json | ${cmd_jq} -c '.[]'`

    echo ${loutput}
}