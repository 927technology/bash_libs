#date 20230723
#version=0.1.0

function file.exists {
    #accepts 1 argument
    #path to file
    #returns boolean true/false and errorcode
    
    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lfile=${1}

    #main
    if [ -f ${lfile} ]; then
        lexitcode=${exitok}
        lexitstring=${true}
    else
        lexitcode=${exitcrit}
        lexitstring=${false}
    fi

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}

function file.isdirectory {
    #acceps 1 argument
    #1) path to directory

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lfile=${1}

    #main
    if [ -d ${lfile} ]; then
        lexitcode=${exitok}
        lexitstring=${true}
    else
        lexitcode=${exitcrit}
        lexitstring=${false}
    fi

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}

function file.isfile {
    #acceps 1 argument
    #1) path to file

    #local variables
    local lfile=${1} 

    #main
    file.exists ${lfile}
}

function file.issymlink {
    #acceps 1 argument
    #1) path to symlink

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lfile=${1}
    local lsymlink_target=""

    #main
    if [ -L ${lfile} ]; then
        lsymlink_target=`${cmd_readlink} ${lfile}`                                             #get target file/directory of symlink
        if [ `file.exist ${lsymlink_target}` -eq ${true} ]; then
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

function file.maxage {
    #accepts 2 args
    #1) path to file
    #2) maximum age of the file in days
    #returns boolean true/false
    
    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lfile=${1}
    local lmaxage=${2}
    local loutput=""

    #main
    if [ `file.exists ${lfile}` ]; then                                                             #ensure file exists
        loutput=`find "${lfile}" -mtime +${lmaxage} -print`                                         #get output maxage
        if [ ! -z ${loutput} ]; then
            lexitcode=${exitok}
            lexitstring=${true}
        else
            lexitcode=${exitcrit}
            lexitstring=${false}                                                                    #checks for variable$
    else
        lexitcode=${exitcrit}
        lexitstring=${false}
    fi

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}

function file.size {
    #accepts 1 arg
    #1) path to file
    #returns boolean true/false and exitcode

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lfile=${1}
    local lsize=0

    #main
    if [ `file.exist ${lfile}` -eq ${true} ]; then
        lsize=`${cmd_wc} -c < "${lfile}"`
        if [ ${?} -eq ${exitok} ]; then
            lexitcode=${exitok}
            lexitstring=${lsize}
        else
            exitcode=${exitcrit}
            exitstring=${-1}
        fi
    else
        lexitcode=${exitcrit}
        lexitstring=${-2}
    fi

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}

function file.stale {
    #accepts 2 arguments
    #1) path to file
    #2) maximum file age in days
    #returns boolean

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lfile=${1}
    local loutput=""
    local lmaxage=${2}

    #main
    if [ `file.isfile ${lfile}` -eq ${true} ]; then
        loutput=`${cmd_find} "${lfile}" -mtime +${lmaxage} -print`
        if [ ! -z ${loutput} ]; then
            lexitcode=${exitok}
            lexitstring=${true}
        else
            lexitcode=${lexitcrit}
            lexitstring=${false}
    else
        lexitcode=${lexitcrit}
        lexitstring=${false}
    fi

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitstring}
}

function file.symlink.validate {
    #accepts 1 arg
    #1) is path to simlink as string
    #returns boolean true/false

    #local variables
    local lfile=${1}

    file.issymlink ${lfile}
}