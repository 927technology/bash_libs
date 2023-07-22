#requires cmd.v,text.f

function os.enumerate {
	##needs work!
	#accepts 0 args. returns os info in json string.

	#test kernel
	local lkernel=$(text.lcase `${cmd_uname} -s`)
	local larch=$(text.lcase `${cmd_uname} -p`)

	case ${lkernel} in
		darwin)
			#this is mac
			local los=$(text.lcase `${cmd_sw_vers} -productName`)
			local lversion=`${cmd_sw_vers} -productVersion`
			local lpackage_manager=brew
		;;
		linux)
			#this is linux
			local los=$(text.lcase `cat /etc/os-release | grep ^ID= | awk -F"=" '{print $2}'`)
			local lversion=`cat /etc/os-release | grep ^VERSION_ID= | awk -F"=" '{print $2}' | sed 's/"//g'`

			case ${los} in
				ol | redhat)	lpackage_manager=yum ;;
				ubuntu) 		lpackage_manager=apt ;;
			esac
		;;
		*)
			#this is other, possible unix
		;;
	esac

	local lexitstring={\"name\":${los},\"architecture\":${larch},\"version\":${lversion},\"package_manager\":${lpackage_manager}}

	echo ${lexitstring} | ${cmd_jq} -c
}

function os.name {
	
	local exitstring=none
	local exitcode=${exitcrit}	
	local kernel=`uname -a | awk '{print $1}'`


	case ${kernel} in
		Darwin)
			exitstring=macos
			exitcode=${exitok}
		;;
                Linux)
                        #is this a RHEL variant
                        if [ -f /etc/os-release ]; then
                                exitstring=`cat /etc/os-release | grep ^ID= | awk -F"=" '{print $2}' | sed 's/\"//g'`
                                exitcode=${?}
                        fi
                ;;
	esac

	echo ${exitstring}
#	return ${exitcode}	 
}
