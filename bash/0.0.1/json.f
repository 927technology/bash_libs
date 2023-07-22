#date 20221013
#version=0.0.1

function json.contains {
    #accepts 4 arguments.  
    #argument 1 is the json stream
    #argment 2 is the path to json key
    #argment 3 is the key name
    #argument 4 is the key value search regex value

    local ljson=${1}
    local lpath=${2}
    local lkey=${3}
    local lvalue=${4}
    local loutput=
    local l=0

    if [ ! -z ${lvalue} ]; then
        for line in `echo ${ljson} | jq -c '.'${path}' | select(.'${lkey}'? | match("'${lvalue}'"))'`; do
            (( l++ ))
            if [ $l -gt 1 ]; then
                local loutput=${loutput},${line}
            else
                local loutput=${loutput}${line} 
            fi
        done
    else
            for line in `echo ${ljson} | jq -c '.'${path}`; do
            (( l++ ))
            if [ $l -gt 1 ]; then
                local loutput=${loutput},${line}
            else
                local loutput=${loutput}${line} 
            fi
        done
    fi

    loutput="${loutput}"
    echo ${loutput}
}
function json.key.is {
    #accepts 3 arguments
    #argument 1 is the json string
    #argument 2 is the key name
    #argment 3 is the key value

    local ljson=${1}
    #local larray=${2}
    local lkey=${2}
    local lvalue=${3}
    local loutput=
    local l=0

#    if [ ! -z ${ljson} ] && [ ! -z ${lkey} ] && [ ! -z ${lvalue} ]; then
#        echo ${ljson} | jq ${''
#    fi	
}
