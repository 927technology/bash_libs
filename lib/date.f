#20220504
#build=0.0.2

function date.pretty {
    #accepts no args.  returns date in YYYY-MM-DD_HH:MM:SS
    ${cmd_date} +'%Y-%m-%d_%H:%M:%S'
}