#!/bin/bash -l

# invocation script meant to be launched from cron

LOGFILE="/var/tmp/rsync0.log"

if [[ -f /tmp/rsync-master-busy ]] ; then
	laststart=$(date -r /tmp/rsync-master-busy +%s)
	now=$(date +%s)
	# allow one run to be skipped quietly
	if [[ $((laststart + (40 * 60))) -lt ${now} ]] ; then
		echo "another rsync-master generation process is still busy"
		ps -ef | grep '[r]efresh-mirror'
		tail ${LOGFILE}
	fi
else
	mv ${LOGFILE} ${LOGFILE%.log}-prev.log
	cd "$(readlink -f "${BASH_SOURCE[0]%/*}")"
	touch /tmp/rsync-master-busy
	echo "starting generation $(date)" > ${LOGFILE}
	genandpush() {
		./update-rsync-master.sh \
			&& ./push-rsync1.sh
#			&& pushd /export/gentoo/statistics/stats \
#			&& ./gen-timing-rsync0-graph.sh \
#			&& popd > /dev/null
	}
	(((genandpush | tee -a "${LOGFILE}") 3>&1 1>&2 2>&3 \
	    | tee -a "${LOGFILE}") 2> /dev/null)
	echo "generation done $(date)" >> ${LOGFILE}
	rm -f /tmp/rsync-master-busy
fi