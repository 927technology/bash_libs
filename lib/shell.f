function shell.binarey.check {
    #placeholder for misnamed function shell.check.binary

    shell.check.binary ${@}                                                                         #send all args to function
}
function shell.check.binary {
    local lname=${1}                                                                                #binary name

    ${cmd_which} ${lname} 2>&1 > /dev/null                                                          #check path for bina$
    [ ${?} -eq ${exitok} ] && echo ${true} || echo ${false}
}
function shell.dependancy.check {
    #accepts global variable dependacies which is csv formatted unquoted string
    #of names of binaries, the binaries must be reachable from withing the users
    #$PATH.  full path is not accepted because shell.check.binary uses the "which"
    #command to determine availability

    # ex: dependacies=jq,git

    for dependancy in `${cmd_echo} ${dependacies} | ${cmd_sed} 's/,/\ /g'`; do        		        #check for dependancies
        if [ `shell.check.binary ${dependancy}` -eq ${true} ]; then
            ${cmd_printf} '| %-25s %-50s | \n' "${dependancy}" "present"
        else
            ${cmd_printf} '| %-25s %-50s | \n' "${dependancy}" "missing"
            (( dep_err++ ))							                                                #increment error count	
        fi
    done
}
function shell.directory.exists {
        local ldirectory=${1}                                                                       #full path t$
        [ -d ${ldirectory} ] && echo ${true} || echo ${false}
}
function shell.diskspace {
    #accepts 0 args retruns json string of diskspace from df -h
    local ldiskspace=`${cmd_df} -h | ${cmd_sed} 's/  */ /g' | ${cmd_sed} 's/%//g' | ${cmd_jq} --raw-input --slurp 'split("\n") | map(split(" ")) | .[0:-1] | map( { "filesystem":.[0],"size":.[1],"used":.[2],"avail":.[3],"use":.[4],"mount":.[5] } )' | jq -c '.[]'`

    echo ${ldiskspace}
}
function shell.file.exists {
    local lfile=${1}
    [ -f ${lfile} ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}
}
function shell.file.stale {
    local lfile=${1}                                                                                #full path to file
    local lmaxage=${2}                                                                              #max file age

    if [ `shell.file.exists ${lfile}` ]; then                                                       #ensure file exists
        local loutput=`find "${lfile}" -mtime +${lmaxage} -print`                                   #receives input if f$
        [ ! -z ${loutput} ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}                          #checks for variable existance
    else
        ${cmd_echo} ${false}
    fi
}
function shell.null {
    ${cmd_cat} /dev/null
}
function shell.validate.package {
    #accepts 2 args.  1 is the package name 2 is the package manager e.g. rpm.  returns boolean true/false
    local lpackage_name=${1}
    local lpackage_manager=${2}

    case ${lpackage_manager} in
        rpm) local lpackage_installed=`${cmd_rpm} -qa ${package}` ;;
        *) 
                shell.log "the package manager for ${lpackage_manager} is not supported"
                exit ${exitcrit}
        ;;
    esac

    [ -z ${lpackage_installed} ] && ${cmd_echo} ${false} || ${cmd_echo} ${true}
}
function shell.lcase {
    #acceprs 1 arg.  returns lowercase of arg.
    local lstring=${1}

    ${cmd_echo} ${lstring} | ${cmd_awk} '{print tolower($1)}'
}
function shell.log {
    #accepts 1 arg as quoted string.  returns string, and logs to syslog
    local lstring=${1}
    local ldate=`date.pretty`

    ${cmd_echo} ${ldate} - ${lstring}                                                               #output string to screen

                                                                                                    #output string to syslog
    [ -z ${syslog_tag} ] && ${cmd_logger} ${lstring} || ${cmd_logger} -t ${syslog_tag} ${lstring}                                                       
}
function shell.log.screen {
    #accepts 1 arg as quoted string.  returns string.
    local lstring=${1}
    local ldate=`date.pretty`

    ${cmd_echo} ${ldate} - ${lstring}                                                               #output string to screen                                                    
}
function shell.log.syslog {
    #accepts 1 arg as quoted string.  sends log message to syslog
    local lstring=${1}
                                                                                                    #output string to syslog
    [ -z ${syslog_tag} ] && ${cmd_logger} ${lstring} || ${cmd_logger} -t ${syslog_tag} ${lstring}                                                       
}
function shell.validate.variable {
    #accepts 1 arg as variable contents
    local lvariable=${1}

    if [ -z ${lvariable} ]; then
            lexitstring=${false}
    else  
            lexitstring=${true}
    fi
    ${cmd_echo} ${lexitstring}
}
function shell.ucase {
    #acceprs 1 arg.  returns lowercase of arg.
    local lstring=${1}

    ${cmd_echo} ${lstring} | ${cmd_awk} '{print toupper($1)}'
}