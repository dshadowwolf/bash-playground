#!/usr/bin/env bash

# abuse the `read` built-in to do a timeout
function timeout() {
    # timeout <fd> <period>
    read -r -t $2 -u $1
    return 0 # regardless of the result of `read` we have a success
}

# deep copy an array
# call as: `copy_array <source ref> <dest ref>`
# parameters are name-refs
function copy_array() {
    # copy_arraay <source> <dest>
    local -n _ca_src="$1"
    local -n _ca_dst="$2"

    _ca_dst=() # make sure the destination is clear
    
    local KEY

    for KEY in "${!_ca_src[@]}"; do
	_ca_dst["${KEY}"]=${_ca_src["${KEY}"]}
    done
    return 0
}

# calculate delta totals for a single entry (could be system total, could be a core)
# call as `calc_single <name> <prev ref> <current ref> <out parameter>`
# `name` is a string, all other parameters are name-refs
function calc_single() {
    local _cs_n="$1"
    local -n _cs_r1="$2"
    local -n _cs_r2="$3"
    local -n _d_out="$4"
    # actual field names
    local -a _cs_k=("user" "nice" "system" "idle" "iowait" "irq" "softirq" "steal" "guest" "guest_nice")
    local -i useracc=0
    local -i sysacc=0
    local -i idleacc=0
    local -i acc=0
    local _cs_kk
    
    for _cs_kk in ${_cs_k[*]}; do
	local _l_key="${_cs_n},${_cs_kk}" # create the lookup key
	local -i _l_val1=${_cs_r1["${_l_key}"]}   # extract previous runs value
	local -i _l_val2=${_cs_r2["${_l_key}"]}   # extract this runs value
	local -i _l_diff=$(($_l_val2 - $_l_val1)) # calc the diff
	acc+=$_l_diff # overall accumulator gets it all
	case "${_cs_kk}" in
	    user|nice)
		# user-mode times
		useracc+=$_l_diff
		;;
	    system|irq|softirq)
		# system times
		sysacc+=$_l_diff
		;;
	    idle|iowait)
		# io times
		idleacc+=$_l_diff
		;;
	    guest|guest_nice)
		# user-mode times but not quite
		useracc=$(($useracc - $_l_diff))
		;;
	    *)
		# ignore for now
		;;
	esac
    done
    
    _d_out["user"]=$useracc
    _d_out["system"]=$sysacc
    _d_out["idle"]=$idleacc
    _d_out["total"]=$acc
    return 0
}

# split a string at a comma and return the component to its left
# call as `cut_and_get_first_at_comma <string> <output parameter>`
# output parameter is a nameref
function cut_and_get_first_at_comma() {
    local ins="$1"
    local -n outs="$2"

    printf -v outs "%s" "${ins%%,*}"
    return 0
}

# collect only the truly unique prefix bits from an associative array
# where keys are in the form of 'unique part,shared part'
# call as `uniq_prefixes <nameref, input> <nameref, output>
function uniq_prefixes() {
    # uniq <input-assoc> <output-array>
    local -n _un_ins="$1"
    local -n _un_outs="$2"

    local KEY

    for KEY in ${!_un_ins[@]}; do
	local act_key
	cut_and_get_first_at_comma "${KEY}" act_key
	[[ " ${_un_outs[*]} " == *" ${act_key} "* ]] || _un_outs+=("${act_key}")
    done
    return 0
}
