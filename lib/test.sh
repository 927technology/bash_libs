#!/bin/bash

. cmd_mac.v
. bools.v
. kubectl.f
. test.f

#kubectl.deployments.status $1 $2

#kubectl.ns.status $2

#kubectl.pods.status $2
test.return &
