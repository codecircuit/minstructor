#!/bin/bash


## CASE 1 ##
output=$(ruby minstructor.rb -c "./foo -key0 bar --key1 [a,b,7] --key3 range(3,5)" \
         --backend slurm -o ./outfile --dry-run -f)

corrCmds=( \
'sbatch  --wrap "./foo -key0 bar --key1 a --key3 3" -o ./outfile_0.txt' \
'sbatch  --wrap "./foo -key0 bar --key1 a --key3 4" -o ./outfile_1.txt' \
'sbatch  --wrap "./foo -key0 bar --key1 b --key3 3" -o ./outfile_2.txt' \
'sbatch  --wrap "./foo -key0 bar --key1 b --key3 4" -o ./outfile_3.txt' \
'sbatch  --wrap "./foo -key0 bar --key1 7 --key3 3" -o ./outfile_4.txt' \
'sbatch  --wrap "./foo -key0 bar --key1 7 --key3 4" -o ./outfile_5.txt')

for corrCmd in "${corrCmds[@]}"; do
	if [[ -z $(echo "$output" | grep "$corrCmd") ]]; then
		echo "Could not find $corrCmd"
		echo "$output"
		echo "Test failed!"
		exit 1
	fi
done

## CASE 2 ##
output=$(ruby minstructor.rb -c "./foo -key0 bar --key1 a --key3 logspace(1,2,2,10)" \
         --backend slurm -o ./outfile -n 3 --dry-run -f)

numSbatch=$(echo "$output" | grep -c "sbatch")
if [[ $numSbatch == 0 ]]; then
	echo "slurm backend failed!"
	exit 1
fi

## CASE 3 ##
output=$(ruby minstructor.rb -c "./foo -key0 bar --key1 [a,b,7] --key3 range(3, 5)" \
         --backend slurm -o ./outfile --dry-run -f)

echo ""
echo "TEST CASE 3"
echo "$output"

echo "Test passed!"
