#!/bin/bash
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2016 Oracle and/or its affiliates. All rights reserved.
# 
# Since: November, 2016
# Author: gerald.venzl@oracle.com
# Description: Creates an Oracle Database based on following parameters:
#              $ORACLE_SID: The Oracle SID and CDB name
#              $ORACLE_TOTALMEMORY: The Oacle totalmemory
#              $ORACLE_PWD: The Oracle password
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

set -e

# Check whether ORACLE_SID is passed on
export ORACLE_SID=${1:-ORCL}

# Auto generate ORACLE PWD if not passed on
export ORACLE_PWD=${2:-"`openssl rand -base64 8`1"}
echo "ORACLE PASSWORD FOR SYS and SYSTEM : $ORACLE_PWD";

# 自动配置内存设置
export ORACLE_TOTALMEMORY=${3:-2048}

# 设置数据库字符集
export ORACLE_CHARACTERSET=${4:-AL32UTF8}

# Replace place holders in response file
cp $ORACLE_BASE/$CONFIG_RSP $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_SID###|$ORACLE_SID|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_PWD###|$ORACLE_PWD|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_CHARACTERSET###|$ORACLE_CHARACTERSET|g" $ORACLE_BASE/dbca.rsp
sed -i -e "s|###ORACLE_TOTALMEMORY###|$ORACLE_TOTALMEMORY|g" $ORACLE_BASE/dbca.rsp

# If there is greater than 8 CPUs default back to dbca memory calculations
# dbca will automatically pick 40% of available memory for Oracle DB
# The minimum of 2G is for small environments to guarantee that Oracle has enough memory to function
# However, bigger environment can and should use more of the available memory
# This is due to Github Issue #307
if [ `nproc` -gt 8 ]; then
   #sed -i -e "s|totalMemory=2048||g" $ORACLE_BASE/dbca.rsp
   sed -i -e "s|TOTALMEMORY=$ORACLE_TOTALMEMORY||g" $ORACLE_BASE/dbca.rsp
   sed -i -e "s|AUTOMATICMEMORYMANAGEMENT = FALSE|AUTOMATICMEMORYMANAGEMENT = TRUE|g" $ORACLE_BASE/dbca.rsp
fi;

# Create network related config files (sqlnet.ora, tnsnames.ora, listener.ora)
mkdir -p $ORACLE_HOME/network/admin
echo "NAME.DIRECTORY_PATH= (TNSNAMES, EZCONNECT, HOSTNAME)" > $ORACLE_HOME/network/admin/sqlnet.ora
# Listener.ora
echo "LISTENER = 
(DESCRIPTION_LIST = 
  (DESCRIPTION = 
    (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1)) 
    (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521)) 
  ) 
) 
ADR_BASE_LISTENER = $ORACLE_BASE
" > $ORACLE_HOME/network/admin/listener.ora
#
mkdir -p $ORACLE_BASE/fast_recovery_area
# Start LISTENER and run DBCA
lsnrctl start &&
dbca -silent -createDatabase -initParams java_jit_enabled=false -responseFile $ORACLE_BASE/dbca.rsp || cat $ORACLE_BASE/cfgtoollogs/dbca/$ORACLE_SID/$ORACLE_SID.log || cat $ORACLE_BASE/cfgtoollogs/dbca/$ORACLE_SID.log

#echo "$ORACLE_SID=localhost:1521/$ORACLE_SID" > $ORACLE_HOME/network/admin/tnsnames.ora
echo "$ORACLE_SID= 
(DESCRIPTION = 
  (ADDRESS = (PROTOCOL = TCP)(HOST = 0.0.0.0)(PORT = 1521))
  (CONNECT_DATA =
    (SERVER = DEDICATED)
    (SERVICE_NAME = $ORACLE_SID)
  )
)" >> $ORACLE_HOME/network/admin/tnsnames.ora

# add redo logs 
#sqlplus / as sysdba << EOF
#   ALTER DATABASE ADD LOGFILE GROUP 4 ('$ORACLE_BASE/oradata/$ORACLE_SID/redo04.log') SIZE 50m;
#   ALTER DATABASE ADD LOGFILE GROUP 5 ('$ORACLE_BASE/oradata/$ORACLE_SID/redo05.log') SIZE 50m;
#   ALTER DATABASE ADD LOGFILE GROUP 6 ('$ORACLE_BASE/oradata/$ORACLE_SID/redo06.log') SIZE 50m;
#   ALTER SYSTEM SWITCH LOGFILE;
#   exit;
#EOF

# Remove temporary response file
rm $ORACLE_BASE/dbca.rsp
