function openssl.expire {

    local lnow_epoch=`${cmd_date} +"%s"`
    local lexitcode=${exitcrit}
    local lexitstring=""
    local ljson="{}"
    local lpath=${1}
    local lcert_expire_date=`${cmd_openssl} x509 -enddate -noout -in ${lpath} | ${cmd_awk} -F"=" '{print $2}'` 
    local lcert_expire_epoch=`${cmd_date} --date="${lcert_expire_date}" +"%s"`

    if [ ${lnow_epoch} -lt ${lcert_expire_epoch} ]; then
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.valid  |=.+ '${true}`
        lexit_code=${exitok}
    else
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.valid  |=.+ '${false}`
    fi

    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.path  |=.+ "'"${lpath}"'"'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.expire.date  |=.+ "'"${lcert_expire_date}"'"'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.expire.epoch  |=.+ "'"${lcert_expire_epoch}"'"'`
    ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.current.epoch  |=.+ "'"${lnow_epoch}"'"'`
  

    # output and exit
    lexitstring=`${cmd_echo} ${ljson} | ${cmd_jq} -c '.'`

    ${cmd_echo} "${lexitstring}"
    return ${exitcode}
}
