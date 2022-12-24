function text.lcase {
    #acceprs 1 arg.  returns lowercase of arg.
    local lstring=${1}

    ${cmd_echo} ${lstring} | ${cmd_awk} '{print tolower($1)}'
}
function text.ucase {
    #acceprs 1 arg.  returns uppercase of arg.
    local lstring=${1}

    ${cmd_echo} ${lstring} | ${cmd_awk} '{print toupper($1)}'
}
