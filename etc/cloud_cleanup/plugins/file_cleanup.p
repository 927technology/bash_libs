#variables
plugin_version=0.0.1

#functions
function plugin_intel {

	#decalare local variables
	local lfile_count=0
	local lfile_size=0
	local lfile_size_total=0
	local ljson="{}"
	local lpath_exists=${false}
	local i=""
	local ii=""
	local j=""
	local jj=""


	#main
																									#loop through file paths from configuration file
	for i in `${cmd_seq} 1 ${#file_path[@]}`; do
		ii=$(( ${i} - 1 ))

																									#ensure target directory is a directory
		if [ -d ${file_path[$i]} ]; then

			lpath_exists=${true}																	#change from default because it exists
			
			j=-1																					#initialize file counter
																									#loop files that match given file path and regex									
			for file_name in `${cmd_ls} ${file_path[$i]} | ${cmd_egrep} ${file_regex[$i]}`; do 
			(( j++ ))
																									#we are only counting files and directories
				if [ -d ${file_path[$i]}/${file_name} ] || [ -f ${file_path[$i]}/${file_name} ]; then

																									#size when path has a subdirectory
					[ -d ${file_path[$i]}/${file_name} ] && lfile_size=`${cmd_du} -s ${file_path[$i]}/${file_name} | awk '{print $1}'`

																									#size when the path has a file
					[ -f ${file_path[$i]}/${file_name} ] && lfile_size=`${cmd_wc} -c < ${file_path[$i]}/${file_name}`
					
						
					lfile_size_total=$(( ${lfile_size_total} + ${lfile_size} ))						#sum, sum, sum
                                                                                  
																									#add key/values to json for files
        			ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files['${j}'] |=.+ {"name":"'${file_name}'"}'`
					ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files['${j}'] |=.+ {"sizeB":"'${lfile_size}'"}'`
				fi
			done
		fi
			
		lfile_size_total=$(( ${lfile_size_total} / 1024 ))											#files are calculated in B.  convert to K.

																									#adding the extra commas that json needs
		[ ${i} -ne 1 ] && loutput=${loutput},

																									#add key/values to json for paths
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"path":"'${file_path[$i]}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"exists":"'${lpath_exists}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"size_totalK":"'${lfile_size_total}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"regex":"'${file_regex[$i]}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"version":"'${plugin_version}'"}'`
	done
	
	${cmd_echo} ${ljson}																			#output json
}

function plugin_logging {

	#declare local variables
	local lfile_name=""
	local lfile_filelog=${false}
	local lfile_size=0
	local lfile_syslog=${false}
	local lfiles_count=0
	local ljson=${1}
	local lmessage_json=""
	local lrunlog_json="{}"
	local lpath=""
	local lpaths_count=0
	local lpath_found=""
	local lpath_size=""

	#main
	lpaths_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths' | ${cmd_jq} '. | length'`				#count array elements for path, counts are real counts 1 thru n

																									#loop indexes for paths, indexes in json are 0 thru (n-1)
	for i in `${cmd_seq} 1 ${lpaths_count}`; do	

		#set default values
		lfile_count_deleted=0
		lfile_count_skipped=0
		lfile_filelog=${false}
		lfile_syslog=${false}
		lfile_size_deleted=0
		lfile_size_skipped=0
		lrunlog_json="{}"
		
		ii=$(( ${i} - 1 ))

																									#construct logging messages
		if ( [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ] ) || [ ! -z ${filelog} ]; then
																									#run log info
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"build":"'${build}'"}'`
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"date":"'${now}'"}'`
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '. |=.+ {"dry_run":"'${dry_run}'"}'`
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"tag":"'${syslog_tag}'"}'`
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"enabled":"'${syslog}'"}'`
			lrunlog_json=`${cmd_echo} ${lrunlog_json} | ${cmd_jq} '.syslog |=.+ {"filelog":"'${filelog}'"}'`
		fi

																									#log to syslog facility
		if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then
			${cmd_logger} --tag ${syslog_tag} ${lrunlog_json}										#off to syslog facility

																									#did it successfull log
			[ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}

																									#update json to show log was sent, or not...
			ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.log |=.+ {"syslog":"'${lfile_syslog}'"}'`
		fi 

																									#send logs to file log
		if [ ! -z ${filelog} ]; then
			[ ! -d ${filelog} ] && ${cmd_mkdir} ${filelog}											#if it aint there, make it!
			${cmd_echo} ${lrunlog_json} >> ${filelog}/${plugin}										#log it

																									#did it successfully log
			[ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}

																									#update json to show log was sent, or not...
			ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.log |=.+ {"filelog":"'${lfile_filelog}'"}'`
		fi


		lfiles_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files | length'`			#count array elements for files, counts are real counts 1 thru n

																									#loop indexes for files, indexes in json are 0 thru (n-1)
		for j in `${cmd_seq} 1 ${lfiles_count}`; do
			
			#set default values
			lmessage_json="{}"
			
			jj=$(( ${j} - 1 ))
																									#get the required values from the array and variablize them
			lpath=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].path'`																						
			lfile_name=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].name'`
			lfile_size=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].sizeB'`
			lfile_success=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].deleted'`

																									#construct logging messages
			if ( [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ] ) || [ ! -z ${filelog} ]; then
																									#event log info
				lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.syslog |=.+ {"id":"'${syslog_id}'"}'`
				lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}' |=.+ {"path":"'${lpath}'"}'`
				lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}'.file |=.+ {"name":"'${lfile_name}'"}'`
				lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}'.file |=.+ {"size":"'${lfile_size}'"}'`
				lmessage_json=`${cmd_echo} ${lmessage_json} | ${cmd_jq} '.'${plugin}'.file |=.+ {"deleted":"'${lfile_success}'"}'`
			fi

																									#send logs to syslog facility
			if [ ! -z ${syslog} ] && [ ${syslog} -eq ${true} ]; then
				${cmd_logger} --tag ${syslog_tag} ${lmessage_json}
				
																									#did the message send
				[ ${?} -eq ${exitok} ] && lfile_syslog=${true} || lfile_syslog=${false}

																									#update json to show log was sent
				ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files['${jj}'].log |=.+ {"syslog":"'${lfile_syslog}'"}'`
			fi 

																									#send logs to file log
			if [ ! -z ${filelog} ]; then
				${cmd_echo} ${lmessage_json} >> ${filelog}/plugin									#log it

																									#did the message send?
				[ ${?} -eq ${exitok} ] && lfile_filelog=${true} || lfile_filelog=${false}

																									#update json to show log was sent
				ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files['${jj}'].log |=.+ {"filelog":"'${lfile_filelog}'"}'`
			fi
		done
	done

	${cmd_echo} ${ljson}
}

function plugin_output {

	#declare local variables
	local lfile_name=""
	local lfile_size=0
	local lfiles_count=0
	local ljson=${1}
	local lpath=""
	local lpaths_count=0
	local lpath_found=""
	local lpath_size=""

	#main
	[ ${dry_run} -eq ${true} ] && dry_run_marker=*

	${cmd_echo}
    ${cmd_echo} `shell.ucase ${plugin}`
    ${cmd_echo} --------------------------------------------------------------------------------

	lpaths_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths' | ${cmd_jq} '. | length'`				#count array elements for path, counts are real counts 1 thru n

																									#output paths header
	${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"														\
		"${dry_run_marker}"																			\
		"Path"																						\
		"Present"																					\
		""																							\
		"SizeK"

																									#loop indexes for paths, indexes in json are 0 thru (n-1)
	for i in `${cmd_seq} 1 ${lpaths_count}`; do	
		ii=$(( ${i} - 1 ))

																									#get the required values from the array and variablize them
		lpath=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].path'`			
		lpath_exists=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].exists'`
		lpath_size=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].size_totalK'`

																									#output paths table
		${cmd_printf} "%-2s %-50s %7s %7s %10s\n" 													\
			"${i}"																					\
			"${lpath}"																				\
			"${lpath_exists}"																		\
			""																						\
			"${lpath_size}"
	done
	
	${cmd_echo} ================================================================================

	#${cmd_echo}																						#add blank line between path and file output sections

																									#loop indexes for paths, indexes in json are 0 thru (n-1)
	for i in `${cmd_seq} 1 ${lpaths_count}`; do

		#set default values
		lfile_count_deleted=0
		lfile_count_skipped=0
		lfile_size_deleted=0
		lfile_size_skipped=0

		ii=$(( ${i} - 1 ))

		[ ${lpaths_count} -gt 1 ] && echo															#add blank line between paths
		
		lpath=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].path'`							#set path for array index $i
																									
																									#output paths info
		${cmd_printf} "%-2s %-50s\n" 																\
			"${i}"																					\
			"${lpath}"


		lfiles_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files | length'`			#count array elements for files, counts are real counts 1 thru n

																									#output header bar if there is actually data to show
		if [ ${lfiles_count} -gt 0 ]; then 
																									#output files header
			${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n" 											\
				""																					\
				"File"																				\
				""																					\
				"Deleted"																			\
				"SizeB" 
		fi

																									#loop indexes for files, indexes in json are 0 thru (n-1)
		for j in `${cmd_seq} 1 ${lfiles_count}`; do
			lfile_name=""
			lfile_size=0
			lfiles_count=0
			lpath=""
			lpaths_count=0
			lpath_found=""
			lpath_size=""

			jj=$(( ${j} - 1 ))

																									#get the required values from the array and variablize them
			lfile_name=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].name'`
			lfile_size=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].sizeB'`
			lfile_deleted=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].deleted'`
			lfile_count_deleted=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].file_count_deleted'`
			lfile_count_skipped=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].file_count_skipped'`
			lfile_size_deleted=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].file_size_deletedB'`
			lfile_size_skipped=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].file_size_skippedB'`

																									#output the files table
			${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"												\
				"${j}"																				\
				"${lfile_name}"																		\
				""																					\
				"${lfile_deleted}"																	\
				"${lfile_size}" 
		done

		echo		
																									#output totals header
		${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n" 												\
			""																						\
			"Totals"																				\
			""																						\
			"Count"																					\
			"SizeB" 
																									#output deleted totals
		${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n" 												\
			""																						\
			"Deleted"																				\
			""																						\
			"${lfile_count_deleted}"																\
			"${lfile_size_deleted}"

																									#output skipped totals
		${cmd_printf} "%-2s %-50s %-7s %-7s %10s\n"													\
			""																						\
			"Skipped"																				\
			""																						\
			"${lfile_count_skipped}"																\
			"${lfile_size_skipped}"

    	${cmd_echo} --------------------------------------------------------------------------------
	done
}

function plugin_remediate {

	#declare local variables
	local lfile_count_deleted=0
	local lfile_count_skipped=0
	local lfile_name=""
	local lfile_size=""
	local lfile_size_deleted=0
	local lfile_size_skipped=0

	local ljson=${1}
	local lpath=""
	local lpaths_count=0

	#main
	lpaths_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths' | ${cmd_jq} '. | length'`				#count array elements for path, counts are real counts 1 thru n

																									#loop indexes for paths, indexes in json are 0 thru (n-1)
	for i in `${cmd_seq} 1 ${lpaths_count}`; do	

		#set default values
		lfile_count_deleted=0
		lfile_count_skipped=0
		lfile_size_deleted=0
		lfile_size_skipped=0

		ii=$(( ${i} - 1 ))

		lfiles_count=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files | length'`			#count array elements for files, counts are real counts 1 thru n

																									#loop indexes for files, indexes in json are 0 thru (n-1)
		for j in `${cmd_seq} 1 ${lfiles_count}`; do
			
			jj=$(( ${j} - 1 ))
																									#get the required values from the array and variablize them
			lpath=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].path'`																						
			lfile_name=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].name'`
			lfile_size=`${cmd_echo} ${ljson} | ${cmd_jq} -r '.paths['${ii}'].files['${jj}'].sizeB'`

																									#check dry_run status and delete file
			[ ${dry_run} -eq ${false} ] && ${cmd_rm} -f ${lpath}/${lfile_name}

																									#report on successfull deletion and dry_run=false
			if [ ${?} -eq ${exitok} ] && [ dry_run=${false} ]; then
				lfile_size_deleted=$(( ${lfile_size_deleted} + ${lfile_size} ))						#sum totall files deleted
				lfile_success=${true}																#whoo hoo!
				(( lfile_count_deleted++ ))															#another one bytes the dust

																									#report on failed deletion or dry_run=true
			else
				lfile_size_skipped=$(( ${lfile_size_skipped} + ${lfile_size} ))						#sum total files skipped
				lfile_success=${false}																#oh snap!
				(( lfile_count_skipped++ ))															#safe for now
			fi

																									#if you havn't learned, json is very nice
																									#lets inject some new lines so we have accurate output
			ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'].files['${jj}'] |=.+ {"deleted":"'${lfile_success}'"}'`
		done

																									#add the final json elements
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"file_count_deleted":"'${lfile_count_deleted}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"file_count_skipped":"'${lfile_count_skipped}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"file_size_deletedB":"'${lfile_size_deleted}'"}'`
		ljson=`${cmd_echo} ${ljson} | ${cmd_jq} '.paths['${ii}'] |=.+ {"file_size_skippedB":"'${lfile_size_skipped}'"}'`
	done

	${cmd_echo} ${ljson}																			#output the updated json 
}