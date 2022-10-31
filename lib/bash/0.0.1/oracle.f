#20220504
#build=0.0.1

function oracle.update.os.get {
    #accepts 0 args, returns os-updater status as json string

    local lstatus_json=`${cmd_os_updater} --status --json 2>/dev/null`

    ${cmd_echo} ${lstatus_json}
}
function oracle.update.os.apply {
    #accepts 0 args, returns no output.  applys latest available patch as configured is os-updater and reboots

    local lstatus_json=`oracle.udpdate.os.get`

    local lstatus_applied=`${cmd_echo} ${lstatus_json} | ${cmd_jq} -r '.snapshots.applied'`
    local lstatus_latest=`${cmd_echo} ${lstatus_json} | ${cmd_jq} -r '.snapshots.latest_available'`
    local lstatus_train=`${cmd_echo} ${lstatus_json} | ${cmd_jq} -r '.current_running_train'`

                                                                                                    #set exitstring to true if applied and latest do not match
    [ "${lstatus_applied}" != "${lstatus_latest}_${lstatus_train}" ] && ${cmd_os-updater} ${lstatus_latest}_${lstatus_train}
}
function oracle.update.os.check {
    #accepts 0 args, returns boolean true/false if upgrade is available.  true=needs upgrade, fasle=does not need upgrade

    local lstatus_json=`oracle.update.os.get`
    local lstatus_applied=`${cmd_echo} ${lstatus_json} | ${cmd_jq} -r '.snapshots.applied'`
    local lstatus_latest=`${cmd_echo} ${lstatus_json} | ${cmd_jq} -r '.snapshots.latest_available'`
    local lstatus_train=`${cmd_echo} ${lstatus_json} | ${cmd_jq} -r '.current_running_train'`

    local lexitstring=${false}

                                                                                                    #set exitstring to true if applied and latest do not match
    [ "${lstatus_applied}" != "${lstatus_latest}_${lstatus_train}" ] && lexitstring=${true}

    echo ${lexitstring}
}