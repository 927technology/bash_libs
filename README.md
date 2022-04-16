# **Bash Libraries**

### Functions for Bash to make coding easier

Source the files into your scripts to reduce time coding and troubleshooting by utilizing tested functions.

To sourcea file into your script use the source command or .
>. ./lib/date.f

or 

>source ./lib/date.f

&nbsp;

All functions in this library require sourcing bools.v and cmd.v.  These are not expressly defined as dependancies when source individually.

&nbsp;

---

### Files Extensions
|Ext|Description|
|:---|:-------------|
|.v|Variables defination.  These files define system variables.  bools.v contains values for true/false for example.  cmd.v values for shell pathed executables.  cmd_echo=/usr/bin/echo would be called ${cmd_echo} from your script or function to reduce shell alias compromise|
|.f|Function defination.  Functions are code blocks to do repetative tasks.  Descriptions for each function are outlined in each function respectivly.

&nbsp;

---

### Version Notes
|Version|File|Notes
|:-----|:------------|:--------------------------------------------------------------------------|
|0.1|All|Started standardising use of cmd.v for all calls for shell commands.  This reduces the availablity of a shell alias to be compromised as a vector of attack.|
|0.1|bool.v|Standard boolean values assigned
|0.1|cmd.v|Commands defined using system paths to reduce attack vectors using shell aliases|
|0.1|date.f|initial commit|
|0.1|docker.f|Added docker.true to test for environment is within a docker container|
|0.1|file.f|initial commit|
|0.1|json.f|initial commit|
|0.1|logrotate.f|initial commit|
|0.1|lvm.f|initial commit|
|0.1|nagios.v|initial commit|
|0.1|oci.f|initial commit|
|0.1|odo.f|Added odo.docker.images, odo.docker.images.inspect, odo.docker.ps.all, odo.docker.ps.running, odo.list|
|0.1|os.f|initial commit|
|0.1|shell.f|initial commit|
