#!/bin/bash

# Check if the correct number of arguments was provided
if [ $# -ne 3 ]; then
  # Display usage information if arguments are missing or too many
  echo "Usage: $0 SRC_PATH DST_PATH TARGET_PERCENTAGE"
  echo "  SRC_PATH: The path to the source directory."
  echo "  DST_PATH: The path to the destination directory."
  echo "  TARGET_PERCENTAGE: The target percentage of used space on the source (an integer between 0 and 100)."
  exit 1
fi

# Set the source and destination paths
# from the command line arguments
src=$1
dst=$2

# Set the target percentage of used space on the source
# from the command line arguments
target=$3

# Check if the target percentage is an integer between 0 and 100
if ! [[ $target =~ ^[0-9]+$ ]] || [ $target -lt 0 ] || [ $target -gt 100 ]; then
  # Display usage information if the target percentage is invalid
  echo "Error: The target percentage must be an integer between 0 and 100."
  echo "Usage: $0 SRC_PATH DST_PATH TARGET_PERCENTAGE"
  echo "  SRC_PATH: The path to the source directory."
  echo "  DST_PATH: The path to the destination directory."
  echo "  TARGET_PERCENTAGE: The target percentage of used space on the source (an integer between 0 and 100)."
  exit 1
fi

# Get the current usage percentage on the source
src_usage_percent=$(df $src | awk 'NR==2 {print $5}' | sed 's/%//')

# Check if the target percentage is already reached
if [ "$src_usage_percent" -le "$target" ]; then
  exit 0
fi

# Calculate target usage in bytes
src_target_bytes=$(( $(df -k /home | awk 'NR==2 {print $2*1024}') * target / 100 ))

# Get the largest file in the source directory
# and store its path in a variable
largest_file=$(find $src -type f -printf "%s %p\n" | sort -nr | head -n 1 | cut -d' ' -f2)

# Get the size of the largest file in bytes
largest_file_size=$(find $src -type f -printf "%s %p\n" | sort -nr | head -n 1 | cut -d' ' -f1)

# Check if the largest file fills the folder
# beyond the target by itself and
# move it if it does
while [ "$largest_file_size" -gt "$src_target_bytes" ]; then
  # Move the largest file from the source to the destination
  mv $largest_file $dst

  # Create symbolic link from source to destination
  ln -s $dst/$(basename $largest_file) $src/$(basename $largest_file)

  # Update the usage percentage on the source
  src_usage_percent=$(df $src | awk 'NR==2 {print $5}' | sed 's/%//')

  # Check if the target percentage is reached
  if [ "$src_usage_percent" -le "$target" ]; then
    exit 0
  fi

  # Get the largest file in the source directory
  # and store its path in a variable
  largest_file=$(find $src -type f -printf "%s %p\n" | sort -nr | head -n 1 | cut -d' ' -f2)

  # Get the size of the largest file in bytes
  largest_file_size=$(find $src -type f -printf "%s %p\n" | sort -nr | head -n 1 | cut -d' ' -f1)
done



# Get the least accessed files in the source directory
# and store their paths in an array
files=($(find $src -type f -printf "%T@ %p\n" | sort -n | cut -d' ' -f2))

# Move the least accessed files from the source to the destination
# and create symlinks for each file
for file in "${files[@]}"; do
  # Move file from source to destination
  mv $file $dst

  # Create symbolic link from source to destination
  ln -s $dst/$(basename $file) $src/$(basename $file)

  # Update the usage percentage on the source
  src_usage_percent=$(df $src | awk 'NR==2 {print $5}' | sed 's/%//')

  # Check if the target percentage is reached
  if [ "$src_usage_percent" -le "$target" ]; then
    exit 0
  fi
done
