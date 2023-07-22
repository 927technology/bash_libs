# Operations Scripts Libraries

</br>

## Adding the library to your project

This will add the repo to your project as the ./lib directory.  

```
git submodule add ssh://git@bitbucket.oci.oraclecorp.com:7999/covsys/hc-ops-libs.git ./lib
```

## Updating the library

The library will update periodically, be sure to update it each time you update your project.

From the root of your project 

Update

```
git submodule update --remote
```

Commit
```
git add ./lib
git commit -am "updated libraries"
```

## Library versions

There are multiple versions, 0.0.1, 0.0.2, ..., each has similar libraries.  The versions are able to stand on their own, and are mostly backwards compatable.  It is best to use the most current.


## Sourcing libraries into your project

To use a library in your script add the following to your script, preferrabily at the top

```
. ./lib/bash/0.0.2/cmd_oracle.v
```
OR

```
source ./lib/bash/0.0.2/cmd_oracle.v
```

## Library Types

.v - Variables: The libraries use variable for full pathing of commands and logic.  cmd_\<distro\>.v and bools.v are required in almost all instances.

.f - Functions: These give tested outcomes to command procedures.  
    
Example

```
#!/bin/bash

#libraries
. ./lib/bash/0.0.2/cmd_mac.v    #cmd lib for mac, use lib for your environment
. ./lib/bash/0.0.2/bools.v      #boolean lib
. ./lib/bash/0.0.2/text.f       #text lib

#main
text.lcase TEST
```

This would output "test" due to the text.lcase function forcing the text to lower case.

</br>

# Libraries

## Boolean Libraries
bools.v - This library contains variables for boolean values such as true/false and exit related codes.  This library is heavily dependant by many of the function libraries.

## Command Libraries
To aid in secure coding, all commands are full pathed when called.  To ensure uniformity all commands are set as a variable in the fashion of cmd_\<command>\=/path/to/binary in the repective cmd library.  This ensures that aliases or alternate binaries in the path are not used.

cmd_centos.v - Developed mostly for CentOS, Compatable across most RHEL based distros such as CentOS, Oracle, RHEL, and Rocky.

cmd_debian.v - Debian based command library.  Compatable across most Debian distros such as Debian and Ubuntu.

cmd_mac.v - Mac based command library.  

cmd_oracle.v - Oracle specific command library.  This library incorporates distinct pathings for Oracle Cooperate builds of Oracle Linux.

## Function Libraries
To aid in ease of coding common tasks are made into functions.  These functions will give the code repeatable outcomes and incorporate additional checks that might otherwise be overlooked.

</br>

### Open the files for functions and usage
---
datatype.f - checks the datatype of a string

date.f - performs date manupulation

docker.f - docker 

file.f - file exists, max age, size, symlink

lvm.f - logical volume manager

oci.f - oci cli

os.f - operating system tasks

systemd.f - systemd tasks

text.f - text manuplation