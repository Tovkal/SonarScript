#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 0
fi

SKIPCOVERAGE=false
BRANCH=""
FRONT=false
BEEP=false

while [[ $# > 0 ]]
do
	key="$1"

	case $key in
		-sc|--skipcoverage)
		SKIPCOVERAGE=true
		;;
		-b|--branch)
		BRANCH="$2"
		;;
		-f|--front)
		FRONT=true
		;;
		-p|--beep)
		BEEP=true
		;;
		-h|--help)
		echo "$(basename "$0") [-h] [-sc -b -f -p] BRANCH_NAME"
		echo
		echo "Calling $(basename "$0") BRANCH_NAME will do a full analysis, including coverage."
		echo
		echo "The following flags can also be used:"
		echo
		echo "	-sc, --skipcoverage		skip coverage analysis"
		echo "	-b, --branch			branch to analyze"
		echo "	-f, --front			use Front's custom sonar profile"
		echo "	-p, --beep			beep when done"
		echo
		echo "The script beeps upon completion." 
		echo "If the command 'beep' does not work, 'sudo modprobe pcspkr' must be run first." 
		echo "To make it persistent between reboots, comment out the line 'blacklist pcspkr' in '/etc/modprobe.d/blacklist.conf'."
		exit 0
		;;
		--default)
		;;
		*)
		BRANCH=$1
			## unknown option
		;;
	esac
	shift
done

if [ -z "$BRANCH" ]; then
	echo "A branch name must be supplied either using the -b flag: 	$(basename $0) -b BRANCH_NAME"
	echo "or directly after the command: 					$(basename $0) BRANCH_NAME"
	exit 0
fi


# Step 1: Clean install
echo "Starting clean install"
echo

mvn clean install
if [ "$?" -ne 0 ]; then
	echo "Clean install unsuccessful"
	exit 1
fi

# Step 2: Coverage
if [[ "$SKIPCOVERAGE" = false ]]; then

	echo "Doing coverage analysis"
	echo

	mvn cobertura:cobertura -Dcobertura.report.format=XML
	if [ "$?" -ne 0 ]; then
	        echo "Coverage analysis unsuccessful"
	        exit 1
	fi
fi


# Step 3: Sonar
echo "Starting sonar build"
echo

if [[ "$FRONT" = false ]]; then
	mvn sonar:sonar -Dsonar.branch="$BRANCH"
else
	mvn sonar:sonar -Dsonar.profile="Barcelo_Front" -Dsonar.branch="$BRANCH"
fi

if [ "$?" -ne 0 ]; then
        echo "Sonar build unsuccessful"
        exit 1
fi

beep