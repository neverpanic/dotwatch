#!/bin/bash

dir="$(dirname "$1")"
file="$(basename "$1")"

fulldir="$(cd "${dir}" && pwd)"
md5="$(echo "${fulldir}" | md5sum | grep -o '[0-9a-f]\+')"

configpath="${HOME}/.dotwatchd/${HOSTNAME}"
pidfile="${configpath}/${md5}.pid"

if [ ! -f "${pidfile}" ]; then
	echo "Warning: dotwatchd not running for dir ${fulldir}" >&2
fi

watchfile="${configpath}/${md5}"
touch "${watchfile}"
grep "^${file}$" "${watchfile}" >/dev/null
if [[ $? != 0 ]]; then
	echo "Warning: watchfile for ${fulldir} did not contain ${file}" >&2
	exit 1
fi

cp "${watchfile}" "${watchfile}.old"
cat "${watchfile}.old" | grep -v "^${file}$" >"${watchfile}"
rm "${watchfile}.old"

echo "Removed ${file} from watchfile for ${fulldir}" >&2

