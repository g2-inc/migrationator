#!/usr/local/bin/zsh
#-
# Copyright (c) 2019 Huntington Ingalls Industries
# Author: Shawn Webb <shawn.webb@hii-tsd.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

drive_need_matter() {
	return 1
}

drive_run() {
	local batchstep
	local naccounts
	local o
	local odir
	local res
	local sdate
	local users

	batchstep=15

	while getopts 'b:i:o:s:' o; do
		case "${o}" in
			b)
				batchstep=${OPTARG}
				;;
			i)
				ifile="${OPTARG}"
				;;
			o)
				odir="${OPTARG}"
				;;
			s)
				sdate="${OPTARG}"
				;;
			*)
				;;
		esac
	done

	if [ ! -f "${ifile}" ]; then
		log_error_arg "Please specify the input file with -i"
		log_error_arg "${ifile} does not exist"
		exit 1
	fi

	if [ -z "${odir}" ]; then
		log_error_arg "Please specify the output directory with -o"
		exit 1
	fi

	mkdir -p ${odir}/${matter} || return ${?}

	naccounts=$(wc -l ${ifile} | awk '{print $1;}')
	for ((i=1; ${i} <= ${naccounts}; i+=${batchstep})); do
		floor=${i}
		ceiling=$((${floor} + ${batchstep} - 1))
		echo "==== $((${floor} / ${batchstep})) : $(date '+%F %T') ===="

		users=$(sed -n ${floor},${ceiling}p ${ifile})

		drive_init_batch "${sdate}" "${users}" || return ${?}
		drive_execute_batch "${users}" || return ${?}
		drive_download_batch ${odir} "${users}" || return ${?}

		res=${?}
		[ ${res} -gt 0 ] && break
	done

	return 0
}
