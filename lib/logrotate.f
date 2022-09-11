#20220504
#build=0.0.2

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
    local ljson=""

    #output configs
    for record in `seq 1 ${#lfile[@]}`; do
        ljson="{\"config\":\"${lconfig_file}\",\"file\":\"${lfile[$record]}\",\"frequency\":\"${lfrequency[$record]}\",\"missingok\":${lmissingok[$record]},\"rotate\":${lrotate[$record]},\"compress\":${lcompress[$record]},\"notifempty\":${lnotifempty[$record]},\"dateext\":${ldateext[$record]},\"maxage\":${lmaxage[$record]},\"dateformat\":\"${ldateformat[$record]}\",\"extension\":\"${lextension[$record]}\",\"mode\":${lcreate_mode[$record]},\"owner\":\"${lcreate_owner[$record]}\",\"group\":\"${lcreate_group[$record]}\"}"
    
        [ ${record} -gt 1 ] && loutput=${loutput},
        loutput=${loutput}${ljson}
    done

    echo "${loutput}"
}