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

email_init_batch() {
	local output
	local res
	local users

	users=${1}
	echo ${users} | while read line; do
		acct=$(echo ${line} | awk -F ',' '{print $1;}')
		hasmbox=$(echo ${line} | awk -F ',' '{print $2;}')
		haslicense=$(echo ${line} | grep -Fi "google vault")
		if [ ${hasmbox} = "False" ]; then
			continue
		fi
		if [ -z "${haslicense}" ]; then
			continue
		fi

		echo "[*] Initiating mail export of account ${acct}"

		exportname="export-mail-${acct:gs/@/_}"
		output=$(${GAM} create export \
		    format pst \
		    name ${exportname} \
		    matter ${matter} corpus mail \
		    accounts ${acct})
		res=${?}
		if [ ${res} -gt 0 ]; then
			echo "    [-] Unable to initiate mail vault export of ${acct}"
			echo "${output}"
			return 1
		fi

		echo "[*] Sleeping for 60 seconds due to API quota"
		sleep 60
	done

	return 0
}

email_execute_batch() {
	local dlready
	local output
	local res
	local users

	users=${1}
	echo "[+] Exports in this batch initiated. Now waiting for download availability."
	while true; do
		dlready=1
		echo ${users} | while read line; do
			acct=$(echo ${line} | awk -F ',' '{print $1;}')
			hasmbox=$(echo ${line} | awk -F ',' '{print $2;}')
			haslicense=$(echo ${line} | grep -Fi "google vault")
			if [ ${hasmbox} = "False" ]; then
				continue
			fi
			if [ -z "${haslicense}" ]; then
				continue
			fi

			exportname="export-mail-${acct:gs/@/_}"
			exportinfo=$(${GAM} info export ${matter} ${exportname})
			exportstatus=$(echo ${exportinfo} | \
			    grep '^ status: ' | \
			    awk '{print $2;}')
			case "${exportstatus}" in
				"COMPLETED")
					;;
				"IN_PROGRESS")
					dlready=0
					;;
				*)
					# Unknown status
					echo ${exportinfo}
					return 1
					;;
			esac

			echo "[*] ${acct} status: ${exportstatus}"
			sleep 60
		done

		[ ${dlready} -eq 1 ] && break
	done

	return 0
}

email_download_batch() {
	local output
	local res
	local users

	users=${1}
	echo "[+] Downloads available. Downloading this batch now."

	echo ${users} | while read line; do
		acct=$(echo ${line} | awk -F ',' '{print $1;}')
		hasmbox=$(echo ${line} | awk -F ',' '{print $2;}')
		haslicense=$(echo ${line} | grep -Fi "google vault")
		if [ ${hasmbox} = "False" ]; then
			continue
		fi
		if [ -z "${haslicense}" ]; then
			continue
		fi

		exportname="export-mail-${acct:gs/@/_}"

		mkdir -p ${odir}/${matter}/${acct}

		echo "[+] Downloading ${acct} mail to ${odir}/${matter}/${acct}"

		output=$(${GAM} download export ${matter} ${exportname} \
		    targetfolder ${odir}/${matter}/${acct})
		res=${?}
		if [ ${res} -gt 0 ]; then
			echo "${output}"
			return ${res}
		fi
	done

	return 0
}
