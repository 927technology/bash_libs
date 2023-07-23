#20230723
#version=0.1.0

function is.datatype {
    #accepts 2 arguments
    #1) datatype - boolean, float, integer, string, string.shell string.special
    #2) variable to check datatype from

    #local variables
    local ldatatype=${1}
    local lvariable=${2}
    local lregex=""

    local lexitcode=${false}
    local lexitstring=""
    
    
    case ${ldatatype} in
        boolean)        lregex=^[01]$                               ;;
        float)          lregex=^[-]?[0-9.]+$                        ;;
        integer)        lregex=^[-]?[0-9]+$                         ;;
        string)         lregex=^[0-9A-Za-z_-]+$                     ;;
        string.shell)   lregex=^[\/0-9A-Za-z_.-]+$                  ;;
        string.special) lregex=^[\]\[\)\(\?\^\/0-9A-Za-z_.-]+$      ;;
    esac

    if [ ! -z "${lregex}" ]; then
        if [[ ${lvariable} =~ ${lregex} ]]; then
            lexitcode=${exitok}
            lexitstring=${true}
        else
            lexitcode=${exitcrit}
            lexitstring=${false}
        fi
    else
        lexitcode=${exitcrit}
        lexitstring=${false}
    fi

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}

function is.datatype.boolean {
    #accepts 1 argument
    #1) variable to check datatype boolean from

    #local variables
    local lvariable=${1}

    #main
    is.datatype boolean ${lvariable}
}

function is.datatype.exitcode {
    #accepts 1 argument
    #1) variable to check datatype exitcode from

    #local variables
    local lvariable=${1}

    #main
    [ ${lvariable} -ge 0 ] && [ ${lvariable} -le 255 ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}
}

function is.datatype.float {
    #accepts 1 argument
    #1) variable to check datatype float from

    #local variables
    local lvariable=${1}

    #main
    is.datatype float ${lvariable}
}

function is.datatype.integer {
    #accepts 1 argument
    #1) variable to check datatype integer from

    #local variables
    local lvariable=${1}

    #main
    is.datatype integer ${lvariable}
}

function is.datatype.string {
    #accepts 1 argument
    #1) variable to check datatype string from   

    #local variables
    local lvariable=${1}

    #main
    is.datatype string ${lvariable}
}

function is.datatype.string.shell {
    #accepts 1 argument
    #1) variable to check datatype string-shell from

    #local variables
    local lvariable=${1}

    #main
    is.datatype string.shell ${lvariable}
}

function is.datatype.string.special {
    #accepts 1 argument
    #1) variable to check datatype string-special from

    #local variables
    local lvariable=${1}

    #main
    is.datatype string.special ${lvariable}
}