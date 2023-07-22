#date 20221013
#version=0.0.2


function file.exists {
    #accepts 1 arg, path to file. returns boolean true/false
    local lfile=${1}

    [ -f ${lfile} ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}
}
function file.maxage {
    #accepts 2 args, 1 path to file, maximum age of the file in days.  returns boolean true/false
    local lfile=${1}
    local lmaxage=${2}
    local loutput=""

    if [ `file.exists ${lfile}` ]; then                                                             #ensure file exists
        loutput=`find "${lfile}" -mtime +${lmaxage} -print`                                         #get output maxage
        [ ! -z ${loutput} ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}                          #checks for variable$
    else
        ${cmd_echo} ${false}
    fi
}
function file.size {
    #accepts 1 arg, path to file.  returns boolean true/false
    local lfile=${1}
    local lsize=0

    lsize=`${cmd_wc} -c < "${lfile}"`

    ${cmd_echo} ${lsize}
}
function file.symlink.validate {
    #accepts 1 arg.  1 is path to simlink as string.  returns boolean true/false
    local lsymlink=${1}
    local lsymlink_target=`${cmd_readlink} ${lsymlink}`                                             #get target file/directory of symlink

                                                                                                    #test target of symlink for being a file or directory and return true/false if exists
    [ -f ${lsymlink_target} ] | [ -d ${lsymlink_target} ] && ${cmd_echo} ${true} || ${cmd_echo} $false
}