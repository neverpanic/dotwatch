#!/bin/bash

set -e

dir="$1"
if [ ! -d "${dir}" ]; then
	echo "No such directory: ${dir}" >&2
	exit 1
fi

fulldir="$(cd "$dir" && pwd)"
md5="$(echo "${fulldir}" | md5sum | grep -o '[a-f0-9]\+')"

configpath="${HOME}/.dotwatchd/${HOSTNAME}"
mkdir -p "${configpath}"

pidfile="${configpath}/${md5}.pid"
if [ -f "${configpath}/${md5}.pid" ]; then
	otherpid=$(cat "${configpath}/${md5}.pid")
	echo "dotwatchd already running for ${fulldir} in pid ${otherpid}" >&2
	exit 1
fi
echo "$$" >"${pidfile}"

watchfile="${configpath}/${md5}"
if [ -f ${configpath}/${md5} ]; then
	echo "Watchfile for the following files still exists:" >&2
	cat "${watchfile}" >&2
	echo -n "clear watchfile? [Y/n]: "
	read answer
	if [ "${answer}" != "n" ]; then
		>"${watchfile}"
	fi
fi

sigterm() {
	echo "Signal received, shutting down" >&2
	kill "${procpid}" || ((echo "Waiting..." >&2) && sleep 2 && (echo "Sending kill" >&2) && kill -9 "${procpid}")
	rm -f "${pidfile}"
	echo "Exit" >&2
	exit 0
}

trap 'sigterm' SIGTERM SIGINT

inotifywait -e CLOSE_WRITE --format '%f' -m "${fulldir}" 2>/dev/null | while read file; do
	set +e
	grep "${file}" "${watchfile}" >/dev/null
	if [[ $? == 0 ]]; then
		# matched, build pdf
		echo "rebuilding ${file}.pdf"
		cd "${fulldir}" && dot -Tpdf "${file}" >"${file}.pdf" && (evince "${file}.pdf" &>/dev/null &)
	fi
done &

procpid="$!"

wait "${procpid}"
