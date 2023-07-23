function text.lcase {
    #acceprs 1 argument
    #1) string to convert to lower case

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lstring=${1}

    #main
    lexitstring=`${lstring} | ${cmd_awk} '{print tolower($1)}'`
    if [ ${?} -eq ${exitok} ]; then
        lexitcode=${exitok}
    else
        lexitcode=${exitcrit}
        lexitstring=${lstring}
    else

    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}
function text.ucase {
    #acceprs 1 argument
    #1) string to convert to upper case

    #local variables
    local lexitcode=${exitcrit}
    local lexitstring=""
    local lstring=${1}

    #main
    lexitstring=`${lstring} | ${cmd_awk} '{print toupper($1)}'`
    if [ ${?} -eq ${exitok} ]; then
        lexitcode=${exitok}
    else
        lexitcode=${exitcrit}
        lexitstring=${lstring}
    else

    #bye bye
    ${cmd_echo} ${lexitstring}
    return ${lexitcode}
}