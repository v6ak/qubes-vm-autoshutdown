#!/bin/bash
# safety settings
set -u # Not strictly needed, but it is safer
set -e # NEEDED for safety and security!
set -o pipefail # Not strictly needed, but it is safer

declare -A callbacks
declare -A ids

function add_check {
	name="$(
		if [ "$1" == "*" ]; then
			printf "all"
		else
			printf "vm_%s" "$1"
		fi
	)"
	nextid=${ids[$name]:-0}
	ids[$name]=$(($nextid+1))
	callbacks["${name}_$nextid"]="$2"
	#echo "Assigning $name#$nextid…"
}

function is_active {
	key="$1"
	vm="$2"
	maxid=$((${ids[$key]:-0}-1))
	#echo "key: $key vm: $vm maxid: $maxid"
	if [ "$maxid" != -1 ]; then
		for i in $(seq 0 $maxid); do
			cbid="${key}_$i"
			#echo maxid: $maxid cbid: $cbid
			#echo "Checking $vm/$key: ${callbacks[$cbid]}…"
			if ${callbacks[$cbid]} "$vm"; then
				return 0
			fi
		done
	fi
	return 1
}

function is_vm_active {
	name="$1"
	if is_active "all" "$name" || is_active "vm_$name" "$name"; then
		return 0
	else
		return 1
	fi
}

function qvm-ls-running { # Very hacky and might fail in some edge cases, but it is the faster way I've found
	qvm-ls | grep -E '\| +Running +\|' | sed 's/^ \+[=>\[{]*//' | sed 's/ .*$//' | tr ']' '}' | sed 's/}$//'
}

for i in activity.d/*; do
	. "$i"
done


#for i in "${!callbacks[@]}"; do
#	echo "$i: ${callbacks[$i]}"
#done
#echo  "------------"
#
#for i in "${!ids[@]}"; do
#	echo "$i: ${ids[$i]}"
#done


MEASUREMENTS_BEFORE_SHUTDOWN_DELAY=1
MEASUREMENTS_BEFORE_SHUTDOWN_COUNT=30

#qvm-ls --raw-list
qvm-ls-running | (
	while read name; do
		#if qvm-ls "$name" | grep '| Running |' > /dev/null; then
		if true; then
			echo -n "* $name:"
			if is_vm_active "$name"; then
				echo ACTIVE
			else
				active=0
				for measId in $(seq $MEASUREMENTS_BEFORE_SHUTDOWN_COUNT); do
					echo -n .
					if is_vm_active "$name"; then
						active=1
						break;
					fi
					sleep $MEASUREMENTS_BEFORE_SHUTDOWN_DELAY
				done
				if [ "$active" = 1 ]; then
					echo "ACTIVE!"
				else
					echo
					# FIXME: Potential race condition
					# Hard to fix without using some Qubes internals
					qvm-shutdown "$name"
				fi
			fi
		fi
	done
)
