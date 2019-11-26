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

GAM="${HOME}/projects/GAM/src/gam.py"

batchstep=15
matter="migration-$(date '+%F_%T')"
odir="/tank/export"

get_topdir() {
	local self

	self=${1}

	echo $(realpath $(dirname ${self}))
	return ${?}
}

TOPDIR=$(get_topdir ${0})

. ${TOPDIR}/../lib/email.zsh
. ${TOPDIR}/../lib/util.zsh

main() {
	local res
	local self
	local verb

	self=${1}
	shift

	verb=${@[${OPTIND}]}
	[ -z "${verb}" ] && usage ${self}
	shift
	sanity_checks ${self} ${verb} || exit 1

	${GAM} create vaultmatter \
	    name ${matter} \
	    description "Vault export"
	res=${?}
	if [ ${res} -gt 0 ]; then
		return ${res}
	fi

	sleep 60

	$(echo ${verb}_run) $@
	res=${?}

	cleanup

	return ${res}
}

main ${0} $*
exit ${?}
