#20220504
#build=0.0.2

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
    #accepts 0 args. returns json of all physical volumes managed by lvm
    
    local lpvreport=`${cmd_pvdisplay} -C | ${cmd_tail} -n +2 | ${cmd_tr} -s ' ' | ${cmd_sed} 's/ //' | ${cmd_sed} 's/<//g' | ${cmd_jq} --raw-input -s 'split("\n") | map(split(" ")) | .[0:-1] | map( { "physical_volume": .[0],"volume_group":.[1],"fmt":.[2],"attr":.[3],"psize":.[4],"pfree":.[5] } )' | ${cmd_jq} '.[]'`

    echo ${lpvreport}
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
    #accepts 0 args.  returns json of all volumes managed by lvm

    local llvreport=`${cmd_lvs} --reportformat json | ${cmd_jq} -c '.report[].lv[]'`                #output logical volume to json format for parsing
                                                                          
    echo ${llvreport}
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
    #accepts 0 args. returns json of all volume groups managed by lvm
    
    local lvgreport=`${cmd_vgdisplay} -C | ${cmd_tail} -n +2 | ${cmd_tr} -s ' ' | ${cmd_sed} 's/ //' | ${cmd_sed} 's/<//g' | ${cmd_jq} --raw-input -s 'split("\n") | map(split(" ")) | .[0:-1] | map( { "volume_group": .[0],"physical_volume":.[1],"logical_volume":.[3],"vsize":.[5],"vfree":.[6] } )' | ${cmd_jq} '.[]'`

    echo ${lvgreport}
}