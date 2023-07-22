#date 20221013
#version=0.0.1

function file.size {
        local lfile=${1}
        local lsize=0

        lsize=`${cmd_wc} -c < "${lfile}"`

        ${cmd_echo} ${lsize}
}
function file.symlink.validate {
        #accepts 1 arg.  1 is path to simlink as string.  returns boolean true/false
        local lsymlink=${1}
        local lsymlink_target=`${cmd_readlink} ${lsymlink}`                             #get target file/directory of symlink

                                                                                        #test target of symlink for being a file or directory and return true/false if exists
        [ -f ${lsymlink_target} ] | [ -d ${lsymlink_target} ] && echo ${true} || echo $false
}