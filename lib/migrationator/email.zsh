#!/usr/local/bin/zsh
#-
# Copyright (c) 2019-2020 Huntington Ingalls Industries
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
	local _end
	local _start
	local breakout
	local edate
	local output
	local rcode
	local res
	local sdate
	local terms
	local users

	sdate=${1}
	users=${2}
	edate=${3}
	echo ${users} | while read line; do
		acct=$(echo ${line} | awk -F ',' '{print $1;}')
		haslicense=$(echo ${line} | grep -Fi "google vault")
		if [ -z "${haslicense}" ]; then
			continue
		fi

		log_info_arg "[*] Initiating mail export of account ${acct}"

		if [ ! -z "${sdate}" ]; then
			_start="start ${sdate}"
		fi
		if [ ! -z "${edate}" ]; then
			_end="end ${edate}"
		fi
		terms="from:${acct} OR to:${acct}"
		exportname="export-mail-${acct:gs/@/_}"

		while true; do
			breakout=1
			output=$(${GAM} create export \
			    format pst \
			    name ${exportname} \
			    matter ${matter} corpus mail \
			    ${=_start} \
			    ${=_end} \
			    everyone \
			    terms ${terms} 2>&1)
			res=${?}
			log_debug_arg "${output}"
			if [ ${res} -gt 0 ] || response_contains_error "${output}"; then
				log_error_arg "    [-] Unable to initiate mail vault export of ${acct}"
				rcode=$(response_get_error_code "${output}")
				echo "[-] rcode is \"${rcode}\""
				if [ "${rcode}" -eq 429 ]; then
					log_info_arg "    [*] Quota exceeded. Retrying after 20 minutes."
					sleep $((20 * 60))
				fi
				breakout=0
			fi

			log_debug_arg "[*] Sleeping for $(config_get_value sleep) seconds due to API quota."
			sleep $(config_get_value sleep)

			if [ ${breakout} -gt 0 ]; then
				break
			fi
		done
	done

	return 0
}

email_execute_batch() {
	local dlready
	local output
	local res
	local users

	users=${1}
	log_info_arg "[+] Exports in this batch initiated. Now waiting for download availability."
	while true; do
		dlready=1
		echo ${users} | while read line; do
			acct=$(echo ${line} | awk -F ',' '{print $1;}')
			haslicense=$(echo ${line} | grep -Fi "google vault")
			if [ -z "${haslicense}" ]; then
				continue
			fi

			exportname="export-mail-${acct:gs/@/_}"
			exportinfo=$(${GAM} info export ${matter} ${exportname} 2>&1)
			exportstatus=$(echo ${exportinfo} | \
			    grep '^ status: ' | \
			    awk '{print $2;}')
			log_info_arg "[*] ${acct} status: ${exportstatus}"
			case "${exportstatus}" in
				"COMPLETED")
					;;
				"IN_PROGRESS")
					dlready=0
					;;
				"FAILED")
					log_error_arg "[-] Export of account ${acct} failed. Error output:"
					log_error_arg "${exportinfo}"
					return 1
					;;
				*)
					# Unknown status
					log_error_arg "[-] Export of account ${acct} received an unknown status. Error output:"
					log_error_arg "${exportinfo}"
					rcode=$(response_get_error_code "${exportinfo}")
					echo "[-] rcode is \"${rcode}\""
					if [ ${rcode} -eq 429 ]; then
						log_info_arg "[*] Quota exceeded. Retrying after 20 minutes."
						sleep $((20 * 60))
						dlready=0
					else
						return 1
					fi
					;;
			esac

			log_debug_arg "[*] Sleeping for $(config_get_value sleep) seconds due to API quota."
			sleep $(config_get_value sleep)
		done

		[ ${dlready} -eq 1 ] && break
	done

	return 0
}

email_download_batch() {
	local breakout
	local odir
	local output
	local rcode
	local res
	local users

	odir=${1}
	users=${2}
	echo "[+] Downloads available. Downloading this batch now."

	echo ${users} | while read line; do
		while true; do
			breakout=1
			acct=$(echo ${line} | awk -F ',' '{print $1;}')
			haslicense=$(echo ${line} | grep -Fi "google vault")
			if [ -z "${haslicense}" ]; then
				break
			fi

			exportname="export-mail-${acct:gs/@/_}"

			mkdir -p ${odir}/${matter}/${acct}

			log_info_arg "[+] Downloading ${acct} mail to ${odir}/${matter}/${acct}"

			output=$(${GAM} download export ${matter} \
			    ${exportname} \
			    noextract \
			    targetfolder ${odir}/${matter}/${acct} 2>&1)
			res=${?}
			log_debug_arg "${output}"
			if [ ${res} -gt 0 ]; then
				rcode=$(response_get_error_code "${output}")
				echo "[-] rcode is \"${rcode}\""
				if [ ${rcode} -eq 429 ]; then
					log_info_arg "[*] Quota exceeded. Retrying after 20 minutes."
					sleep $((20 * 60))
					breakout=0
				else
					return ${res}
				fi
			fi

			log_debug_arg "[*] Sleeping for $(config_get_value sleep) seconds due to API quota."
			sleep $(config_get_value sleep)
			if [ ${breakout} -gt 0 ]; then
				break
			fi
		done
	done

	return 0
}
