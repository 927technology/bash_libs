#requires cmd.v


##lvm.lv
lvm.lv.report {
	#accepts 0 args, returns json string

	local lreport=`${cmd_lvs} --reportformat json | ${cmd_jq} -c '.report[].lv[]'`   #output logical volume to json format for parsing

	echo ${lreport}
}
lvm.lv.size {
	#accepts 1 arg lvname. returns json string

	local lname=${1}
	                                                                 		#parse the logical vol size with unit from json
	local lsize_full=`${cmd_echo} `lvm.lvreport` | ${cmd_jq} -r 'select(.lv_name == "'${lname}'").lv_size'`
	local lsize_unit=${lsize_full: -1}                            			#strip the size from the json output leaving the unit

                                                                            		#strip the unit from the json output leaving the size, remove the decimal keeping the int value
	lsize=`${cmd_echo} ${lsize_full} | sed 's/'${lsize_unit}'$//' | ${cmd_awk} -F"." '{print $1}'`                  


	local lexitstring={\"name\":${lname},\"size\":${lsize},\"unit\":${lsize_unit}

	echo ${lexitstring} | ${cmd_jq} -c
}

##lvm.pv
##need functions for physical volumes

##lvm.vg
lvm.vg.report {
	#accepts 1 arg vgname, returns json string

	local lname=${1}
                                                                            		#output volume group to json for parsing
	local lreport=`${cmd_vgdisplay} -C ${lname} | ${cmd_tail} -n +2 | ${cmd_tr} -s ' ' | ${cmd_sed} 's/ //' | ${cmd_jq} --raw-input -s 'split("\n") | map(split(" ")) | .[0:-1] | map( { "vg_name": .[0],"physical_volume":.[1],"logical_volume":.[3],"vsize":.[5],"vfree":.[6] } )' | ${cmd_jq} -c '.[]'`

	echo ${lreport}
}
lvm.vg.size {
	#accepts 1 arg vgname, returns json string

	local lname=${1}

	local lreport=`lvm.vg.report ${lname}`

	#get total size
	local lsize_total_full=`${cmd_echo} ${lreport} | ${cmd_jq} -r 'select(.volume_group == "'${lname}'").vsize' | ${cmd_sed} 's/^<//'`
	local lsize_total_unit=${lsize_total_full: -1}                                	#strip the size from the json output leaving the unit
                                                                            		#strip the unit from the json output leaving the size, remove the decimal keeping the int value
	local lsize_total=`${cmd_echo} ${lsize_total_full} | ${cmd_sed} 's/'${lsize_total_unit}'$//' | ${cmd_awk} -F"." '{print $1}'`
	
	#get free size
                                                                            		#parse volume group free size
	local lsize_free_full=`${cmd_echo} ${lreport} | ${cmd_jq} -r 'select(.volume_group == "'${lname}'").vfree' | ${cmd_sed} 's/^<//'`
	local lsize_free_unit=${lsize_free_full: -1}                                	#strip the size from the json output leaving the unit
                                                                            		#strip the unit from the json output leaving the size, remove the decimal keeping the int value
	local lsize_free=`${cmd_echo} ${lsize_free_full} | ${cmd_sed} 's/'${lsize_free_unit}'$//' | ${cmd_awk} -F"." '{print $1}'`

	local lexitstring={\"name\":${lname},\"size\":${lsize_total},\"size_unit\":${lsize_total_unit},\"free\":${lsize_free},\"free_unit\":${lsize_free_unit}}

	echo ${lexitstring} | ${cmd_jq} -c
}
