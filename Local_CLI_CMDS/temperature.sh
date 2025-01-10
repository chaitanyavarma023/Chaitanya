#!/bin/sh

# Run the thermaltool command for wifi0 and wifi1 and capture output
output_wifi0=$(thermaltool -i wifi0 -get -e 1)
output_wifi1=$(thermaltool -i wifi1 -get -e 1)

# Function to print the output with a table-like box
print_table_box() {
  # Print the top border of the table
  echo "|--------------------------------------------------------------------------------------------------"

  # Print each line of the original output, formatted within the box
  while IFS= read -r line; do
    # Print the line inside the box
    echo "| $line"
  done

  # Print the bottom border of the table
echo "|--------------------------------------------------------------------------------------------------"

}

# Output for wifi0
echo "Thermal Config for wifi0"
echo "$output_wifi0" | print_table_box
echo

# Output for wifi1
echo "Thermal Config for wifi1"
echo "$output_wifi1" | print_table_box
echo

