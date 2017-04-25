#!/bin/bash
#Rebecca Kuensting
#344 - Operating Systems

#********************************************************************
# E X I T  C O D E S
#********************************************************************
SUCCESSFUL_EXECUTION=0
FAILED_EXECUTION=1

#********************************************************************
# T E M P  F I L E
# definition and cleanup
#********************************************************************
#temp_file holds the name of the temp file. The $$ is the process ID
temp_file="tempfile$$"

#Set a trap which, on interrupt, hangup, or termination, deletes the temporary file temp_file.
#trap "rm -f $temp_file; " EXIT INT HUP TERM
trap 'rm -f $temp_file temp_file; exit' INT HUP TERM
#trap 'rm -f temp*; exit' INT HUP TERM
#trap 'rm -f /tmp/xyz$$; exit' ERR EXIT

#********************************************************************
# U S A G E  F U N C T I O N
# Tells user how to call the function (prints to stderr by redirecting from stdout)
#********************************************************************
usage () {
	echo "The function takes the following parameters: $0 {-rows|-cols} [file]" 1>&2
}

#********************************************************************
# A R G U M E N T - R E L A T E D  E R R O R S
#********************************************************************
#********************************************************************
# Exit unsuccessfully if wrong number of arguments are given:
#********************************************************************
if [[ $# > 2 ]] || [[ $# < 1 ]]; then
	usage
	echo "Wrong number of arguments! Try again."
	exit $FAILED_EXECUTION
fi

#********************************************************************
# Check if file pointed at by argument 2 is readable, and string given
# for filename is not empty
#********************************************************************
if [[ $# == 2 && ! -z $2 && ! -r $2 ]]; then
	echo "$2 cannot be opened or doesn't exist! Please try again." 1>&2
	usage
	exit $FAILED_EXECUTION
fi

#********************************************************************
# O N E  A R G U M E N T (no file was given)
#********************************************************************
# Get user input

if [ $# == 1 ]; then
	   if [[ "$1" == -r* ]] || [[ "$1" == -c* ]]; then

		#printf "Input some integers separated by spaces, or <ENTER> for a new row\n"
		#put user input into temp_file
		while read input
		do
		   #printf "Keep going! Type ctrl+d when finished.\n"
		   echo $input >> temp_file
		   printf "\n"
		done

	   #otherwise, parameter 1 was not good:
	   else
		  echo "Bad arguments! Please try again." 1>&2
	
	      usage
	      exit $FAILED_EXECUTION
		  
		fi
fi

#********************************************************************
# P R O G R A M  B O D Y
#********************************************************************

#********************************************************************
# R O W S
#********************************************************************
#********************************************************************
# If the requested data is in rows: (user has passed -rows parameter)
#********************************************************************
if [[ "$1" == -r* ]]; then

	#print header and concatenate it to the temp file
	printf "\t* Average *\t* Median *\n" | cat >> $temp_file

   while read -r row
   do
	  #use wc -w to get word count of the whole line == number of elements
      elements=$(echo $row | wc -w)

    #*******************************************************************
	# Get the sum of this row
	#********************************************************************
      rowSum=0
      for each in $row
      do
		rowSum=$(expr $rowSum + $each)
      done

    #*******************************************************************
	# Get the average of this row
	#********************************************************************
      	#rounding!
	    checkRoundRow=$(expr $rowSum % $elements)
		moreThanHalf=$(expr $elements / 2)
	      if [[ $checkRoundRow > $moreThanHalf ]]; then
			rowAvg=$(expr $rowSum / $elements + 1)
		  else
			rowAvg=$(expr $rowSum / $elements)
	      fi
	  avgValue=$rowAvg

	#*******************************************************************
	# Get the median of this row
	#********************************************************************
      # use translate to replace all tabs with newlines
	  prepForSort=$(echo $row | tr "	" "\n")
	  
	  #for some reason it only works if I do it all on one line
	  sorted=$(echo $prepForSort | tr " " "\n" | sort -g)
	  oneLineSorted=$(echo $sorted | tr "\n" " ")
	  
      #Get the median (the midway point plus 1)
      halfList=$(expr $elements / 2)
	  medianIndex=$(expr $halfList + 1)
	  #use cut to get the value:
      medianValue=$(echo $oneLineSorted | cut -d " " -f $medianIndex)
	  
	  printf "\t$avgValue\t\t$medianValue\n" | cat >> $temp_file
	done < "${2:-/dev/stdin}" #Read from file or input

#********************************************************************
# C O L U M N S
#********************************************************************
#********************************************************************
# If the requested data is in cols: (user has passed -cols parameter)
#********************************************************************
elif [[ $1 == -c* ]]; then

	#print header and concatenate it to the temp file
	printf "* Averages: *\n" | cat >> $temp_file
	
	#find length for outer loop to run
	numRows=$(head -1 $2)
	
	lengthOfCols=0
	while read line
	do
		lengthOfCols=$(expr $lengthOfCols + 1)
	done < $2
	
	idx=0
	printed=0
	medianString=""

	for i in {1..$numRows}
	do
		colAvg=0
		colSum=0
		columnToString=""
		#making a manual interator because nothing else is working
		idx=$(expr $idx + 1)
		
		while read row 
		do
		#use wc -w to get word count of the whole line == number of elements
        elementsC=$(echo $row | wc -w)
		#printf "INDEX: $idx\n"
		
		# grab each row of data and clean it up
		cleanedRow=$(echo $row | tr "	" " ")
		#printf "CLEANEDROW: $cleanedRow\n"
		#use cut to get the value for the column:
        colVal=$(echo $cleanedRow | cut -d " " -f $idx)
		#printf "COLVAL: $colVal\n"
		
		columnToString+="$colVal "
		#printf "COLUMN: $columnToString\n"
		
		#*****************************************************************
		# Get the sum of this column
		#*****************************************************************
		colSum=$(expr $colSum + $colVal)
		#printf "COLSUM: $colSum\n"
		done < "${2:-/dev/stdin}"
		
		#*****************************************************************
		# Get the average of this column
		#*****************************************************************
		#rounding!
	    checkRound=$(expr $colSum % $lengthOfCols)
		moreThanHalf=$(expr $lengthOfCols / 2 - 1)
	      if [[ $checkRound > $moreThanHalf ]]; then
			colAvg=$(expr $colSum / $lengthOfCols + 1)
		  else
			colAvg=$(expr $colSum / $lengthOfCols)
	      fi
		
		#****************************************************************
		# Get the median of this column
		#****************************************************************
		# use translate to replace all tabs with newlines
		prepColSort=$(echo $columnToString | tr " " "\n")
		#printf "presort = $prepForSort\n"
	  
		#for some reason it only works if I do it all on one line
		sortedCol=$(echo $prepColSort | tr " " "\n" | sort -g)
		sortFinished=$(echo $sortedCol | tr "\n" " ")
		#printf "POST = $sortFinished\n"
	  
		#Get the median (the midway point plus 1)
		halfCol=$(expr $elementsC / 2)
		medianIndex=$(expr $halfCol + 1)
		#use cut to get the value:
		colMedianValue=$(echo $sortFinished | cut -d " " -f $medianIndex)
		
		printf "$colAvg\t" | cat >> $temp_file
		
		#using a string to store median values since I missed the memo about proper formatting and did it backwards
		medianString+="$colMedianValue\t"
	done
	
	printf "\n* Medians: *\n" | cat >> $temp_file
	printf "$medianString" | cat >> $temp_file
	
#if the user has reached this point, something is wrong. throw an error	
else
	usage
	exit $FAILED_EXECUTION
fi
	
#print output
cat $temp_file

#remove the output file
rm -f $temp_file
rm -f 'temp_file'