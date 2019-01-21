#!/bin/bash

set -e

#su oracle -c 'cd /home/oracle/database && ./runInstaller -ignorePrereq -ignoreSysPrereqs -silent -responseFile /install/oracle-11g-ee.rsp -waitForCompletion 2>&1'

#/u01/app/oraInventory/orainstRoot.sh
#/u01/app/oracle/product/11.2.0/EE/root.sh


$ORACLE_HOME/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname ORCL -sid ORCL -responseFile NO_VALUE -totalMemory 2048 -emConfiguration LOCAL  -sysPassword oracle -systemPassword oracle -dbsnmpPassword oracle
