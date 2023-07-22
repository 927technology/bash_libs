#20220504
#build=0.0.1

#mount
function volume.df.report {
    #20220929 cm
    #accepts 0 args. returns json of all physical volumes
    
    local ljson=`${cmd_df} | ${cmd_tail} -n +2 | ${cmd_tr} -s ' ' | ${cmd_jq} --raw-input -s 'split("\n") | map(split(" ")) | .[0:-1] | map( { "filesystem": .[0],"1k_blocks":.[1],"used":.[2],"available":.[3],"use":.[4],"mount":.[5] } )'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}
function mount.report {
    #20220909
    #cm
    #accepts 0 args.  returns json of all block devices that are ext, vfat, and xfs.  
    #declare local variables
    local lbv_json=""
    local llvm_lv_json=""
    local llvm_pv_json=""
    local llvm_vg_json=""
    local lmount_device_json=""
    local lmount_docker_json=""
    local lmount_json=""
    local ljson="{}"

    #main
                                                                                                    #get block volume data
    lbv_json=`${cmd_osqueryi} 'select * from block_devices' --json 2> /dev/null`

                                                                                                    #get mount point data
    lmount_json=`${cmd_osqueryi} 'select * from mounts where type like "ext%" or type like "xfs%" or type like "%vfat%"' --json 2> /dev/null`

                                                                                                    #get mount point data for docker containers
    lmount_docker_json=`${cmd_osqueryi} 'select * from mounts where type == "nsfs" or type == "overlay" or type like "%vfat%"' --json 2> /dev/null`

                                                                                                    #lvm physical volume info 
    llvm_pv_json=`lvm.pv.report`
                                                                                                    #lvm volume group info
    llvm_vg_json=`lvm.vg.report`
                                                                                                    #lvm logical volume info
    llvm_lv_json=`lvm.lv.report`
                                                                                                    #generate list of devices
    lmount_devices=`${cmd_echo} ${lmount_json} | ${cmd_jq} -r '.[].device'`				    

    i=-1
    for mount_device in `echo $lmount_devices`; do
        (( i++ ))
        lmount_device_is_lvm=${false}
        lmount_device_name=""
        lmount_device_json=""
        lmount_device_vg_json="{}"
        lmount_device_vg_name=""
        lmount_device_lv_json="{}"
        lmount_device_lv_name=""

                                                                                                    #get mount info for this device
        lmount_device_json=`${cmd_echo} ${lmount_json} | ${cmd_jq} -c '.[] | select(.device == "'${mount_device}'")'`

                                                                                                    #add mount info to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'].mount |=.+ '${lmount_device_json}`

                                                                                                    #add device name to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'] |=.+ {"device":"'${mount_device}'"}'`

                                                                                                    #get vg name
        lmount_device_vg_name=`${cmd_echo} ${mount_device} | ${cmd_awk} -F"/" '{print $NF}' | ${cmd_awk} -F"-" '{print $1}'`

                                                                                                    #get lv name
        lmount_device_lv_name=`${cmd_echo} ${mount_device} | ${cmd_awk} -F"/" '{print $NF}' | ${cmd_awk} -F"-" '{print $2}'`

                                                                                                    #set lvm to true if device name is present
        [ ! -z ${lmount_device_lv_name} ] && lmount_device_is_lvm=${true}

                                                                                                    #construct lvm data into json
        if [ ${lmount_device_is_lvm} -eq ${true} ]; then

                                                                                                    #retrieve pv data for this vg
            lmount_device_pv_json=`${cmd_echo} ${llvm_pv_json} | ${cmd_jq} -c '. | select(.volume_group == "'${lmount_device_vg_name}'")'`

                                                                                                    #add pv data to json
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'].lvm.pv |=.+ '${lmount_device_pv_json}`

                                                                                                    #retrieve vg data for this vg
            lmount_device_vg_json=`${cmd_echo} ${llvm_vg_json} | ${cmd_jq} -c '. | select(.volume_group == "'${lmount_device_vg_name}'")'`

                                                                                                    #add vg data to json
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'].lvm.vg |=.+ '${lmount_device_vg_json}`

                                                                                                    #retrieve lv data for the lv
            lmount_device_lv_json=`${cmd_echo} ${llvm_lv_json} | ${cmd_jq} -c '. | select(.lv_name == "'${lmount_device_lv_name}'" and .vg_name == "'${lmount_device_vg_name}'")'`

                                                                                                    #add lv data to json
            ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'].lvm.lv |=.+ '${lmount_device_lv_json}`

                                                                                                    #get the block volume for lvm partitions
            lmount_device_name=`${cmd_echo} ${lmount_device_pv_json} | ${cmd_jq} -r '.physical_volume'`
        else
                                                                                                    #get the block volume for standard partitions
            lmount_device_name=`${cmd_echo} ${lmount_device_json} | ${cmd_jq} -r '.device'`
        fi
                                                                                                    #add lvm status to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'] |=.+ {"is_lvm":"'${lmount_device_is_lvm}'"}'`

                                                                                                    #get block volume info for this device
        lbv_device_json=`${cmd_echo} ${lbv_json} | ${cmd_jq} -c '.[] | select(.name == "'${lmount_device_name}'")'`

                                                                                                    #add block volume info to json
        ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.volumes['${i}'].block_volume |=.+ '${lbv_device_json}`


        
    done

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}
#physical volume
function lvm.pv.check {
    #accepts 1 arg. 1 vg name.  returns json of size

    local lpvreport=`lvm.pv.report`
    local lvgname=${1}                                                                              #this the thier name not path or mountpoint of the volume group

                                                                                                    #parse the logical vol name with unit from json
    local lpvphysical_volume=`${cmd_echo} ${lpvreport} | ${cmd_jq} -r 'select(.volume_group == "'${lvgname}'").physical_volume'`
                                                                                                    #parse the logical vol size with unit from json
    local lpvsize_full=`${cmd_echo} ${lpvreport} | ${cmd_jq} -r 'select(.volume_group == "'${lvgname}'").psize'`
    local lpvsize_unit=${lpvsize_full: -1}                                                          #strip the size from the json output leaving the unit
                                                                                                    #strip the unit from the json output leaving the size, remove the decimal keeping the int value
    local lpvsize=`${cmd_echo} ${lpvsize_full} | sed 's/'${lpvsize_unit}'$//' | ${cmd_awk} -F"." '{print $1}'` 

                                                                                                    #parse the logical vol free size with unit from json
    local lpvsize_free_full=`${cmd_echo} ${lpvreport} | ${cmd_jq} -r 'select(.volume_group == "'${lvgname}'").pfree'`
    local lpvsize_free_unit=${lpvsize_free_full: -1}                                                #strip the size from the json output leaving the unit
                                                                                                    #strip the unit from the json output leaving the size, remove the decimal keeping the int value
    local lpvsize_free=`${cmd_echo} ${lpvsize_free_full} | ${cmd_sed} 's/'${lpvsize_free_unit}'$//' | ${cmd_awk} -F"." '{print $1}'` 

    local lexitstring="{ \"physical_volume\": \"${lpvphysical_volume}\", \"full\":\"${lpvsize_full}\",\"size\":${lpvsize},\"unit\":\"${lpvsize_unit}\",\"free_full\":\"${lpvsize_free_full}\",\"free_size\":${lpvsize_free},\"free_unit\":\"${lpvsize_free_unit}\" }"

    echo ${lexitstring}

}
function lvm.pv.report {
    #20220929 cm
    #accepts 0 args. returns json of all physical volumes managed by lvm
    
    local ljson=`${cmd_pvdisplay} -C | ${cmd_tail} -n +2 | ${cmd_tr} -s ' ' | ${cmd_sed} 's/ //' | ${cmd_sed} 's/<//g' | ${cmd_jq} --raw-input -s 'split("\n") | map(split(" ")) | .[0:-1] | map( { "physical_volume": .[0],"volume_group":.[1],"fmt":.[2],"attr":.[3],"psize":.[4],"pfree":.[5] } )'`

    ${cmd_echo} ${ljson} | ${cmd_jq} -c
}
#logical volume
function lvm.lv.check { 
    #accepts 2 args.  1 vg name , 2 lv name. returns json of size
    #this function only gives information about the size of a lv partition, it does not alter the partition.

    local llvreport=`lvm.lv.report` 
    local lvgname=${1}                                                                              #this is their name not path or mountpoint of the volume group
    local llvname=${2}                                                                              #this is their name not path or mountpoint of the logical volume partition

                                                                                                    #parse the logical vol size with unit from json
    local llvsize_full=`${cmd_echo} ${llvreport} | ${cmd_jq} -r 'select(.vg_name == "'${lvgname}'" and .lv_name == "'${llvname}'").lv_size'`
    local llvsize_unit=${llvsize_full: -1}                                                          #strip the size from the json output leaving the unit
                                                                                                    #strip the unit from the json output leaving the size, remove the decimal keeping the int value
    local llvsize=`${cmd_echo} ${llvsize_full} | ${cmd_sed} 's/'${llvsize_unit}'$//' | ${cmd_awk} -F"." '{print $1}'`                  
    
    local lexitstring="{\"full\": \"${llvsize_full}\",\"size\": ${llvsize}, \"unit\": \"${llvsize_unit}\" }"

    echo ${lexitstring}
}
function lvm.lv.report {
    #20220929 cm
    #accepts 0 args.  returns json of all volumes managed by lvm

                                                                                                    #output logical volume to json format for parsing
    local ljson=`${cmd_lvs} --reportformat json | ${cmd_jq} -c '.report[].lv[]' | ${cmd_jq} -s`
                                                                          
    echo ${ljson}
}
#volume group 
function lvm.vg.check {
    #accepts 1 arg. 1 vg name. returns json of all volume groups

    local lvgreport=`lvm.vg.report`
    local lvgname=${1}                                                                              #this the thier name not path or mountpoint of the volume group

                                                                                                    #parse volume group size
    local lvgsize_full=`${cmd_echo} ${lvgreport} | ${cmd_jq} -r 'select(.volume_group == "'${lvgname}'").vsize' | ${cmd_sed} 's/^<//'`
    local lvgsize_unit=${lvgsize_full: -1}                                                          #strip the size from the json output leaving the unit

                                                                                                    #strip the unit from the json output leaving the size, remove the decimal keeping the int value
    local lvgsize=`${cmd_echo} ${lvgsize_full} | ${cmd_sed} 's/'${lvgsize_unit}'$//' | ${cmd_awk} -F"." '{print $1}'`

                                                                                                    #parse volume group free size
    local lvgsize_free_full=`${cmd_echo} ${lvgreport} | ${cmd_jq} -r 'select(.volume_group == "'${lvgname}'").vfree' | ${cmd_sed} 's/^<//'`
    local lvgsize_free_unit=${lvgsize_free_full: -1}                                                #strip the size from the json output leaving the unit

                                                                                                    #strip the unit from the json output leaving the size, remove the decimal keeping the int value
    local lvgsize_free=`${cmd_echo} ${lvgsize_free_full} | ${cmd_sed} 's/'${lvgsize_free_unit}'$//' | ${cmd_awk} -F"." '{print $1}'`

    local lexitstring="{ \"full\": \"${lvgsize_full}\", \"size\": ${lvgsize}, \"unit\": \"${lvgsize_unit}\", \"free_full\": \"${lvgsize_free_full}\", \"free_size\": ${lvgsize_free}, \"free_unit\": \"${lvgsize_free_unit}\" }"

    echo ${lexitstring}
}
function lvm.vg.report {
    #20220929 cm
    #accepts 0 args. returns json of all volume groups managed by lvm
    
    local ljson=`${cmd_vgdisplay} -C | ${cmd_tail} -n +2 | ${cmd_tr} -s ' ' | ${cmd_sed} 's/ //' | ${cmd_sed} 's/<//g' | ${cmd_jq} --raw-input -s 'split("\n") | map(split(" ")) | .[0:-1] | map( { "volume_group": .[0],"physical_volume":.[1],"logical_volume":.[3],"vsize":.[5],"vfree":.[6] } )'`

    ${cmd_echo} "${ljson}" | ${cmd_jq} -c
}