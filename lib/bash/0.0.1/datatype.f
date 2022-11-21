#20220504
#version=0.0.1

function is.datatype {

    #local variables
    local ldatatype=${1}
    local lvariable=${2}
    local lregex=""
    
    
    case ${ldatatype} in
        boolean)        lregex=^[01]$                               ;;
        float)          lregex=^[-]?[0-9.]+$                        ;;
        integer)        lregex=^[-]?[0-9]+$                         ;;
        string)         lregex=^[0-9A-Za-z_-]+$                     ;;
        string.shell)   lregex=^[\/0-9A-Za-z_.-]+$                  ;;
        string.special) lregex=^[\]\[\)\(\?\^\/0-9A-Za-z_.-]+$      ;;
    esac

    if [ ! -z "${lregex}" ]; then
        [[ ${lvariable} =~ ${lregex} ]] && ${cmd_echo} ${true} || ${cmd_echo} ${false}
    else
        ${cmd_echo} ${false}
    fi

}

function is.datatype.boolean {
    #placeholder
    #accepts 1 arg variable value, returns true if value is a boolean.

    #local variables
    local lvariable=${1}

    #main
    is.datatype boolean ${lvariable}
}

function is.datatype.exitcode {
    #accepts 1 arg variable value, returns true if value is a within the rage for an exit code 0-255

    #local variables
    local lvariable=${1}

    #main
    [ ${lvariable} -ge 0 ] && [ ${lvariable} -le 255 ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}
}

function is.datatype.float {
    #placeholder
    #accepts 1 arg variable value, returns true if value is a float

    #local variables
    local lvariable=${1}

    #main
    is.datatype float ${lvariable}
}

function is.datatype.integer {
    #placeholder
    #accepts 1 arg variable value, returns true if value is an integer

    #local variables
    local lvariable=${1}

    #main
    is.datatype integer ${lvariable}
}

function is.datatype.string {
    #placeholder
    #accepts 1 arg variable value, returns true if value is a basic string containing only alpha and number

    #local variables
    local lvariable=${1}

    #main
    is.datatype string ${lvariable}
}

function is.datatype.string.shell {
    #placeholder
    #accepts 1 arg variable value, returns bool if value is a string containing only characters approved for shell paths

    #local variables
    local lvariable=${1}

    #main
    is.datatype string.shell ${lvariable}
}

function is.datatype.string.special {
    #placeholder
    #accepts 1 arg variable value, returns bool if value is a string containing only alpha, number, and approved special characters

    #local variables
    local lvariable=${1}

    #main
    is.datatype string.special ${lvariable}
}