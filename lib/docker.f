#20220504
#build=0.0.2

function docker.true {
    #accepts 0 args.  returns true/false if is a container under docker

    local lcgroup_pid1=`${cmd_cat} /proc/self/cgroup | ${cmd_grep} ^1:`

                                                                                                    #for those running docker daemon
    [ `${cmd_echo} "${lcgroup_pid1}" | ${cmd_grep} -ci docker` -gt 0 ] && local lexitstring=${true} || local lexitstring=${false}
                                                                                                    #for those running docker engine
    [ `${cmd_echo} "${lcgroup_pid1}" | ${cmd_grep} -ci ^1:` -eq 0 ] && local lexitstring=${true} || local lexitstring=${false}

    ${cmd_echo} ${lexitstring}
}