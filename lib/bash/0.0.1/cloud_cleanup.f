#date 20221013
#version=0.0.1

function script.title {
    if [ "${output}" == "table" ]; then
        ${cmd_echo} --------------------------------------------------------------------------------
        ${cmd_printf} "%-2s %-40s %-36s\n"											                    \
                "${dry_run_marker}"																	    \
                "Cloud Cleanup:"																	    \
                "${build}"	
        ${cmd_printf} "%-2s %-40s %-36s\n"											                    \
                "${dry_run_marker}"																	    \
                "Syslog ID:"																	        \
                "${syslog_id}"	
        ${cmd_echo} --------------------------------------------------------------------------------
    fi
}

function script.title.settings {

    if [ "${output}" == "table" ]; then
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "dry run:" "${dry_run}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "plugins:" "${plugins}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "lib dir:" "${lib_dir}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "plugin dir:" "${plugin_dir}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "output:" "${output}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "command lib:" "${cmd_lib}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "syslog tag:" "${syslog_tag}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "date format:" "${date_format}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "syslog:" "${syslog}"
        ${cmd_printf} "%-2s %-15s %-10s \n"	"" "file log:" "${filelog}"
    fi
}

function script.validate.cmd_lib {

    #define local variables
    local lcmd=""
    local lexists=${false}
    local ljson="{}"
    local lpath=""
    local lvalidate=${false}
    local lvalidate_count=0
    local lexitcode=${exitcrit}

    #main
    if [ -f ${lib_dir}/bash/${lib_version}/${cmd_lib}.v ]; then
        i=0                                                                                         #initilize counter
        for command in `${cmd_cat} ${lib_dir}/bash/${lib_version}/${cmd_lib}.v | ${cmd_grep} -v ^#`; do  

            (( i++ ))                                                                               #increment counter
            ii=$(( ${i} - 1 ))                                                                      #set index
            lexists=${false}                                                                        #set variable default for loop

                                                                                                    #get command name and fail crit
            lcmd=`${cmd_echo} ${command} | ${cmd_awk} -F"=" '{print $1}' | ${cmd_awk} -F"_" '{print $NF}'` || { echo ${ljson}; exit ${exitcrit}; }
                                                                                                    #get command path and fail crit
            lpath=`${cmd_echo} ${command} | ${cmd_awk} -F"=" '{print $2}' | ${cmd_awk} -F" " '{print $1}'` || { echo ${ljson}; exit ${exitcrit}; }
                                                                                                    #validate binary existance
            [ -f ${lpath} ] &&  lexists=${true} || { lexists=${false}; (( lvalidate_count++ )); }
                                                                                                    #write json output and fail crit
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} -c '.validation.cmd['${ii}'] |=.+ {"name":"'${lcmd}'"}'` || { echo ${ljson}; exit ${exitcrit}; }
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} -c '.validation.cmd['${ii}'] |=.+ {"path":"'${lpath}'"}'` || { echo ${ljson}; exit ${exitcrit}; }
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} -c '.validation.cmd['${ii}'] |=.+ {"exists":'${lexists}'}'` || { echo ${ljson}; exit ${exitcrit}; }
        done

                                                                                                    #set ok exitcode if all binarys validate
        [ ${lvalidate_count} -eq 0 ] && { lexitcode=${exitok}; lvalidate=${true}; }
    fi
                                                                                                    #set validation json values and fail crit
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} -c '. |=.+ {"validate":'${lvalidate}'}'` || { echo ${ljson}; exit ${exitcrit}; }
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} -c '. |=.+ {"exceptions":'${lvalidate_count}'}'` || { echo ${ljson}; exit ${exitcrit}; }

                                                                                                    #output json and fail crit
    ${cmd_echo} ${ljson} | ${cmd_jq} -c  || { echo ${ljson}; exit ${exitcrit}; }
    exit ${lexitcode}
}

function script.validate.args {

    #define local variables
    local lexitcode=${exitcrit}

    #main
    while [ "${1}" != "" ]; do
        case ${1} in
            -cl | --cmd_lib)
                shift
                case ${1} in
                    centos | debian | mac | oracle) 
                        cmd_lib=cmd_${1} 
                        . ${lib_dir}/${cmd_lib}.v                   2>/dev/null || { echo missing ${cmd_lib}.v; exit -1; }
                    ;;
                esac
            ;;
            -dr | --dry_run)
                shift
                case ${1} in
                    true  | 1)  dry_run=1 ;;
                    false | 0)  dry_run=0 ;;
                    *)          ${0} -h; exit ${exitcrit}  ;;                                   #fail help
                esac
            ;;
            -lf | --log_file)
                shift
                [ "${1}" == "none" ] && filelog="" || filelog=${1}
            ;;
            -ls | --log_syslog)
                shift
                case ${1} in
                    true  | 1)  syslog=1 ;;
                    false | 0)  syslog=0 ;;
                    *)          ${0} -h; exit ${exitcrit}  ;;                                   #fail help
                esac
            ;;
            -lt | --syslog_tag)
                shift
                syslog_tag=${1}
            ;;
            -o | --output)
                shift
                case ${1} in
                    json | table) output=${1} ;;
                esac
            ;;
            -p | --plugins)
                shift
                plugins=${1}
            ;;
            -v | --version)
                ${cmd_echo} Cloud Cleanup: v${build}
                exit ${exitok}
            ;;
            -h | --help | *)
                ${cmd_echo} 

                ${cmd_printf} "%-2s %-60s \n" "" "cloud cleanup"
                ${cmd_echo} --------------------------------------------------------------------------------

                ${cmd_echo}

                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-cl" "--cmd_lib" "" "set the command library to use ex. -cl cmd_oracle"
                for lib in `${cmd_ls} ${lib_dir}/bash/${lib_version}/cmd_*.v | ${cmd_awk} -F"/" '{print $NF}' | ${cmd_awk} -F"." '{print $1}'`; do 
                    ${cmd_printf} "%-2s %-24s %-15s \n" "" "" "${lib}"
                done
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-dr" "--dry_run" "" "set dry run status"
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-h" "--help" "" "show this dialogue"
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-lf" "--log_file" "" "set run to log to a file path"
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-ls" "--log_syslog" "" "set run to use syslog"
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-lt" "--syslog_tag" "" "set the run to use this syslog tag"
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-o" "--output" "" "set the run to output json or table"
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-p" "--plugins" "" "select the plugins to for the run.  ex. -p docker,yum"
                for lib in `${cmd_ls} ../etc/cloud_cleanup/plugins/*.p | ${cmd_awk} -F"/" '{print $NF}' | ${cmd_awk} -F"." '{print $1}'`; do 
                    ${cmd_printf} "%-2s %-24s %-15s \n" "" "" "${lib}"
                done
                ${cmd_echo}
                ${cmd_printf} "%-2s %-3s | %-15s %-2s %-50s\n" "" "-v" "--version" "" "show the version of this tool"
                ${cmd_echo}

                exit ${exitok}
            ;;
        esac
        
        shift
    done
}

function script.validate.variables {
    #local variables
    local lerror_code=0
    local ljson="{}"
    local ldry_run_null=${false}
    local lodo_null=${false}
    local lsyslog_null=${false}
    local lverbose_null=${false}
    local lfile_log_null=${true}
    local llib_dir_null=${false}
    local lplugin_dir_null=${false}



    ##booleans
    [ ! -z ${dry_run} ]                                         && ldry_run_notempty=${true}        || ldry_run_notempty=${false}
    [ `is.datatype.boolean ${dry_run}` -eq ${true} ]            && ldry_run_type=${success}         || ldry_run_type=${failure}

    [ ! -z ${odo} ]                                             && lodo_notempty=${true}            || lodo_notempty=${false}
    [ `is.datatype.boolean ${odo}` -eq ${true} ]                && lodo_type=${success}             || lodo_type=${failure}

    [ ! -z ${syslog} ]                                          && ldry_run_notempty=${true}        || ldry_run_notempty=${false}
    [ `is.datatype.boolean ${syslog}` -eq ${true} ]             && lsyslog_type=${success}          || lsyslog_type=${failure}

    [ ! -z ${verbose} ]                                         && lverbose_notempty=${true}        || lverbose_notempty=${false}
    [ `is.datatype.boolean ${verbose}` -eq ${true} ]            && lverbose_type=${success}         || lverbose_type=${failure}

    ##strings

    ##strings - shell
    [ ! -z ${file_log} ]                                        && lfile_log_notempty=${true}       || lfile_log_notempty=${false}
    [ `is.datatype.string.shell ${file_log}` -eq ${true} ]      && lfile_log_type=${success}        || lfile_log_type${failure}
    [ -d ${file_log}]                                           && lfile_log_path=${success}        || lfile_log_path=${failure}
    

    [ ! -z ${lib_dir} ]                                         && llib_dir_notempty=${true}        || llib_dir_notempty=${false}
    [ `is.datatype.string.shell ${lib_dir}` -eq ${true} ]       && llib_dir_type=${success}         || llib_dir_type${failure}
    [ -d ${lib_dir}]                                            && llib_dir_path=${success}         || llib_dir_path=${failure}

    [ ! -z ${plugin_dir} ]                                      && lplugin_dir_notempty=${true}     || lplugin_dir_notempty=${false}
    [ `is.datatype.string.shell ${plugin_dir}` -eq ${true} ]    && lplugin_dir_type=${success}      || lplugin_dir_type=${failure}
    [ -d ${plugin_dir}]                                         && lplugin_dir_path=${success}      || lplugin_dir_path=${failure}






    #dry_run=1                                                                                           #1=enable 0=disable; enable dry_run precautions
    plugins=docker
    #,storage,docker,services,file_cleanup,yum                                                          #comma seperated list of plugins to run
    #lib_dir=/opt/hcgbu/lib 
    #lib_version=0.0.1                                                                                   #version of libraries to use
    #plugin_dir=/opt/hcgbu/etc/cloud_cleanup/plugins                                                     #path to plugins.  relative from script bin folder or full path
    output=table                                                                                        #output type table or json
    cmd_lib=cmd_centos
    syslog_tag=hcgbuops                                                                                 #cmd for enterprise linux, cmd_mac for mac
    date_format='+%Y%m%d-%H%M%S'                                                                        #format for date output
    #syslog=1                                                                                            #1=enable 0/comment=disable; enable logging to syslog
    #filelog=../var/log                                                                                  #specify path to file log or leave blank/comment for no file logging
    #odo=0
    #verbose=1 
}