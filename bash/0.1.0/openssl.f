#20230723
#build=0.1.0

function openssl.expire {
    #accepts 1 argument
    #1) path to certificate
    #returns json

    #local variables
    local lnow_epoch=`${cmd_date} +"%s"`
    local lexitcode=${exitcrit}
    local lexitstring=""
    local ljson="{}"
    local lfile=${1}
    local lcert_expire_date=""
    local lcert_expire_epoch=""

    #main
    if [ `file.exists ${lfile}` -eq ${true} ]; then
        lcert_expire_date=`${cmd_openssl} x509 -enddate -noout -in ${lfile} | ${cmd_awk} -F"=" '{print $2}'` 
        lcert_expire_epoch=`${cmd_date} --date="${lcert_expire_date}" +"%s"`
        
        if [ ${lnow_epoch} -lt ${lcert_expire_epoch} ]; then
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.valid  |=.+ '${true}`
            lexitcode=${exitok}
        else
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.valid  |=.+ '${false}`
            lexitcode=${exitcrit}
        fi
    fi

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.exist  |=.+ '${lexitcode}`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.path  |=.+ "'"${lfile}"'"'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.expire.date  |=.+ "'"${lcert_expire_date}"'"'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.expire.epoch  |=.+ '${lcert_expire_epoch}`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.current.epoch  |=.+ '${lnow_epoch}`
  
    # output and exit
    lexitstring=`${cmd_echo} ${ljson} | ${cmd_jq} -c '.'`

    #bye bye
    ${cmd_echo} "${lexitstring}"
    return ${exitcode}
}