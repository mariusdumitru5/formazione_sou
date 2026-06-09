#!/usr/bin/env bash
# Naked variables

echo

# When is a variable "naked", i.e., lacking the '$' in front?
# When it is being assigned, rather than referenced.

# Assignment
a=879
echo "The value of \"a\" is $a."

# Assignment using 'let'
# let is used for integer operations
let a=16+5
echo "The value of \"a\" is now $a."

echo

# print the values of a in a for loop
echo -n "Values of \"a\" in the loop are: "
for a in 7 8 9 11
do
  # -n is for no special characters: \n
  echo -n "$a "
done

echo
echo

# In a 'read' statement (also a type of assignment):
echo -n "Enter \"a\" "
read a
echo "The value of \"a\" is now $a."

echo

exit 0 
