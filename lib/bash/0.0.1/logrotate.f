#20220921
#build=0.0.1

function logrotate.files {
    local lfile_size=0
    local ljson=${1}
    local lpath=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.path'`
    local lrotate=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.rotate'`
    local lrotate_error=${true}


    [ -z ${lrotate} ] && lrotate=0

    i=0
    if [ -f ${lpath} ]; then
        for file in `${cmd_ls} -t ${lpath}* | ${cmd_grep} ${lpath}[.]`; do
            (( i++ ))
            ii=$(( ${i} - 1 ))
            lfile_size=0                                                                            #reset size counter

            if [ "${file}" != "null" ]; then
                lfile_size=`file.size "${file}"`
                ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.files['${ii}'] |=.+ {"path":"'${file}'"}'`
                ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.data.files['${ii}'] |=.+ {"sizeB":"'${lfile_size}'"}'`
            fi
        done
    fi

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}

function logrotate.report {

    #local variables
    local lfrequency=""
    local ljson="{}"
    local llogrotate_json=""
    local llogrotate_path=/etc/logrotate.d

    declare -a llogrotate_data=""

    oldifs=${IFS}                                                                                   #ifs is a pain
    

    #list all configuration files
                                                                                                    #start counter
    i=0 
    for file in `${cmd_find} ${llogrotate_path}/ -maxdepth 1 -type f`; do

        llogrotate_data=""                                                                          #zero out variable
        lfrequency=""
        llogrotate_json=""
                                                                                                    #ensure no empty variables
        if [ ! -z ${file} ]; then
                                                                                                    
            (( i++ ))                                                                               #increment counter
            ii=$(( ${i} - 1 ))                                                                      #set index
            llogrotate_data=""                                                                      #zero out array
                                                                                                    #add config file to json
            ljson=`${cmd_echo} "${ljson}" | jq '.data.files['${ii}'] |=.+ {"configuration_file":"'${file}'"}'`

            #parse each stanza in the file
            j=0
            IFS='}'                                                                                 #set delimiter to }
                                                                                                    #flatten configuration file and loop
            for stanza in `cat ${file} | ${cmd_grep} -v \# | ${cmd_sed} 's/{//g' | sed 's/\n/\ /g'`; do
                (( j++ ))                                                                           #increment counter
                jj=$(( ${j} - 1 ))                                                                  #set index
                                                                                                    #set config parameters into an array to preserve 
                                                                                                    #the spacing needed for the function arguments
                if [ ! -z ${stanza} ]; then
                    llogrotate_data[j]=${stanza}
                fi
            done 
            IFS=${oldifs}                                                                           #because we return things where we found them
                                                                                                    #loop stanzas and place them in json
            for k in `${cmd_seq} 1 ${j}`; do
                kk=$(( ${k} -1 ))
                llogrotate_json=`logrotate.parse.config.string ${llogrotate_data[$k]}`
                ljson=`${cmd_echo} "${ljson}" | jq '.data.files['${ii}'].configs['${kk}'] |=.+ '${llogrotate_json}`
                ljson=`${cmd_echo} "${ljson}" | jq '.data.files['${ii}'].configs['${kk}'] |=.+ {"index":"'${kk}'"}'`
            done
        fi
    done
    
    ${cmd_echo} ${ljson} | ${cmd_jq} -c
    }


function logrotate.config.parse {
    #accepts 2 args.  1 the name of the configuration file NOT the path, 2 text stream of logrotate file.  can be accomplished by using cat of the file into the function.  returns json array of configuration

    local lconfig_file="${1}"                                                                       #name of configuration file without path
    local lstring="${2}"                                                                            #quoted string value of the contents of the configuration file

    #turn logrotate file into parsable format <file> { <config1> } | <file2> { <config> } pipe delimited
    local lfull=`${cmd_echo} "${lstring}" | ${cmd_sed} 's/    */,/g' | ${cmd_tr} --delete '\n' | ${cmd_sed} 's/\}/\n/g' | ${cmd_sed} 's/, *fi/; fi/g' | ${cmd_sed} 's/then,,/then /g' | ${cmd_sed} 's/postrotate,/postrotate /g'`
  
    local loldifs=${IFS}                                                                            #ifs sucks
    IFS=$'\n'                                                                                       #set ifs to newline from default space

    local -a lfile                                                                                  #declare array - path to config file
    local -a lsettings                                                                              #declare array - ??  is this used
    local -a lfrequency                                                                             #declare array - frequency of log rotation year, month, day
    local -a lmissingok                                                                             #declare array - do not err on missing file
    local -a lrotate                                                                                #declare array - number of copies to backup before overwriting
    local -a lcompress                                                                              #declare array - compress backups
    local -a lnotifempty                                                                            #declare array - rotate even if file is empty
    local -a ldateext                                                                               #declare array - add date extension to backups
    local -a lmaxage                                                                                #declare array - remove logs older than X days
    local -a ldateformat                                                                            #declare array - date format to use in the log
    local -a lextension                                                                             #declare array - file extension to put on the log file, typically .log
    local -a lcreate_mode                                                                           #declare array - mode permissions on file
    local -a lcreate_owner                                                                          #declare array - file owner
    local -a lcreate_group                                                                          #declare array - file group
    #local -a lpostrotate                                                                            #declare array - postrotate tasks, not implemented for complexity.

    local i=0                                                                                       #zero out counter
    for lstanza in `${cmd_echo} "${lfull}"`; do 
        IFS=,                                                                                       #set ifs to ,
        (( i++ ))                                                                                   #increment counter

        #set default variable values
        lfile[i]=${false}
        lfrequency[i]=${false}
        lmissingok[i]=${false}
        lrotate[i]=${false}
        lcompress[i]=${false}
        lnotifempty[i]=${false}
        ldateext[i]=${false}
        lmaxage[i]=${false}
        ldateformat[i]=${false}
        lextension[i]=${false}
        lcreate_mode[i]=${false}
        lcreate_owner[i]=${false}
        lcreate_group[i]=${false}

        for lconfig in `${cmd_echo} "${lstanza}"`; do
            lfile[i]=`${cmd_echo} ${lstanza} | ${cmd_awk} -F" {" '{print $1}' | awk -F" " '{print $1}'`
            lsettings[i]=`${cmd_echo} ${lstanza} | ${cmd_awk} -F" {" '{print $1}' | ${cmd_sed} 's/}$//g'`

            case ${lconfig} in
                #file
                '/'*) lfile[i]=${lconfig} ;; 
                #frequency
                hourly) lfrequency[i]=h ;;
                weekly) lfrequency[i]=w ;;
                monthly) lfrequency[i]=m ;;
                yearly) lfrequency[i]=y ;;
                #missingok
                missingok) lmissingok[i]=${true} ;;
                #rotate
                rotate*) lrotate[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $2}'` ;;
                #compress
                compress) lcompress[i]=${true} ;;
                #notifempty
                notifempty) lnotifempty[i]=${true} ;;
                #dateext
                dateext) ldateext[i]=${true} ;;
                #maxage
                maxage*) lmaxage[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $2}'` ;;
                #dateformat
                dateformat*) ldateformat[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $2}'` ;;
                #extension
                extension*) lextension[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $2}'` ;;
                #create
                create*) 
                    lcreate_mode[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $2}'`
                    lcreate_owner[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $3}'`
                    lcreate_group[i]=`${cmd_echo} ${lconfig} | ${cmd_awk} '{print $4}'`
                ;;
                #postrotate
            esac
        done
    done

    IFS=${loldifs}                                                                                  #because we return things to where we found them

    local loutput=""
    local ljson="{}"

    #output configs
    for record in `seq 1 ${#lfile[@]}`; do
        ljson="{\"config\":\"${lconfig_file}\",\"file\":\"${lfile[$record]}\",\"frequency\":\"${lfrequency[$record]}\",\"missingok\":${lmissingok[$record]},\"rotate\":${lrotate[$record]},\"compress\":${lcompress[$record]},\"notifempty\":${lnotifempty[$record]},\"dateext\":${ldateext[$record]},\"maxage\":${lmaxage[$record]},\"dateformat\":\"${ldateformat[$record]}\",\"extension\":\"${lextension[$record]}\",\"mode\":${lcreate_mode[$record]},\"owner\":\"${lcreate_owner[$record]}\",\"group\":\"${lcreate_group[$record]}\"}"
    
        [ ${record} -gt 1 ] && loutput=${loutput},
        loutput=${loutput}${ljson}
    done

    echo "${loutput}"
}

function logrotate.parse.config.string {
    #accepts a string of space delimited values from the logrotate.d config file. 
    #one config per line

    #local variables
    local lfrequency=""
    local lrotate=""
    local lcompress=""
    local ldelaycompress=""
    local lmissingok=""
    local lnotifempty=""
    local lcreate_group=""
    local lcreate_mode=""
    local lcreate_owner=""
    local ljson="{}"

    i=0

    #main
    while [ "${1}" != "" ]; do
        case ${1} in
            /*)
                if [ `${cmd_echo} ${1} | ${cmd_grep} -c /dev` -eq 0 ] && [ `${cmd_echo} ${1} | ${cmd_grep} -c /bin` -eq 0 ]; then
                    (( i++ ))                                                                       #increment counter
                    ii=$(( ${i} - 1 ))                                                              #set index

                    ljson=`${cmd_echo} "${ljson}" | ${cmd_jq} '.logpaths['${ii}'] |=.+ {"path":"'${1}'"}'`
                fi
            ;;
            compress) lcompress=${true} ;;
            create)
                shift
                lcreate_mode=${1}
                shift
                lcreate_owner=${1}
                shift
                lcreate_group=${1}
            ;;
            delaycompress) ldelaycompress=${true} ;;

            #frequency
            daily) lfrequency=d ;;
            hourly) lfrequency=h ;;
            monthly) lfrequency=m ;;
            weekly) lfrequency=w ;;
            yearly) lfrequency=y ;;

            missingok) lmissingok=${true} ;;
            notifempty) lnotifempty=${true} ;;
            rotate) 
                shift
                lrotate=${1}
            ;;
        esac

        shift
    done

    ljson=`${cmd_echo} "${ljson}" | jq '. |=.+ {"compress":"'${lcompress}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '.create |=.+ {"mode":"'${lcreate_mode}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '.create |=.+ {"owner":"'${lcreate_owner}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '.create |=.+ {"group":"'${lcreate_group}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '. |=.+ {"delaycompress":"'${ldelaycompress}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '. |=.+ {"frequency":"'${lfrequency}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '. |=.+ {"missingok":"'${lmissingok}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '. |=.+ {"notifempty":"'${lnotifempty}'"}'`
    ljson=`${cmd_echo} "${ljson}" | jq '. |=.+ {"rotate":"'${lrotate}'"}'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}