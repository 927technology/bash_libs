#date 20221013
#version=0.0.1

function kubectl.deployments.status {
    #accepts 2 args.  1 name of the deployment 2 the namespace.  returns json string of status.

    local ldeployment=${1}
    local lnamespace=${2}

    if [ ! -z ${ldeployment} ] || [ ! -z ${lnamespace} ]; then
        local lstatus_json=`${cmd_kubectl} get deployments -n ${lnamespace} ${ldeployment} -o json 2> /dev/null | ${cmd_jq} -c '.status' | ${cmd_jq} -sc`

        [[ -z ${lstatus_json} ]] && { local lstatus=${false}; lstatus_json={}; } || local lstatus=${true} 
        
        local loutput_json=\"OUTPUT\":${lstatus_json}
    else
        lstatus=${false}
        local lstatus_json={}
    fi

    local lscript_json=\"FUNCTION\":{\"status\":${lstatus}}
    local loutput_json=\"OUTPUT\":${lstatus_json}

    local lexitstring={${lscript_json}\,${loutput_json}}
    ${cmd_echo} ${lexitstring}
}
function kubectl.ns.create {
    #accepts 1 arg.  1 name of namespace string.  returns boolean true/false if the namespace was created

    local lnamespace=${1}
    local lexgiitstring=${false}

    [ `kubectl.ns.exists ${lnamespace}` -eq ${true} ] || { ${cmd_kubectl} create namespace ${lnamespace} > /dev/null 2>&1; lexitstring=${true}; }

    ${cmd_echo} ${lexitstring}
}
function kubectl.ns.exists {
    #accepts 1 arg.  1 name of namespace string.  returns boolean true/false if exists
    
    local lnamespace=${1}
    local lexitstring=${false}                                                                      #set default value
                                                                                                    #query kubectl json for name space
    local lnamespace_json=`${cmd_kubectl} get ns -o json | ${cmd_jq} '.items[].metadata | select(.name == "'${lnamespace}'")'`
    [ -z "${lnamespace_json}" ] || lexitstring=${true}

    ${cmd_echo} ${lexitstring}
}
function kubectl.ns.status {
    #accepts 1 arg.  1 name the namespace.  returns json string of status.

    local lnamespace=${1}

    if [ ! -z ${lnamespace} ] || [ ! -z ${lnamespace} ]; then
        local lstatus_json=`${cmd_kubectl} get namespace -n ${lnamespace}  -o json 2> /dev/null | ${cmd_jq} '.items[] | {status: .status.phase, namespace: .metadata.name}' | ${cmd_jq} -sc`

        [[ -z ${lstatus_json} ]] && { local lstatus=${false}; lstatus_json={}; } || local lstatus=${true} 
        
        local loutput_json=\"OUTPUT\":${lstatus_json}
    else
        lstatus=${false}
        local lstatus_json={}
    fi

    local lscript_json=\"FUNCTION\":{\"status\":${lstatus}}
    local loutput_json=\"OUTPUT\":${lstatus_json}

    local lexitstring={${lscript_json}\,${loutput_json}}
    ${cmd_echo} ${lexitstring}
}
function kubectl.pods.status {
    #accepts 1 arg.  1 name the namespace.  returns json string of status.

    local lnamespace=${1}

    if [ ! -z ${lnamespace} ] || [ ! -z ${lnamespace} ]; then
        local lstatus_json=`${cmd_kubectl} get pods -n ${lnamespace} -o json 2> /dev/null | ${cmd_jq} '.items[] | {name: .metadata.name, namespace: .metadata.namespace, createtime: .metadata.creationTimestamp, env: .spec.containers[].env, nodeName: .spec.nodeName, containerStatuses: .status.containerStatuses[]}' | ${cmd_jq} -sc
`

        [[ -z ${lstatus_json} ]] && { local lstatus=${false}; lstatus_json={}; } || local lstatus=${true} 
        
        local loutput_json=\"OUTPUT\":${lstatus_json}
    else
        lstatus=${false}
        local lstatus_json={}
    fi

    local lscript_json=\"FUNCTION\":{\"status\":${lstatus}}
    local loutput_json=\"OUTPUT\":${lstatus_json}

    local lexitstring={${lscript_json}\,${loutput_json}}
    ${cmd_echo} ${lexitstring}
}
function kubectl.validate.kubecontrol {
    #accepts 0 args.  returns boolean of successfull communication with kubernetes cluster

    local lexitcode=${false}                                                                        #always fail closed

    ${cmd_kubectl} get nodes > /dev/null 2>&1
		case ${?} in 
			0) lexitcode=${true} ;;																    #exit ok
			*) lexitcode=${false} ;;												                #exit !ok
		esac

    ${cmd_echo} ${lexitcode}
}