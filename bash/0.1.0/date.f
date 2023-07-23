#20230723
#version=0.1.0

function date.pretty {
    #accepts no args.  returns date in YYYY-MM-DD_HH:MM:SS
    ${cmd_date} +'%Y-%m-%d_%H:%M:%S'
}