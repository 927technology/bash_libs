#20220504
#version=0.0.1

function date.pretty {
    #accepts no args.  returns date in YYYY-MM-DD_HH:MM:SS
    ${cmd_date} +'%Y-%m-%d_%H:%M:%S'
}