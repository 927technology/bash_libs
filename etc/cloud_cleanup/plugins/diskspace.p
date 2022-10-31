#variables
plugin_version=0.0.1

#functions
function plugin_intel {
    #declare local variables
    local ljson=${1}

    #main
    ${cmd_echo} ${ljson}
}

function plugin_logging {
    #declare local variables
    local ljson=${1}

    #main
    ${cmd_echo} ${ljson}
}

function plugin_output {
    #declare local variables
    local ljson=${1}

    #main
    ${cmd_echo} ${ljson}
}

function plugin_remediate {
    #declare local variables
    local ljson=${1}

    #main
    ${cmd_echo} ${ljson}
}

################################### DISK UTILIZATION ###################################
#get partitions over usage from df

                                                                                                   #get diskspace json - docker approved
partitions_oversize=`shell.diskspace | ${cmd_jq} -c '[ .[] | select(.filesystem != "Filesystem" and (.use | tonumber ) >= '${max_disk_usage}') ]'`

declare -a partition_oversize_filesystem                                                            #declare array - filesystems equal or greater than ${max_disk_usage}
declare -a partition_oversize_size                                                                  #declare array - size of filesystem
declare -a partition_oversize_used                                                                  #declare array - size of used filesystem
declare -a partition_oversize_avail                                                                 #declare array - size of available filesystem
declare -a partition_oversize_use                                                                   #declare array - integer percentage of used filesystem
declare -a partition_oversize_mount                                                                 #declare array - mountpoint of filesystem

i=0                                                                                                 #zero out counter
                                                                                                    #populate json into array
for partition_oversize in `echo ${partitions_oversize} | ${cmd_jq} -c '.[]'`; do
        (( i++ ))
        partition_oversize_filesystem[i]=`${cmd_echo} ${partition_oversize} | ${cmd_jq} -r '.filesystem'`
        partition_oversize_size[i]=`${cmd_echo} ${partition_oversize} | ${cmd_jq} -r '.size'`
        partition_oversize_used[i]=`${cmd_echo} ${partition_oversize} | ${cmd_jq} -r '.used'`
        partition_oversize_avail[i]=`${cmd_echo} ${partition_oversize} | ${cmd_jq} -r '.avail'`
        partition_oversize_use[i]=`${cmd_echo} ${partition_oversize} | ${cmd_jq} -r '.use'`
        partition_oversize_mount[i]=`${cmd_echo} ${partition_oversize} | ${cmd_jq} -r '.mount'`
done

#get lvm information - not docker approved
if [ `docker.true` -eq ${false} ]; then
    declare -a partition_oversize_filesystem_lvname_full                                            #declare array - full name of logical volume
    declare -a partition_oversize_filesystem_lvname_vg                                              #declare array - volume group of logical volume
    declare -a partition_oversize_filesystem_lvname_lv                                              #declare array - name of logical volume

                                                                                                    #parse oversize partitions array to get vg and lv
    for record in `${cmd_seq} 1 ${#partition_oversize_filesystem[@]}`; do

        if [ `${cmd_echo} ${partition_oversize_filesystem[record]} | ${cmd_grep} /mapper/ > /dev/null 2>@1 && ${cmd_echo} ${true} || ${cmd_echo} ${false}` -eq ${true} ]; then

            partition_oversize_filesystem_lvname_full[record]=`${cmd_echo} ${partition_oversize_filesystem[$record]} | ${cmd_awk} -F"/" '{print $NF}'`
            partition_oversize_filesystem_lvname_vg[record]=`${cmd_echo} ${partition_oversize_filesystem_lvname_full[$record]} | ${cmd_awk} -F"-" '{print $1}'`
            partition_oversize_filesystem_lvname_lv[record]=`${cmd_echo} ${partition_oversize_filesystem_lvname_full[$record]} | ${cmd_awk} -F"-" '{print $2}'`


            #get lvm physical volume information
            lvmpv[$record]=`lvm.pv.check ${partition_oversize_filesystem_lvname_vg[$record]}`       #get pv info
            lvmpv_physical_volume[$record]=`${cmd_echo} ${lvmpv[$record]} | ${cmd_jq} -r '.physical_volume'`
            lvmpv_size[$record]=`${cmd_echo} ${lvmpv[$record]} | ${cmd_jq} -r '.size'`
            lvmpv_size_unit[$record]=`${cmd_echo} ${lvmpv[$record]} | ${cmd_jq} -r '.unit'`
            lvmpv_free[$record]=`${cmd_echo} ${lvmpv[$record]} | ${cmd_jq} -r '.free_size'`
            lvmpv_free_unit[$record]=`${cmd_echo} ${lvmpv[$record]} | ${cmd_jq} -r '.free_unit'`

            #get lvm volume group information
            lvmvg[$record]=`lvm.vg.check ${partition_oversize_filesystem_lvname_vg[$record]} ${partition_oversize_filesystem_lvname_lv[$record]}`                  #get vg info
            lvmvg_size[$record]=`${cmd_echo} ${lvmvg[$record]} | ${cmd_jq} -r '.size'`
            lvmvg_size_unit[$record]=`${cmd_echo} ${lvmvg[$record]} | ${cmd_jq} -r '.unit'`
            lvmvg_free[$record]=`${cmd_echo} ${lvmvg[$record]} | ${cmd_jq} -r '.free_size'`
            lvmvg_free_unit[$record]=`${cmd_echo} ${lvmvg[$record]} | ${cmd_jq} -r '.free_unit'`

            #get lvm logical volume information
            lvmlv[$record]=`lvm.lv.check ${partition_oversize_filesystem_lvname_vg[$record]} ${partition_oversize_filesystem_lvname_lv[$record]}`                  #get vg info
            lvmlv_size[$record]=`${cmd_echo} ${lvmlv[$record]} | ${cmd_jq} -r '.size'`
            lvmlv_size_unit[$record]=`${cmd_echo} ${lvmlv[$record]} | ${cmd_jq} -r '.unit'`
            lvmlv_free[$record]=`${cmd_echo} ${lvmlv[$record]} | ${cmd_jq} -r '.free_size'`
            lvmlv_free_unit[$record]=`${cmd_echo} ${lvmlv[$record]} | ${cmd_jq} -r '.free_unit'`
        fi
    done
fi

if [ "${output}" == "table" ]; then
    #output headers 
    ${cmd_printf} '%-3s %-20s %-5s %-5s %-5s %5s %-20s %-10s %-10s %-5s %-5s %-5s %-5s %-5s %-5s %-5s \n'           \
            " "                                                                                                     \
            " "                                                                                                     \
            " "                                                                                                     \
            " "                                                                                                     \
            " "                                                                                                     \
            " "                                                                                                     \
            " "                                                                                                     \
            " "                                                                                                     \
            "PV"                                                                                                    \
            " "                                                                                                     \
            " "                                                                                                     \
            "VG"                                                                                                    \
            " "                                                                                                     \
            " "                                                                                                     \
            "LV"                                                                                                    \
            " "                                                             

    ${cmd_printf} '%-3s %-20s %-5s %-5s %-5s %5s %-20s %-10s %-10s %-5s %-5s %-5s %-5s %-5s %-5s %-5s \n'           \
            "#"                                                                                                     \
            "Filesystem"                                                                                            \
            "Size"                                                                                                  \
            "Used"                                                                                                  \
            "Avail"                                                                                                 \
            "Use%"                                                                                                  \
            "Mount"                                                                                                 \
            "LVM"                                                                                                   \
            "Device"                                                                                                \
            "Size"                                                                                                  \
            "Free"                                                                                                  \
            "Name"                                                                                                  \
            "Size"                                                                                                  \
            "Free"                                                                                                  \
            "Name"                                                                                                  \
            "Size"                                                             
fi

#output data
for record in `${cmd_seq} 1 ${#partition_oversize_filesystem[@]}`; do
                                                                                                    #output parition information
    if [ "${output}" == "table" ]; then
        ${cmd_printf} '%-3s %-20s %-5s %-5s %-5s %5s %-20s %-10s %-10s %-5s %-5s %-5s %-5s %-5s %-5s %-5s \n'       \
        "`${cmd_echo} ${record} | ${cmd_head} -c 3`"                                                                \
        "`${cmd_echo} ${partition_oversize_filesystem[$record]} | ${cmd_head} -c 20`"                               \
        "`${cmd_echo} ${partition_oversize_size[$record]} | ${cmd_head} -c 5`"                                      \
        "`${cmd_echo} ${partition_oversize_used[$record]} | ${cmd_head} -c 5`"                                      \
        "`${cmd_echo} ${partition_oversize_avail[$record]} | ${cmd_head} -c 5`"                                     \
        "`${cmd_echo} ${partition_oversize_use[$record]}% | ${cmd_head} -c 5`"                                      \
        "`${cmd_echo} ${partition_oversize_mount[$record]} | ${cmd_head} -c 20`"                                    \
        "`${cmd_echo} ${partition_oversize_filesystem_lvname_full[$record]} | ${cmd_head} -c 10`"                   \
        "`${cmd_echo} ${lvmpv_physical_volume[$record]} | ${cmd_head} -c 10`"                                       \
        "`${cmd_echo} ${lvmpv_size[$record]}${lvmpv_size_unit[$record]} | ${cmd_head} -c 5`"                        \
        "`${cmd_echo} ${lvmpv_free[$record]}${lvmpv_free_unit[$record]} | ${cmd_head} -c 5`"                        \
        "`${cmd_echo} ${partition_oversize_filesystem_lvname_vg[$record]} | ${cmd_head} -c 5`"                      \
        "`${cmd_echo} ${lvmvg_size[$record]}${lvmvg_size_unit[$record]} | ${cmd_head} -c 5`"                        \
        "`${cmd_echo} ${lvmvg_free[$record]}${lvmvg_free_unit[$record]} | ${cmd_head} -c 5`"                        \
        "`${cmd_echo} ${partition_oversize_filesystem_lvname_lv[$record]} | ${cmd_head} -c 5`"                      \
        "`${cmd_echo} ${lvmlv_size[$record][$record]}${lvmlv_size_unit[$record]} | ${cmd_head} -c 5`"
    fi

    shell.log.syslog "{\"id\":\"${syslog_id}\",\"task\":\"oversized_filesystems\",\"filesystem\":\"${partition_oversize_filesystem[$record]}\",\"size\":\"${partition_oversize_size[$record]}\",\"avail\":\"${partition_oversize_avail[$record]}\",\"use\":\"${partition_oversize_use[$record]}%\"}"
done

if [ "${output}" == "table" ]; then
                                                                                                    #total record count
    ${cmd_echo} total over ${max_disk_usage}% used file systems \(${#partition_oversize_filesystem[@]}\)
fi

                                                                                                    #exit on overutilized diskspace
if [ ${xe} -eq ${true} ] && [ ${#partition_oversize_filesystem[@]} -gt 0 ] && [ "${output}" == "table" ]; then 
    shell.log.screen "${#partition_oversize_filesystem[@]} filesystems over ${max_disk_usage}%"
    exit ${exitcrit}
fi