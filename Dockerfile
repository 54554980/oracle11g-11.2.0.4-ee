# LICENSE UPL 1.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 11g Release 2
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) p13390677_112040_Linux-x86-64_1~7of7
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/database:11.2.0.4-${EDITION} . 
#
# Pull base image
# ---------------
FROM oraclelinux:7-slim AS base

# Maintainer
# ----------
MAINTAINER Carl <54554980@qq.com>

# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV ORACLE_BASE=/u01/app/oracle \
    ORACLE_HOME=/u01/app/oracle/product/11.2.0/db_1 \
    INSTALL_DIR=/u01/app/install \
    INSTALL_FILE_1="p13390677_112040_Linux-x86-64_1of7.zip" \
    INSTALL_FILE_2="p13390677_112040_Linux-x86-64_2of7.zip" \
    INSTALL_RSP="db_inst.rsp" \
    CONFIG_RSP="dbca.rsp.tmpl" \
    PWD_FILE="setPassword.sh" \
    RUN_FILE="runOracle.sh" \
    START_FILE="startDB.sh" \
    CREATE_DB_FILE="createDB.sh" \
    SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    CHECK_DB_FILE="checkDBStatus.sh" \
    USER_SCRIPTS_FILE="runUserScripts.sh" \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh"

# Use second ENV so that variable get substituted
ENV PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib

# Copy files needed during both installation and runtime
# -------------
COPY $SETUP_LINUX_FILE $CHECK_SPACE_FILE $INSTALL_DIR/
COPY $RUN_FILE $START_FILE $CREATE_DB_FILE $CONFIG_RSP $PWD_FILE $CHECK_DB_FILE $USER_SCRIPTS_FILE $ORACLE_BASE/

RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/$SETUP_LINUX_FILE && \
    rm -rf $INSTALL_DIR



#############################################
# -------------------------------------------
# Start new stage for installing the database
# -------------------------------------------
#############################################

FROM base AS builder

ARG DB_EDITION

# Install unzip for unzip operation
#RUN yum -y install unzip vi

ADD pn /usr/bin/pn
# Copy DB install file
COPY --chown=oracle:dba $INSTALL_FILE_1 $INSTALL_FILE_2 $INSTALL_RSP $INSTALL_DB_BINARIES_FILE $INSTALL_DIR/

# Install DB software binaries
USER oracle
RUN chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE $DB_EDITION



#############################################
# -------------------------------------------
# Start new layer for database runtime
# -------------------------------------------
#############################################

FROM base

USER oracle
COPY --chown=oracle:dba --from=builder $ORACLE_BASE $ORACLE_BASE

USER root
RUN $ORACLE_BASE/oraInventory/orainstRoot.sh && \
    $ORACLE_HOME/root.sh

USER oracle
WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]

EXPOSE 1521 8080
HEALTHCHECK --interval=1m --start-period=5m \
   CMD "$ORACLE_BASE/$CHECK_DB_FILE" >/dev/null || exit 1

# Define default command to start Oracle Database. 
CMD exec $ORACLE_BASE/$RUN_FILE
