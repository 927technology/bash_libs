#requires cmd.v,text.f

function os.enumerate {
	#accepts 0 args. returns os info in json string.

	#test kernel
	local lkernel=$(text.lower `${cmd_uname} -s`)
	local larch=$(text.lower `${cmd_uname} -p`)

	case ${lkernel} in
		darwin)
			#this is mac
			local los=$(text.tolower `${cmd_sw_vers} -productName`)
			local lversion=`${cmd_sw_vers} -productVersion`
			local lpackage_manager=brew
		;;
		linux)
			#this is linux
			local los=$(text.tolower `cat /etc/os-release | grep ^ID= | awk -F"=" '{print $2}'`)
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
