#date 20220519
#version=0.0.1

function git.clean {
    #accepts 2 args 1 git repo name 2 expected branch.  uses global git_root. returns no output

    local lrepo=${1}
    local lbranch=${2}

    if [ -d ${git_root}/${lrepo} ]; then
        git.rebase.abort ${lrepo}                                                                   #rebase error correction
        local lcurrent_branch=`git.branch ${lrepo}`                                                 #get current branch
        [ "${lcurrent_branch}" != "master" ] && ${cmd_git} -C ${git_root}/${lrepo} checkout master  #checkout master if not already

        ${cmd_git} -C ${git_root}/${lrepo} fetch                                                    #fetch git meta
        ${cmd_git} -C ${git_root}/${lrepo} pull                                                     #pull updated repo
    fi
}
function git.commit.force {
    #accepts 1 args 1 git repo uses global git_root.  this will stage all untracked files and commit.

    local lrepo=${1}
    if [ `${cmd_git} -C ${git_root}/${lrepo} status | ${cmd_head} -n 2 | ${cmd_tail} -n -1 | grep -c ^"Your branch is up to date with \'origin/${repo}\'"` -eq 0 ]; then
        ${cmd_git} -C ${git_root}/${lrepo} fetch
        ${cmd_git} -C ${git_root}/${lrepo} pull
        ${cmd_git} -C ${git_root}/${lrepo} add -A .
        ${cmd_git} -C ${git_root}/${lrepo} commit -am "forced commit from script"
    fi

}
function git.branch {
    #acepts  1 arg repo name, returns string branch name.

    local lrepo=${1}

    local lcurrent_branch=`${cmd_git} -C ${git_root}/${lrepo} branch | ${cmd_grep} ^* | ${cmd_sed} 's/* //'`

    ${cmd_echo} ${lcurrent_branch}
}
function git.rebase.abort {
    #accepts 1 arg git repo name.  usues global git_root, returns no output

    local lrepo=${1}

    local lcurrent_branch=`git.branch ${lrepo}`
                                                                                                    #abort bad rebase
    [ `${cmd_echo} ${lcurrent_branch} | ${cmd_grep} -c "no branch"` -gt 0 ] && ${cmd_git} -C ${git_root}/${lrepo} rebase --abort
}