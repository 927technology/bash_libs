#!/bin/bash

cat << EOF >> ./test.txt

	[general]
	servername=${HOSTNAME}

EOF

