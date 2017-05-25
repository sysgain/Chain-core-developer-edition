#!/bin/bash
##############################################
# Parameters
##############################################
# Validate that all arguments are supplied

if [ $# -lt 10 ]; then echo "Insufficient parameters supplied. Exiting"; exit 1; fi

AZUREUSER=$1;
BASE_URL=$2
SCRIPTNAME=$3

###############################################
# Constants
###############################################
HOMEDIR="/home/$AZUREUSER";
CONFIG_LOG_FILE_PATH="$HOMEDIR/config.log";

###############################################
# Get the script for running as Azure user
###############################################

cd "/home/$AZUREUSER";

sudo -u $AZUREUSER /bin/bash -c "wget -N ${BASE_URL}/scripts/${SCRIPTNAME}";
cat ${SCRIPTNAME} | tr -d '\r' > new${SCRIPTNAME}

###############################################
# Initiate loop for error checking
###############################################

for LOOPCOUNT in `seq 1 5`; do
    if [ "new$SCRIPTNAME" = "newgenerator-script.sh" ]; then
       sudo -u $AZUREUSER /bin/bash /home/$AZUREUSER/newgenerator-script.sh "$4" "$5" "$6" "$7" "$8" "$9" "${10}" >> $CONFIG_LOG_FILE_PATH 2>&1;
    elif [ "new$SCRIPTNAME" = "newsigner-script.sh" ]; then
       sudo -u $AZUREUSER /bin/bash /home/$AZUREUSER/newsigner-script.sh "$4" "$5" "$6" "$7" "$8" "$9"  "${10}" "${11}">> $CONFIG_LOG_FILE_PATH 2>&1;
    elif [ "new$SCRIPTNAME" = "newparticipant-script.sh" ]; then
       sudo -u $AZUREUSER /bin/bash /home/$AZUREUSER/newparticipant-script.sh "$4" "$5" "$6" "$7" "$8" "$9" "${10} "${11}"">> $CONFIG_LOG_FILE_PATH 2>&1;
    else
      exit 1
    fi
    	
	if [ $? -ne 0 ]; then
		echo "Command failed on try $LOOPCOUNT, retrying..." >> $CONFIG_LOG_FILE_PATH;
		sleep 5;
		continue;
	else
		echo "======== Deployment successful! ======== " >> $CONFIG_LOG_FILE_PATH;
		exit 0;
	fi
done

echo "One or more commands failed after 5 tries. Deployment failed." >> $CONFIG_LOG_FILE_PATH;
exit 1
