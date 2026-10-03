#!/usr/bin/env bash

source ./libs/iobits.sh
source ./libs/databits.sh

# called as `monitor [ period numsamples ]`
function monitor() {
    local period=${1:-"0.25"}
    local -i lines columns rr samples=${2:-4}
    local -i lines columns
    local sleeper
    # all of these are used, mostly as name-refs, shellcheck doesn't see this
    local -A start_sample cur_sample prev_sample diffs diffstats=()
    local -a prefixes

    # we need to know the size of the screen, force Bash to give it to us, even in
    # a non-interactive shell
    init_term lines columns

    # need this for the waiter
    exec {sleeper}<> <(:)

    # initial sample
    load_data start_sample
    
    # get a list of unique data prefixes -- this should be, eg: `cpu`, `cpu0`, etc...
    uniq_prefixes start_sample prefixes

    # the starting sample is the previous sample
    prev_sample=()
    copy_array start_sample prev_sample
    
    # pause for the specified inter-sample period
    timeout "${sleeper}" "${period}"

    # next sample
    load_data cur_sample

    # start the loop    
    for (( rr = 1; rr < samples; rr++)); do
	local -i idx icount=${#prefixes[@]}
	for (( idx = 0; idx < icount; idx++ )); do
	    local __K id="${prefixes[${idx}]}"
	    
	    # reset this prior to every sample
	    diffs=()

	    # calculate the differences
	    calc_single "${id}" prev_sample cur_sample diffs
	    for __K in "user" "system" "idle" "total"; do
		local _fk="${id},${__K}"
		# shellcheck caught an error here, make _sure_ that we always
		# have the double brackets/parens on all short-circuit checks
		[[ -v diffstats["${_fk}"] ]] || diffstats["${_fk}"]=0
		local -i temp=${diffstats["${_fk}"]}
		temp+=${diffs["${__K}"]}
		diffstats["${_fk}"]=$temp
	    done
	done
	# pause before the next sample
	timeout ${sleeper} ${period}
	copy_array cur_sample prev_sample
	load_data cur_sample
	print_table diffstats $lines $columns
    done
}

# test drive
# 40 samples, quarter-second between them
monitor 0.25 120
