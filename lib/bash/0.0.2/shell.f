#20220629
#build=0.2.1

function shell.check.binary {
    #20220629
    #changed binary calls to variables

    local lname=${1}                                                                                #binary name

    ${cmd_which} ${lname} 2>&1 > /dev/null                                                          #check path for bina$
    [ ${?} -eq ${exitok} ] && ${cmd_echo} ${true} || ${cmd_echo} ${false}
}
function shell.dependancy.check {
    #accepts global variable dependacies which is csv formatted unquoted string
    #of names of binaries, the binaries must be reachable from withing the users
    #$PATH.  full path is not accepted because shell.check.binary uses the "which"
    #command to determine availability

    # ex: dependacies=jq,git

    #20220629
    #accepts 1 arg of output.  legacy or bool.  verbose outputs legacy output, 
    #bool only returns true/false if all passed.


    local loutput_type=legacy
    [ ! -z ${1} ] && local loutput_type=`shell.lcase ${1}`

    case ${loutput_type} in 
        bool)
            local lexitcode=${false}                                                                #always fail closed
            local lerrcount=0                                                                       #set error count to 0

            for dependancy in `${cmd_echo} ${dependacies} | ${cmd_sed} 's/,/\ /g'`; do              #check for dependancies
                [ `shell.check.binary ${dependancy}` -eq ${false} ] && (( lerrcount++ ))            #increment errcount on failures
            done

            [ ${lerrcount} -eq 0 ] && lexitcode=${true}                                             #exit code becomes true only if no failures 

            ${cmd_echo} ${lexitcode}
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
        ;;
    esac
}
function shell.directory.size {
    #accepts 1 arg for directory path, returns json of exists, path, and size
    #20220908

    local lexists=${false}
    local ljson="{}"
    local lpath=${1}
    local lsize=0

    [ `shell.directory.exists ${lpath}` -eq ${true} ] && { lexists=${true}; lsize=`${cmd_du} -s ${path} | awk '{print $1}'`; }

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '. |=.+ {"exists":"'${lexists}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '. |=.+ {"path":"'${lpath}'"}'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '. |=.+ {"sizeB":"'${lsize}'"}'`

    ${cmd_echo} ${ljson}
}
function shell.diskspace {
        #accepts 0 args retruns json string of diskspace from df -h
        local ldiskspace=`${cmd_df} -h | ${cmd_tail} -n +2 | ${cmd_sed} 's/  */ /g' | ${cmd_sed} 's/%//g' | ${cmd_jq} --raw-input --slurp 'split("\n") | map(split(" ")) | .[0:-1] | map( { "filesystem":.[0],"size":.[1],"used":.[2],"avail":.[3],"use":.[4],"mount":.[5] } )'`

        echo ${ldiskspace}
}
function shell.directory.exists {
    local ldirectory=${1}                                                                   #full path t$
    [ -d ${ldirectory} ] && echo ${true} || echo ${false}
}
function shell.file.exists {
    local lfile=${1}
    [ -f ${lfile} ] && echo ${true} || echo ${false}
}
function shell.file.stale {
    local lfile=${1}                                                                        #ful$
    local lmaxage=${2}                                                                      #max$

    if [ `shell.file.exists ${lfile}` ]; then                                               #ensure file exists
            local loutput=`find "${lfile}" -mtime +${lmaxage} -print`                       #receives input if f$
            [ ! -z ${loutput} ] && echo ${true} || echo ${false}                            #checks for variable$
    else
            echo ${false}                                                                   #exi$
    fi
}
function shell.get {
    #accepts 0 args.  returns shell binary

    ${cmd_cat} /proc/$$/cmdline
}
function shell.lcase {
    ##depricated.  replaced with test.lcase
    test.lcase ${1}    
}
function shell.log {
    #accepts 1 arg as quoted string.  returns string.
    local lstring=${1}
    local ldate=`date.pretty`

    ${cmd_echo} ${ldate} - ${lstring}                                               #output string to screen

                                                                                    #output string to syslog
    [ -z ${syslog_tag} ] && ${cmd_logger} ${lstring} || ${cmd_logger} -t ${syslog_tag} ${lstring}                                                       
}
function shell.log.screen {
    #accepts 1 arg as quoted string.  returns string.
    local lstring=${1}
    local ldate=`date.pretty`

    ${cmd_echo} ${ldate} - ${lstring}                                               #output string to screen                                                    
}
function shell.null {
    cat /dev/null
}
function shell.log.syslog {
    #accepts 1 arg as quoted string.  sends log message to syslog
    local lstring=${1}
                                                                                    #output string to syslog
    [ -z ${syslog_tag} ] && ${cmd_logger} ${lstring} || ${cmd_logger} -t ${syslog_tag} ${lstring}                                                       
}
function shell.ucase {
    #depricated.  replaced with text.ucase

    shell.ucase ${1}
}
function shell.validate.package {
        #accepts 2 args.  1 is the package name 2 is the package manager e.g. rpm.  returns boolean true/false
        local lpackage_name=${1}
        local lpackage_manager=${2}
        local lpackage_installed=${false}

        case ${lpackage_manager} in
                rpm) [ ! -z `${cmd_rpm} -qa ${package}` ] && lpackage_installed=${true} ;;
                deb) 
                    ${cmd_dpkg} -V ${package}                                                       > /dev/null 2>&1
                    case ${?} in
                        ${exitok}) lpackage_installed=${true} ;;
                    esac
                ;;
        esac

        ${cmd_echo} ${lpackage_installed}
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