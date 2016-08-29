#!/bin/bash
#!/usr/bin/env bats

##### Configurations ###
STOCKED_BILLS=10 					# The number of stocked bills
DOLLAR_AMOUNTS=(100 50 20 10 5 1) 	# Lets us dicated dollar amounts allowed.
CURRENCY_SYMBOL="$" 				# Selected readable currency symbol
MACHINE_BALANCE=() 					# Holds associative array of dollar amounts
TEMP_BALANCE=() 					# Temporary storage for possible updated balance
WITHDRAWL_REQUEST=0					# Amount the user is requing to withdrawl

### Helper Funcions ###
showBalance()
{
  echo ""
  echo "Machine balance:"
  dollarCount=${#MACHINE_BALANCE[@]}
  for(( i=0 ; i < ${dollarCount}; i++ ))
  do
  	echo ""
  	echo "${CURRENCY_SYMBOL}"${DOLLAR_AMOUNTS[$i]} - ${MACHINE_BALANCE[${DOLLAR_AMOUNTS[$i]}]}  
  done
}

setRemainingBalance()
{
    REMAINING_BALANCE=0
	for dollarInventory in ${!TEMP_BALANCE[@]} # Popuate TEMP_BALANCE array
	do
		REMAINING_BALANCE=$(( ${REMAINING_BALANCE} + ${dollarInventory} * ${TEMP_BALANCE[${dollarInventory}]} ))	
	done
}

withdrawl()
{
	withdrawlAmount=${1}

	if [ ${REMAINING_BALANCE} -ge ${withdrawlAmount} ]; then

		for dollarAmount in ${DOLLAR_AMOUNTS[@]}
		do

			#echo "Withdrawl Request " ${withdrawlAmount}
			if [ ${withdrawlAmount} == 0 ]; then
				#echo "Remaining Balance" ${REMAINING_BALANCE}
				break;
			fi

			modulus=$(( ${withdrawlAmount} % ${dollarAmount} ))
			billsAvailable=${TEMP_BALANCE[${dollarAmount}]}
			billsNeeded=$((${withdrawlAmount} / ${dollarAmount}))
			billsDifference=$(( ${billsAvailable} -  ${billsNeeded} ))

			if [ ${modulus} != ${withdrawlAmount} ] && [ billsAvailable != 0 ]; then

				if [ ${billsDifference} -lt 0 ]; then

					amountToWithdraw=$(( ${TEMP_BALANCE[${dollarAmount}]} * ${dollarAmount} ))
					TEMP_BALANCE[${dollarAmount}]=0

				elif [ ${billsDifference} -gt -1 ]; then

					amountToWithdraw=$(( ${billsNeeded} * ${dollarAmount} ))
					TEMP_BALANCE[${dollarAmount}]=${billsDifference}
				fi


				#echo "Amount to Withdrawl " ${amountToWithdraw}
				withdrawlAmount=$(( ${withdrawlAmount} - ${amountToWithdraw} ))

				setRemainingBalance

			fi
		done

		if [ ${withdrawlAmount} != 0  ]; then
			echo ""
			echo "Failure: Insufficient funds. The system needs to be reloaded."		
		else
			echo ""
			echo "Success Dispensed ${CURRENCY_SYMBOL}"${WITHDRAWL_REQUEST}

			# Update machine balance because we were successful.
			for i in ${!TEMP_BALANCE[@]}; do
			    MACHINE_BALANCE[$i]="${TEMP_BALANCE[$i]}"
			done
		fi

		showBalance 

	else
		echo ""
		echo "Failure: Insufficient funds"
	fi
}

reload()
{
	for amount in ${DOLLAR_AMOUNTS[@]} # Popuate MACHINE_BALANCE array
	do
		MACHINE_BALANCE[$amount]=${STOCKED_BILLS}
		TEMP_BALANCE[$amount]=${STOCKED_BILLS}
	done

	setRemainingBalance # Update our known balance
} 

inquire()
{
	
	balance=${MACHINE_BALANCE[${1}]}
	if [ -z ${balance} ]; then
		echo "Failure: Invalid inquiry amount."
	else
		echo "${CURRENCY_SYMBOL}"${1} - ${MACHINE_BALANCE[${1}]} 
	fi	
}

# Start
reload
echo "Welcome to the cash machine. Please enter a command......"

while read line
do

	

	userInput=${line::1}
	value=$(echo ${line}| cut -d'$' -f 2 -s) # Strip the dollar sign out value
	re='^[0-9]+$'

	if [ -z ${userInput} ]; then
		echo "The input that you've entered is not a valid."
	else
		case ${userInput} in
	    "w" | "W")
			

			if [ -z ${value} ] || ! [[ $value =~ $re ]]; then
				echo ""
				echo "Failure: Invalid Command"
			else

				# Most efficient way for copying associative array
				for i in ${!MACHINE_BALANCE[@]}; do
				    TEMP_BALANCE[$i]="${MACHINE_BALANCE[$i]}"
				done

				WITHDRAWL_REQUEST=${value}
				withdrawl ${value}
			fi
			;;
		"r" | "R")
			reload
			;;
		"i" | "I")
				for inputAmount in ${line} 
				do
					amount=$(echo ${inputAmount}| cut -d'$' -f 2 -s) # Strip the dollar sign out value
					if ! [ -z ${amount} ] || [[ $amount =~ $re ]]; then
						inquire ${amount}
					fi				
				done				
		
			;;
		"q" | "Q")
			exit
			;;
		*)
		 	echo "Failure: Invalid Command"
		  ;;
		esac
	fi
done


#Unit Tests
@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}
