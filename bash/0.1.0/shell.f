#20230723
#build=0.1.0

function shell.check.binary {
    #accepts 1 argument
    #1) name of the binary

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=${false}
    local lname=${1}                                                                                #binary name

    #main
    ${cmd_which} ${lname} 2>&1 > /dev/null                                                          #check path for bina$
    if [ ${?} -eq ${exitok} ]; then
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

function shell.dependancy.check {
    #accepts global variable dependacies which is csv formatted unquoted string
    #of names of binaries, the binaries must be reachable from withing the users
    #$PATH.  full path is not accepted because shell.check.binary uses the "which"
    #command to determine availability

    # ex: dependacies=jq,git

    #accepts 1 argument
    #1) type of output.  legacy or bool.  
    #verbose outputs legacy output, bool only returns true/false if all passed.

    #local variables
    local lerrorcount=0
    local lexitcode=${exitcrit}
    local lexitstring=""
    local loutput_type=${1}
    
    #main
    if [ ! -z ${loutput_type} ]; then
        loutput_type=`shell.lcase ${1}`
    else
        loutput_type=legacy
    fi

    case ${loutput_type} in 
        bool)
            for dependancy in `${cmd_echo} ${dependacies} | ${cmd_sed} 's/,/\ /g'`; do              #check for dependancies
                if [ `shell.check.binary ${dependancy}` -eq ${false} ]; then
                    (( lerrcount++ ))                                                               #increment errcount on failures
                fi
            done

            if [ ${lerrcount} -eq 0 ]; then
                lexitcode=${exitok}                                                                 #exit code becomes true only if no failures 
                lexitstring=${true}
            else
                lexitcode=${exitcrit}
                lexitstring=${false}
            fi


            #bye,bye
            ${cmd_echo} ${lexitstring}
            return ${exitcode}
        ;;
        legacy)
            for dependancy in `echo ${dependacies} | sed 's/,/\ /g'`; do                       		#check for dependancies
                    if [ `shell.check.binary ${dependancy}` -eq ${true} ]; then
                            printf '| %-25s %-50s | \n' "${dependancy}" "present"
                    else
                            printf '| %-25s %-50s | \n' "${dependancy}" "missing"
                            (( dep_err++ ))															#increment error count	
                    fi
            done

            if [ ${dep_error} -gt 0 ]; then
                lexitcode=${exitcrit}
            fi

            return ${exitcode}
        ;;
    esac
}

function shell.directory.size {
    #accepts 1 argument
    #1) directory path
    #returns json

    #local variables
    local lexitcode=${exitcrit}
    local lexist=${false}
    local ljson="{}"
    local lpath=${1}
    local lsize=0

    #main
    if [ `file.isdirectory ${lpath}` -eq ${true} ]; then
        lexist=${true}
        lsize=`${cmd_du} -s ${path} | ${cmd_awk} '{print $1}'`
        lexitcode=${exitok}
    fi

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.exist     |=.+ '${lexist}`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.exitcode  |=.+ '${lexitcode}`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.path      |=.+ "'"${lpath}"'"'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.sizeB     |=.+ '${lsize}`

    #bye bye
    ${cmd_echo} ${ljson}
    return ${lexitcode}
}

function shell.diskspace {
    #accepts 0 arguments
    #returns json

    #local variables
    local ljson="{}"
    local lexitcode=${exitcrit}
    local lexitstring=""

    #main
    ljson=`${cmd_df} -h | ${cmd_tail} -n +2 | ${cmd_sed} 's/  */ /g' | ${cmd_sed} 's/%//g' | ${cmd_jq} --raw-input --slurp 'split("\n") | map(split(" ")) | .[0:-1] | map( { "filesystem":.[0],"size":.[1],"used":.[2],"avail":.[3],"use":.[4],"mount":.[5] } )'`
    if [ ${?} -eq ${exitok} ]; then     
        lexitcode=${exitok}
    else
        lexitcode=${exitcrit}
        ljson="{}"
    fi

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.exitcode  |=.+ '${lexitcode}`
    lexitstring="${ljson}"

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitstring}
}

function shell.directory.exists {
    #accepts 1 argument
    #1) path to directory

    #local variables
    local lfile=${1}

    #main
    file.isdirectory ${lfile}
}

function shell.file.exists {
    #accepts 1 argument
    #1) path to file

    #local variables
    local lfile=${1}

    #main
    file.isfile ${lfile}
}

function shell.file.stale {
    #accepts 2 arguments
    #1) path to file
    #2) maximum file age in days
    #returns boolean

    #local variables
    local lstring=${1}
    local lmaxage=${2}

    #main
    text.stale ${lstring} ${lmaxage}
    return ${?}
}

function shell.get {
    #accepts 0 arguments
    #returns name of current shell

    ${cmd_cat} /proc/${$}/cmdline
}

function shell.lcase {
    #acceprs 1 argument
    #1) string to convert to lower case

    #local variables
    local lstring=${1}

    #main
    text.lcase ${lstring}
    return ${?}
}

function shell.log {
    #requires global variable of syslog_tag or will log as root
    #accepts 1 argument as quoted string
    #returns timestamp string to screen and syslog

    #local variables
    local lerror_count=0
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lstring=${1}

    #main
    shell.log.screen "${lstring}"
    if [ ${?} -eq ${exitcrit} ]; then
        $(( error_count++ ))
    fi

    shell.log.syslog "${lstring}"
    if [ ${?} -eq ${exitcrit} ]; then
        $(( error_count++ ))
    fi

    if [ ${lerror_count} -gt 0 ]; then
        lerrorcode=${lexitcrit}
    else
        lerrorcode=${lexitok}
    fi

    #bye bye
    return ${lexitcode}
}

function shell.log.screen {
    #requires global variable of syslog_tag or will log as root
    #accepts 1 argument as quoted string
    #returns timestamp string to screen

    #local variables
    local lerror_count=0
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lstring=${1}
    local ldate=""

    #main
    ldate=`date.pretty`
    if [ ${?} -eq ${exitcrit} ]; then
        $(( error_count++ ))
    fi

    lexitstring="${ldate} - ${lstring}"                                                             #output string to screen

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}

function shell.null {
    #accepts 0 arguments
    #returns null value
    
    #main
    ${cmd_cat} /dev/null
}

function shell.log.syslog {
    #requires global variable of syslog_tag or will log as root
    #accepts 1 argument as quoted string
    #returns timestamp string syslog

    #local variables
    local lerror_count=0
    local lexitcode=${exitcrit}
    local lstring=${1}
    local ldate=""

    #main
    ldate=`date.pretty`
    if [ ${?} -eq ${exitcrit} ]; then
        $(( error_count++ ))
    fi

                                                                                                    #output string to syslog
    if [ -z ${syslog_tag} ]; then
        ${cmd_logger} ${lstring}
        if [ ${?} -eq ${exitcrit} ]; then
            $(( lerror_count++ ))
        fi
    else
        ${cmd_logger} -t ${syslog_tag} ${lstring}
        if [ ${?} -eq ${exitcrit} ]; then
            $(( lerror_count++ ))
        fi
    fi

    if [ ${lerror_count} -gt 0 ]; then
        lerrorcode=${lexitcrit}
    else
        lerrorcode=${lexitok}
    fi

    #bye bye
    return ${lexitcode}                                                    
}

function shell.ucase {
    #acceprs 1 argument
    #1) string to convert to upper case

    #local variables
    local lstring=${1}

    #main
    text.ucase ${lstring}
    return ${?}
}

function shell.validate.package {
    #accepts 2 arguments
    #1) is the package name 
    #2) is the package manager e.g. rpm.  
    #returns boolean

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lname=${1}
    local lmanager=${2}
    local linstalled=${false}

    case ${manager} in
            apt)
                linstalled=`${cmd_apt} list --installed 2> /dev/null | ${cmd_grep} ${lname} 2>&1> /dev/null`
                if [ ${?} -eq ${exitok} ]; then
                    lexitcode=${exitok}
                    lexitstring=${true}
                else
                    lexitcode=${exitcrit}
                    lexitstring=${false}
                fi                      
            ;;
            rpm) 
                linstalled=`${cmd_rpm} -qa ${lname}`
                if [ ${?} -eq ${exitok} ]; then
                    lexitcode=${exitok}
                    lexitstring=${true}
                else
                    lexitcode=${exitcrit}
                    lexitstring=${false}
                fi                   
            ;;
            *) 
                    shell.log "the package manager for ${lmanager} is not supported"
                    exit ${exitcrit}
            ;;
    esac

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}