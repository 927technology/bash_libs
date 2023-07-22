#20220504
#build=0.0.1

function oci.region {
    #accpets 0 args, returns oci region,
    
    local lregion=`${cmd_cat} /etc/region`
    
    ${cmd_echo} ${lregion}
}
: '
function oci.list.iam.ad {
    local lprofile=${1}
    
    local liamad=`oci iam availability-domain list --all  --profile ${lprofile} | jq -c`
    echo ${liamad}
}
function oci.list.iam.regionsubscription {
    local lprofile=${1}

    local liamregionsubscription=`oci iam region-subscription list --profile ${lprofile} | jq -c`
    echo ${liamregionsubscription}   
}
function oci.list.iam.homeregion {
    local lprofile=${1}

    local liamregionsubscription=`oci.list.iam.regionsubscription | jq`
}
'

function oci.help {
    echo you done messed up a-aron!

}
function oci.profile.get {
    #tested cm
    #date 20220215

    #accepts 1 unquoted string input of region name and returns oci profile unquoted string name

    #get oci profile for region

    local lregion=${1}

    if [ ! -z ${lregion} ]; then                                                                    #test for non-blank entry

        #parse oci.json for tenancy
        local ltenancy=`cat ${cfg}/oci.json | jq -r '.region[] | select(.long == "'${lregion}'").tenancy'`

        #get profile if tenancy is available
        if [ ! -z ${ltenancy} ]; then
            local lprofile=`cat ${cfg}/oci.json | jq -r '.tenancy[].'${ltenancy}'.regions[] | select(.region == "'${lregion}'").profile'`

        else
            lprofile=NULL2                                                                          #return null if profile is empty
        fi
    else
        local lprofile=NULL
    fi

    local loutput=${lprofile}
    echo ${loutput}                                                                                 #output string
}
function oci.compute.instance.get {
    #testing cm
    #date 20220215

    #accepts 2 unquoted strings and outputs unquoted json instance data from oci

    #input01: ocid
    #example ocid: ocid1.instance.oc1.phx.anyhqljsgyo4xiyc7kyzoapsxajfos7rijhca2krh24f4dhv744bycec5bsq

    #input02: oci profile
    #example profile: boat-phx-oc1

    local locid=${1}
    local lprofile=${2}

    if [ ! -z ${locid} ] || [ ! -z ${lprofile} ]; then
        #get compute instance based on ocid in json format
        local loutput=`oci compute instance get --instance-id ${locid} --profile ${lprofile} | jq -c`   
        
        #test error value for failures
        [ ! -z "${loutput}" ] && local lsuccess=${exitok} || local lsuccess=${exitcrit}
    else
        local lsuccess=${exitcrit}
    fi
        
    echo ${loutput}                                                                                 #output json string
}
function oci.compute.instance.get.dn {
                                                                                                    #get compute instance displayname from ocid
    local locid=${1}

    local loutput=`oci.get.instance ${locid} | jq -r '."data"."display-name"'`                      #get compute instace display name in string format
    echo ${loutput}                                                                                 #output string
}
function oci.hostname.deconstruct {
    #testing cm
    #date 20220222

    #accepts 1 unquoted string host name and converts to unquoted json output
    #example hostname name: prs-shared-splunk-0.node.ad1.ap-sydney-1

    #20220215 changed verbiage from display name to hostname to represent names on the network vs in oci console

    local lhn=${1}                                                                                      #host name
    local lsuccess=${exitcrit}
    local lerror=0

    if [ ! -z ${lhn} ]; then
        local lhost=`echo ${lhn} | awk -F"." '{print $1}'`                                              #hostname portion of the hostname name
        [ -z ${lhost} ] && (( lerror++ ))

        local lregion_full=`echo ${lhn} | awk -F"." '{print $NF}'`                                      #full region from dn ex. ap-sydney-1
        [ -z ${lregion_full} ] && (( lerror++ ))

        local lregion=`echo ${lregion_full} | awk -F"-" '{print $2}'`                                   #oci region name
        [ -z ${lregion} ] && (( lerror++ ))

                                                                                                        #oci tenancy
        local ltenancy=`cat ${cfg}/oci.json | jq -r '.region[] | select(.long == "'${lregion}'").tenancy'`
        [ -z ${ltenancy} ] && (( lerror++ ))

        local lad=`echo ${lhn} | awk -F"." '{print $(NF-1)}'`                                           #availability domain
        [ -z ${lad} ] && (( lerror++ ))

        local ltype=`echo ${lhn} | awk -F"." '{print $(NF-2)}'`                                         #type of resource
        [ -z ${ltype} ] && (( lerror++ ))

        local lunit=`echo ${lhost} | awk -F"-" '{print $1}'`                                            #work unit that owns the resource
        [ -z ${lunit} ] && (( lerror++ ))

        local lteam=`echo ${lhost} | awk -F"-" '{print $2}'`                                            #team that supports the resource
        [ -z ${lteam} ] && (( lerror++ ))

        local lrole=`echo ${lhost} | cut -d"-" -f3- | rev | cut -d "-" -f2- | rev`                      #role of the resource
        [ -z ${lrole} ] && (( lerror++ ))

        local lindex=`echo ${lhost} | awk -F"-" '{print $NF}'`                                          #index number of the resource
        [ -z ${lindex} ] && (( lerror++ ))

        local locid=`cat ${ssh_cfg}/${ltenancy}.ssh-config | grep ${lhn} | awk '{print $3}'`
        #[ -z ${locid} ] && (( lerror++ ))

        #test error value for failures
        [ ${lerror} -eq 0 ] && local lsuccess=${exitok} || local lsuccess=${exitcrit}
    else
        local lsuccess=${exitcrit}
    fi

    local loutput="{\"success\":\"${lsuccess}\",\"region\":\"${lregion}\",\"tenancy\":\"${ltenancy}\",\"ad\":\"${lad}\",\"type\":\"${ltype}\",\"unit\":\"${lunit}\",\"team\":\"${lteam}\",\"role\":\"${lrole}\",\"index\":\"${lindex}\",\"name\":\"${lhn}\"}"
    echo ${loutput}
}

function oci.policy.count {

    local ltenancy_ocid=${1}
    local lprofile=${2}
    local ltotal=0

    if [ ! -z ${ltenancy_ocid} ] && [ ! -z ${lprofile} ]; then
        ltotal=`${cmd_oci} iam policy list --compartment-id ${ltenancy_ocid} --profile ${lprofile} --all | ${cmd_jq} '.data[].id' | ${cmd_jq} -s '. | length'`
    fi
    
    ${cmd_echo} ${ltotal}
}
function oci.sshkeyfile.parse {
    #testing cm
    #date 20220222

    #accepts 1 unquoted string tennant and returns json

    #local lifs=${IFS}                                                                                                       #save IFS
    local ltenancy=${1}
    local l=0                                                                                                               #initialize line counter
    local loutput=
    local lhost_array=""                                                                                                    #initialize hosts array

    for line in `cat ~/.ssh/${ltenancy}.ssh-config | grep Host | awk '$1 == "Host" {lhost = $2; locid = $3; next;} $1 == "HostName" {lip = $2;} { print "{\"hostname\":\"" lhost"\",\"ocid\":\"" locid"\",\"ip\":\"" lip "\"}";}'`; do
        (( l++ ))
 
        local lhostname=`echo ${line} | jq -r '.hostname'`
        local locid=`echo ${line} | jq -r '.ocid'`
        local lhostdeconstruct=`oci.hostname.deconstruct ${lhostname}`
        local lociddeconstruct=`oci.ocid.deconstruct ${locid}`

        if [ ${l} -gt 1 ]; then
            loutput=${loutput}","${line}
        else
            loutput=${loutput}${line}
        fi

                                                                                                                            #add host and ocid deconstruct to json string
        loutput=`echo ${loutput} | sed 's/}$//'`",\"hostname_deconstruct\":"${lhostdeconstruct}",\"ocid_deconstruct\":"${lociddeconstruct}"}"

        #[ ${l} -eq 5 ] && break                                                                                             #limit output to 5 records for testing                                                                              
    done

    echo "{\""${ltenancy}"\":["${loutput}"]}"                                                                               #add tenancy to json string
}
function oci.sshkeyfile.show {

    local lsearch=${1}

    if [ `ls ${ssh_cfg}/*.ssh-config.json | grep -c .json` -gt 0 ]; then
        local ltenancies=`cat ${ssh_cfg}/*.ssh-config.json | jq -r '.data.tenancy'`
    else
        exit
    fi

}
function oci.sshkeyfile.update {
    #testing cm
    #date 20220216

    #accepts 1 unquoted string tennant returns json status 

    local ltenancy=${1}
    local lsuccess=${exitcrit}
    local lerror=0
    local lstalessh=${exitcrit}
    local lgitmethod=${exitcrit}
    local ljsoncreate=${exitcrit}
    local lpwd=`pwd`                                                                                                        #X marks the spot.  

    [ -f ${log}/sshconfig ] || touch ${log}/sshconfig
                                                                                                                            #check json presence in oci.json
    if [ `cat ${cfg}/oci.json | jq '.tenancy[].'${ltenancy}' | has("update_yaml")'` ]; then
        local lupdate_yaml=`cat ${cfg}/oci.json | jq -r '.tenancy[].'${ltenancy}'.update_yaml'`                             #get update yaml path


        if [ `shell.file.exists ${ssh_cfg}/${ltenancy}.ssh-config` -eq ${false} ] || [ `shell.file.stale ${ssh_cfg}/${ltenancy}.ssh-config ${maxage}` -eq ${true} ]; then

                #update/create covid19-host-patching scripts from git
                [ ! `shell.directory.exists ${gitroot}` -eq ${true} ] &&  mkdir -p ${gitroot}                               #make gitroot if missing
                cd ${gitroot}

                #git pull/update
                if [ `shell.directory.exists ${gitroot}/covid19-host-patching` -eq ${true} ]; then                          #update existing covid19-host-patching
                        local lgitmethod=update
                        cd covid19-host-patching                                                                            #changing dirs
                        git pull -q
                        [ ${?} -eq ${exitok} ] || (( lerror++ ))

                else                                                                                                        #git covid19-host-pa$
                        local lgitmethod=pull
                        git clone -q ssh://git@${git_covid19_host_patching}
                        [ ${?} -eq ${exitok} ] || (( lerror++ ))
                        cd covid19-host-patching                                                                            #changing dirs again, why we pwd this
                        [ ${?} -eq ${exitok} ] || (( lerror++ ))
                        pip3 install --upgrade pip
                        [ ${?} -eq ${exitok} ] || (( lerror++ ))
                        pip3 install -r requirements.txt
                        [ ${?} -eq ${exitok} ] || (( lerror++ ))
                fi

                python3 scripts/dynamic-ssh-config.py -c inventories/${lupdate_yaml} -a key --tenancy ${ltenancy} > ${log}/sshconfig   2>&1         #update tenancy
                [ ${?} -eq ${exitok} ] || (( lerror++ ))
 
                cd ${lpwd}                                                                                                  #we return things to where we found them

                #create json file
                oci.sshkeyfile.parse ${ltenancy} | jq > ${ssh_cfg}/${ltenancy}.ssh-config.json
                #sort json file
                #cat ~/.ssh/${ltenancy}.ssh-config.json | jq '.[]' | jq -s -c 'sort_by(.hostname)' | jq > ${ssh_cfg}/${ltenancy}.ssh-config.json

                [ ${?} -eq ${exitok} ] && ljsoncreate=${exitok} || (( lerror++ ))
        else
                #echo ssh config......fresh
                lstalessh=${exitok}
                if [ ! `shell.file.exists ${ssh_cfg}/${ltenancy}.ssh-config.json` -eq ${true} ]; then 
                    oci.sshkeyfile.parse ${ltenancy} | jq > ${ssh_cfg}/${ltenancy}.ssh-config.json
                    [ ${?} -eq ${exitok} ] && ljsoncreate=${exitok} || (( lerror++ ))
                else
                    ljsoncreate=${exitok}
                fi

                lgitmethod=none
        fi
    else
        (( lerror++ ))   
    fi

    [ ${lerror} -gt 0 ] || local lsuccess=${exitok}

    

    local loutput="{\"data\":{\"success\":\"${lsuccess}\",\"jsoncreate\":\"${ljsoncreate}\",\"tenancy\":\"${ltenancy}\",\"errors\":\"${lerror}\",\"stalessh\":\"${lstalessh}\",\"gitmethod\":\"${lgitmethod}\"}}"
    echo ${loutput}
}
function oci.ssh.reload {
    #20220222 cm broken - does not correctly detect unlocked PIV
    ssh-add -l /usr/local/lib/opnsc-pkcs11.so > /dev/null 2>&1                              #test if PIV is accessable
    if [ ${?} -ne ${exitok} ]; then
        ssh-add -e  /usr/local/lib/opensc-pkcs11.so > /dev/null 2>&1                        #remove PIV device
        if [ ${?} -ne ${exitok} ]; then                                                     #you done messed up a-aron
            echo "Error removing your PIV card."
        fi
    
        ssh-add -s  /usr/local/lib/opensc-pkcs11.so > /dev/null 2>&1                        #insert new PIV device
        if [ ${?} -ne ${exitok} ]; then                                                     #this is not the PIV you are lookng for
            echo "Error inserting your PIV card.  Try removing/replacing your PIV."
            exit
        fi 
    fi
}
function oci.validate {
    #WIP

    tenancy=`shell.null`                                                                       #set default variable value
    region=`shell.null`                                                                         #set default variable value
    filter=`shell.null`                                                                     #set default variable value
    filterhost=`shell.null`
    filterregion=`shell.null`
    ssh=`shell.null`                                                                          #set default variable value
    update_get=`shell.null`                                                                    #set default variable value
    update_install=`shell.null`                                                                 #set default variable value
    update_version=`shell.null`
    debug=${false}

    if [ "${1}" == "" ]; then                                                               #send to help for empty args
        oci.help
        exit
    fi

    while [ "${1}" != "" ]; do                                                              #loop until args stop
        case ${1} in
            -d | --debug)
                debug=${true}
            ;;
            -t | --tenancy)
                shift
                tenancy=${1}
            ;;
            -f | --filter)
                shift
                filterhost=${1}
            ;;
            -fh| --filter-host)
                shift
                filterhost=${1}
            ;;
            -fr| --filter-region)
                shift
                filterregion=${1}
            ;;
            -r | --region)
                shift
                filterregion=${1}
            ;;
            -s | --ssh)
                ssh=${true}
            ;;
            -ug| --update-get)
                update_get=${true}
            ;;
            -ui| --update-install)
                update_install=${true}
                shift
                update_version=${1}
            ;;
            * | -h | --help)                                                                #overrides all other args.  1 bad arg lands you here
                oci.help
                exit
            ;;
        esac
        shift
    done

    if [ ${debug} -eq ${true} ]; then
        echo +==============================================================================+
        printf '| %-76s | \n' "DEBUG - User argument values"
        echo +------------------------------------------------------------------------------+
        printf '| %-25s %-25s %-25s| \n' "key" "value" "required"
        printf '| %-25s %-25s %-25s| \n' "tenancy" "${tenancy}" "${true}"
        printf '| %-25s %-25s %-25s| \n' "filter" "${filter}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "filter host" "${filterhost}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "filter region" "${filterregion}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "region" "${filterregion}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "ssh" "${ssh}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "update_get" "${update_get}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "update_install" "${update_install}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "update_version" "${update_version}" "${false}"
        printf '| %-25s %-25s %-25s| \n' "debug" "${debug}" ${false}
        echo +------------------------------------------------------------------------------+
    fi
}
function oci.ocid.deconstruct {
    #testing cm
    #date 20220217

    #20220215 added output for NULL input/output value
    #20220215 added variable validation logic
    #20220217 fixed the region parse issue for oci.json schema changes

    #accepts 1 unquoted string ocid and converts to unquoted json output
    #example ocid: ocid1.instance.oc1.phx.anyhqljsgyo4xiyc7kyzoapsxajfos7rijhca2krh24f4dhv744bycec5bsq


    local locid=${1}
    local lsuccess=${exitcrit}
    local lerror=0

    if [ ! -z ${locid} ]; then
        #get ocid revision
        local lrevision=`echo ${locid} | awk -F"." '{print $1}'`
        [ -z ${lrevision} ] && (( lerror++ ))

        #get resource type
        local ltype=`echo ${locid} | awk -F"." '{print $2}'`
        [ -z ${ltype} ] && (( lerror++ ))
        
        #get management domain name
        local lmgmtdomain=`echo ${locid} | awk -F"." '{print $3}'`
        [ -z ${lmgmtdomain} ] && (( lerror++ ))
 
        #get region and region short name
        ##multiple formats to the region name
        local lregion_temp=`echo ${locid} | awk -F"." '{print $4}'`

        case `echo ${lregion_temp} | grep -c -` in
            0)

                local lregion_short=${lregion_temp}
                if [ -z ${lregion_short} ]; then
                    (( lerror++ ))
                else
                    #get region long/full name
                    local lregion=`cat ${cfg}/oci.json | jq -r '.region[] | select(.short == "'${lregion_short}'").long'`
                    [ -z ${lregion} ] && (( lerror++ ))
                fi
            ;;
            *)

                local lregion=`echo ${lregion_temp} | awk -F"-" '{print $2}'`

                if [ -z ${lregion} ]; then
                    (( lerror++ ))
                else
                    #get region short name
                    local lregion_short=`cat ${cfg}/oci.json | jq -r '.region[] | select(.long == "'${lregion}'").short'`
                    [ -z ${lregion} ] && (( lerror++ ))
                fi
            ;;
        esac

        #get unique identifier
        local luid=`echo ${locid} | awk -F"." '{print $5}'`
        [ -z ${luid} ] && (( lerror++ ))
       
        #get tenancy name
        local ltenancy=`cat ${cfg}/oci.json | jq -r '.region[] | select(.short == "'${lregion_short}'").tenancy'`
        [ -z ${ltenancy} ] && (( lerror++ ))

        #get oci profile
        local lprofile=`oci.profile.get ${lregion}`
        [ "${lprofile}" == "NULL" ] && (( lerror++ ))

        #test error value for failures
        [ ${lerror} -eq 0 ] && local lsuccess=${exitok} || local lsuccess=${exitcrit}
    else
        local lsuccess=${exitcrit}
    fi

    local loutput="{\"success\":\"${lsuccess}\",\"revision\":\"${lrevision}\",\"type\":\"${ltype}\",\"tenancy\":\"${ltenancy}\",\"mgmtdomain\":\"${lmgmtdomain}\",\"region\":\"${lregion}\",\"region_short\":\"${lregion_short}\",\"uid\":\"${luid}\",\"profile\":\"${lprofile}\",\"full\":\"${locid}\"}"
    echo ${loutput}
}
