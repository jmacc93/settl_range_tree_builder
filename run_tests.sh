#!/bin/bash

dmd -lowmem -g -debug -main -of=range_tree_builder_unittests range_tree_builder.d lib.d tree.d progressive_partition.d

./range_tree_builder_unittests

dmd -lowmem -g -debug -version=rangeTreeBuilderMain -of=range_tree_builder_main_tests range_tree_builder.d lib.d tree.d progressive_partition.d

# Note: uncomment the following line when something goes wrong
# verbosityValue="--verbosity=all"

echo "================"
echo "Running test 1:"
echo "io json"
./range_tree_builder_main_tests $verbosityValue --patterns test_patterns.json --input test_input.json --output "range_tree_builder_test_output1.json"

cmp --silent range_tree_builder_test_output1.json test_correct_output.json || echo -e "\033[31m Test 1 didn't produce the correct output \033[0m"


echo "==============="
echo "Running test 2:"
echo "io txt"
./range_tree_builder_main_tests $verbosityValue --patterns test_patterns.txt --input test_input.txt --output "range_tree_builder_test_output2.json"

cmp --silent range_tree_builder_test_output1.json test_correct_output.json || echo -e "\033[31m Test 2 didn't produce the correct output \033[0m"

echo "==============="
echo "Running test 3:"
echo "piping, stdin is json"
cat test_input.json | ./range_tree_builder_main_tests $verbosityValue --patterns test_patterns.json > range_tree_builder_test_output3.json

cmp --silent range_tree_builder_test_output1.json test_correct_output.json || echo -e "\033[31m Test 3 didn't produce the correct output \033[0m"

echo "==============="
echo "Running test 4:"
echo "piping, stdin is lineseq"
cat test_input.txt | ./range_tree_builder_main_tests $verbosityValue --lineseq --patterns test_patterns.json > range_tree_builder_test_output4.json

cmp --silent range_tree_builder_test_output1.json test_correct_output.json || echo -e "\033[31m Test 4 didn't produce the correct output \033[0m"