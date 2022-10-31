#date 20221013
#version=0.0.1

function help {
    echo you done messed up a-aron

    ${cmd_printf} '%-26s %-50s \n' "Argument" "Description"
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-dr" "--dryrun" "run without making any changes requires true/false" 
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-md" "--maxdisk" "set the flag for maximum disk size for error requires integer in bytes"
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-ml" "--maxlog" "set maximum individual log backup size.  requires an integer in bytes" 
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-ch" "--containerhead" "set the headspace, aka the amount of growth to allocate, default is 3 times image size.  requires and integer."
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-cb" "--containerbuffer" "set the bufferspace to allocate for delta between new images.  this is a percentage as a float 10%=.1.  requires a float/decimal"
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-o" "--output" "set the output to default table or optional json"
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-xe" "--exitonerror" "set flag to error out and exit when intel stage finds an error.  default is false. requires boolean true/false"
    ${cmd_printf} '%-3s | %-20s %-50s \n' "-h" "--help" "displays this menu"
}
function install {
    #accepts 1 arg.  1 short region name  return exit code

    local lsource=${1}
    local lfile=`${cmd_echo} ${lsource} | awk -F"/" '{print $NF}'`

    [ -d ${install_root}/hcgbu/bin ] && ${cmd_mkdir} -p ${install_root}/hcgbu/bin
    ${cmd_wget} ${lsource} -P ${install_root}/hcgbu/bin
    chmod +x ${install_root}/hcgbu/bin/${lfile}

    ${cmd_ln} -s ${install_root}/hcgbu/bin/${lfile} /etc/cron.daily/${lfile}.cron
}