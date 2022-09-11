#!/bin/bash

#source config
. ../etc/oci.cfg

#echo ${cfg}
#echo ${lib}
#echo ${include}

#source libs
for include in `echo ${include} | sed 's/\,/\ /g'`; do 
	#echo ${lib}/${include}
 	. ${lib}/${include}
done



#create file paths
[ -d ${log} ] || mkdir -p ${log}

#testing
#echo ${ocid}
#oci.ocid.deconstruct ${ocid}
#oci.hostname.deconstruct cust-dev-authproxy-0.node.ad1.us-ashburn-1
#oci.sshkeyfile.parse united_states
#oci.profile.get ${region}
#oci.ocid.deconstruct ${ocid}
#ocid=`echo ${host_json} | jq -r '.data.ocid'`
#ocid_json=`oci.ocid.deconstruct ${ocid}`
#profile=`echo ${ocid_json} | jq -r '.data.profile'`
#oci.compute.instance.get ${ocid} ${profile}
#exit													


#main
#validate command line args
oci.validate ${@} 																		#send cli arguments to validation

#load PIV
#20220222 cm - function needs work
# echo 
# echo +==============================================================================+
# printf '| %-76s | \n' "Enter PIV Key PIN"
# echo +------------------------------------------------------------------------------+
# oci.ssh.reload																			#enter PIV PIN ensure it is fresh
# echo +------------------------------------------------------------------------------+

#check dependancies to update and exit if missing
dep_err=0																				#initialize error count
echo 
echo +==============================================================================+
printf '| %-76s | \n' "Checking dependancies"
echo +------------------------------------------------------------------------------+
shell.dependancy.check

echo +------------------------------------------------------------------------------+
[ ${dep_err} -gt 0 ] && exit															#exit on failed dependacies
echo 


#update tenancy ssh file
echo +==============================================================================+

printf '| %-76s | \n' "Updating SSH files from OCI"
echo +------------------------------------------------------------------------------+

printf '| %-25s %-50s | \n' "tenancy" "${tenancy}"
printf '| %-25s %-50s | \n' "log file" "`echo ${log}/sshconfig | head -c 50`"

sshupdate=`oci.sshkeyfile.update ${tenancy}`
sshupdate_errors=`echo ${sshupdate} | jq -r '.data.errors'`
sshupdate_success=$( [ `echo ${sshupdate} | jq -r '.data.success'` -eq 0 ] && echo success || echo failure )
sshupdate_jsoncreate=$( [ `echo ${sshupdate} | jq -r '.data.jsoncreate'` -eq 0 ] && echo success || echo failure )
printf '| %-25s %-50s | \n' "completed" "${sshupdate_success}"
printf '| %-25s %-50s | \n' "errors" "${sshupdate_errors}"
printf '| %-25s %-50s | \n' "json" "${sshupdate_jsoncreate}"

echo +------------------------------------------------------------------------------+

#filter - host
echo
echo +==============================================================================+




if [ ! -z ${tenancy} ] && [ ! -z ${filterregion} ] && [ ! -z ${filterhost} ]; then
	printf '| %-76s | \n' "Filter tenancy=${tenancy} region=${filterregion} host=${filterhost}"
	json=`cat ~/.ssh/${tenancy}.ssh-config.json | jq -c '.'${tenancy}'[] | select(.ocid_deconstruct.region == "'${filterregion}'") | select(.hostname? | match("'${filterhost}'"))' | jq -s .`							#get filtered json stream

elif [ ! -z ${tenancy} ] && [ ! -z ${filterregion} ]; then
	printf '| %-76s | \n' "Filter tenancy=${tenancy} region=${filterregion}"
	json=`cat ~/.ssh/${tenancy}.ssh-config.json | jq -c '.'${tenancy}'[] | select(.ocid_deconstruct.region == "'${filterregion}'")' | jq -s .`									#get filtered json stream

elif [ ! -z ${tenancy} ] && [ ! -z ${filterhost} ]; then
	printf '| %-76s | \n' "Filter tenancy=${tenancy} region=${filterregion} host=${filterhost}"
	json=`cat ~/.ssh/${tenancy}.ssh-config.json | jq -c '.'${tenancy}'[] | select(.hostname? | match("'${filterhost}'"))' | jq -s .`							#get filtered json stream

elif [ ! -z ${tenancy} ]; then
	printf '| %-76s | \n' "Filter tenancy=${tenancy}"
	json=`cat ~/.ssh/${tenancy}.ssh-config.json | jq -c '.'${tenancy}'[]' | jq -s .`									#get filtered json stream

else
	oci.help
	exit
fi
echo +------------------------------------------------------------------------------+


#output json to screen
json_count=`echo ${json} | jq -c  '.[]' | wc -l`									#count records in hosts array

printf '| %-25s %-50s | \n' "IP" "HostName"												#print header

#loop through json objects in the hosts array
for line in `echo ${json} | jq -c '.[]'`; do
	ip=`echo ${line} | jq -r '.ip' | head -c 25`
	hostname=`echo ${line} | jq -r '.hostname' | head -c 50`
	printf '| %-25s %-50s | \n' "${ip}" "${hostname}"
done

echo +------------------------------------------------------------------------------+
echo records ${json_count}																#output record count