#!/bin/bash
# This script simply takes it input parameters and
# generates some random output with them. It should
# resemble the output of an example application.
# Moreover it saves the command line parameters with
# which it have been called in a file
# ./dummy-script-executions.txt

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "$@" >> ${DIR}/dummy-script-executions.txt

# Now we wan to detect the flags and the values the script
# has been called with. We say that a flag is a command line
# parameter with at least one '-' sign in the front, but
# without subsequent numbers, thus '-9foo' will not be detected
# as a command line argument, but as a value, whereas '-foo',
# will be detected as a command line flag.

args=($@)
types=()
while [[ -n "$1" ]]; do
	currArg="$1"
	if [[ -n `echo "$currArg" | grep -E "^-"` ]]; then
		if [[ ${#currArg} -gt 1 ]]; then
			if [[ -z `echo "${currArg[2]}" | grep -E "[0-9]"` ]]; then
				types=(${types[@]} "flag")
			else
				types=(${types[@]} "value")
			fi
		fi
	else
		types=(${types[@]} "value")
	fi
	shift
done

# We generate some exemplaric output
echo "# DUMMY SCRIPT EXECUTION OUTPUT"
echo "TODO enter lorem ipsum text here"
echo ""
echo "## Command line parameters"
echo "Now we iterate over the given parameters"
echo "number of Args = ${#args[@]}"
echo ""
for i in `seq 0 $((${#args[@]} - 1))`; do
	if [[ "${types[$i]}" == "flag" ]]; then
		argCropped=$(echo "${args[$i]}" | sed 's/^-\+//g')
		echo "  - cmd arg nr $i: cmd-arg-$argCropped = ${args[$(($i+1))]}"
	fi
done

# Generate some random output
echo ""
echo "## Some random output"
echo "  - exampleKey0 -> importantValue"
printf "    anotherKey3  :  \t -00.654678  seconds\n"
printf "\t important-key7   =   -86487  16674  whateverUnit\n"
printf " --- finally-key99 \t ---> +0.6874e-08  the answer to everything is 42\n"
echo "  smallkeyword  =    +7.68416e+684465 woow that is a large number"
echo ""

