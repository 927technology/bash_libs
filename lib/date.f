function date.pretty {
        #accepts no args.  returns date in YYYY-MM-DD_HH:MM:SS
        ${cmd_date} +'%Y-%m-%d_%H:%M:%S'
}
function date.today {
        #accepts no args.  returns date in YYYYMMDD format
        ${cmd_date} +'%Y%m%d'
}