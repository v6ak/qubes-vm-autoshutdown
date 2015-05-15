#!/bin/bash
cd "$(dirname "$0")"
(
	while true; do
		./poll.sh
		sleep 600
	done
) &> ~/autoshutdown.log&
