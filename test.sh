#!/bin/bash

## Base Variables
RUN_TASK=""
SOURCE_FILE=""
RUN_TESTS=false
ONE_YEAR=31536000
CURRENT_EPOC=$(date +%s)
NAMES=""
EXAMPLE_NAMES='Lincoln Harmon|02/02/1974
Terence Marshman|06/22/1976
Thea Blair|11/17/1982
Michael Gilbert|10/05/2001
Carly Craig|03/17/1991
Gene Woodward|12/02/2010
Audrey Bates|05/18/1976
Roderick Potter|01/19/2019
'

show_help(){
HELP="
This script is used to answer a coding execise I had to do.
An argument flag is required or you will just see this help prompt.

It is expected that a task is specified, however you can just run -t for the tests.

The follow options are available:

-h
  Shows this help screen.

--task [reader, booper]
  Runs the specified task.
  You can only specify one at a time.
    reader: requires a text file defined by --filename <path.to.file>
    booper: requires no extra input.

--filename
  Used with task \"reader\" to obtain the filename required.
  The format of the file is specific, use --example-file for a complete example.
  The file format must be:
    Name|month/day/year
    Name|month/day/year


--example-file
  prints output that can be used to create an example file for this script.
  example usage: test.sh --example-file > ./input.txt

-t or --run-tests
  Runs the internal code tests.
"
printf "$HELP"
}

# Check to see if there are arguments
# No arguments means we can not determine what needs to be done.
# Show a help message and exit out.
if [ $# -lt 1 ]; then
  show_help
  exit
fi

# Read the arguments passed in.
while test $# -gt 0; do
  case $1 in
    -h)
      # Standard help menu
      show_help
      exit
      ;;
    --task)
      # Determine which job needs to be run
      # If --task is specified we should check to see that a vaild option is specified here.
      shift
      if [[ -z $1 ]] || ! [[ "$1" =~ reader|booper ]]; then
        echo "Task value '$1' seems to be invalid."
        show_help
        exit
      fi

      RUN_TASK=$1
      ;;
    --filename)
      shift
      if [[ -z $1 ]]; then
        echo "No source file was specified."
        show_help
        exit
      fi

      SOURCE_FILE=$1
      ;;
    
    -t|--run-tests)
      RUN_TESTS=true
      ;;
    --example-file)
      echo "$EXAMPLE_NAMES"
      exit
      ;;
    *)
      break
      ;;
  esac
  shift
done

## Check for required task argument combonations
if [[ $RUN_TASK == "reader" ]] && [[ $SOURCE_FILE == "" ]]; then
  echo "Task $RUN_TASK spcified but no source file was specified."
  show_help
  exit
fi

# Create functions that will do the work
file_slurper(){
  if [ ! -f $1 ]; then
    echo "$1 is not a valid file"
    exit
  fi

  NAMES=$(cat $1)
}

booper(){
    if [[ `expr $1 % 100` -eq 0 ]]; then
        echo "beep boop"
    elif [[ `expr $1 % 20` -eq 0 ]]; then
        echo "boop"
    elif [[ `expr $1 % 5` -eq 0 ]]; then
        echo "beep"
    fi
}

sorter(){
  echo "$1" | sort
}

# Determine age based on date of birth
determine_age(){
  age_epoc=$(date -d $1 +%s)
  echo $(echo "($CURRENT_EPOC-$age_epoc)/$ONE_YEAR" | bc)
}

show_age(){
  # Set for to break lines not on spaces
  IFS=$'\n'
  for entry in $1; do
    # This looks like magic, but it just takes the values before and after the | 
    name=${entry%'|'*}
    date_of_birth=${entry#*'|'}

    age=$(determine_age $date_of_birth)
    echo "$name: $age"
  done
  unset IFS
}

show_average_age(){
  entry_count=$(echo "$1" | wc -l)
  all_ages=0
  IFS=$'\n'
  for entry in $1; do
    name=${entry%'|'*}
    date_of_birth=${entry#*'|'}
    age=$(determine_age $date_of_birth)
    let all_ages+=$age
  done
  unset IFS
  avg_years=$(echo "$all_ages/$entry_count" | bc)
  echo "The average age in years of all users is: $avg_years"
}

# Check what needs to be run
case $RUN_TASK in
  "booper")
    for i in $(seq 1 1000); do
      echo "$i: $(booper $i)"
    done
  ;;
  "reader")
    echo "Reading in file: $SOURCE_FILE"
    file_slurper $SOURCE_FILE

    echo "Sorting name:"
    sorter "$NAMES"
    echo ""
    echo "Show age in years for each entry"
    show_age "$NAMES"
    echo ""
    echo "Show average age in years"
    show_average_age "$NAMES"
  ;;
esac

# Because we are fancy we have tests that will determine if the code works.
# Bash code testing is a pain. So this might look a bit ugly.
if [ $RUN_TESTS == "true" ]; then
  # Test for beep boop functions
  echo '''
This test should result in the following when we loop over 1 to 1000
150 beeps
40 boops
10 beepboops

Running test....
'''
  beeps=0
  boops=0
  beepboops=0
  for i in $(seq 1 1000); do
      out=$(booper $i)
      if [[ -z $out ]]; then
          continue
      fi
      # count "beeps" 
      if [[ "$out" =~ ^beep$ ]]; then
          let beeps+=1
      fi
      # count "boops"
      if [[ "$out" =~ ^boop$ ]]; then
          let boops+=1
      fi
      # count "beep boops"
      if [[ "$out" =~ ^"beep boop"$ ]]; then
          let beepboops+=1
      fi
  done

  failure=false
  if [ $beeps -ne 150 ]; then
      echo "Not enough 'beep' detected. Got $beeps."
      failure=true
  fi
  if [ $boops -ne 40 ]; then
      echo "Not enough 'boop' detected. Got $boops."
      failure=true
  fi
  if [ $beepboops -ne 10 ]; then
      echo "Not enough 'beep boop' detected. Got $beepboops."
      failure=true
  fi

  if [ $failure == true ]; then
      echo "Failures detected, exiting..."
      exit
  else
      echo "Success:"
      echo "beeps $beeps, boops $boops, beepboops $beepboops"
  fi

  # Tests for date readers
  # The data being used is the example names which is also used to give the user
  # an example file.
  # If you change that expect these tests to fail.
  echo '
Testing the date reader functions now.
Output to follow as tests are run.
Running....

'
  failure=false

  # Sort by name
  echo "Sort entries in order"
  output=$(sorter "$EXAMPLE_NAMES")
  if [[ ! $(echo $output | head -n 1) =~ "Audrey Bates|05/18/1976" ]] && [[ ! $(echo $output | tail -n 1) =~ "Thea Blair|11/17/1982"\$ ]]; then
    echo "The order of the names is incorrect."
    failure=true
  else
    echo "The order is correct"
  fi
  echo "$output"
  echo ""

  echo "Determine ages:"
  output=$(show_age "$EXAMPLE_NAMES")
  if [[ ! $output =~ "Lincoln Harmon: 47" ]]; then
    echo "Failed to determine the correct age of Lincoln Harmon."
    failure=true
  else
    echo "Correctly determined the age of Lincoln Harmon."
  fi
  echo ""
  echo "$output"
  echo ""

  echo "Show Average Age"
  output=$(show_average_age "$EXAMPLE_NAMES")
  if [[ "$output" != "The average age in years of all users is: 26" ]]; then
    echo "failed to determine the average age of entries"
    failure=true
  else
    echo "The average age is correct."
  fi
  echo ""
  echo "$output"
  echo ""
  if [ $failure == true ]; then
    echo "Some tests failed for determining age. Exiting..."
    exit
  fi
fi
