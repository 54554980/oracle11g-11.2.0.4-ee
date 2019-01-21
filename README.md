Oracle Database on Docker
This project offers sample Dockerfiles for:

    Oracle Database 11g Release 2 (11.2.0.4)  Enterprise Edition and Standard Edition.

To assist in building the images, you can use the buildDockerImage.sh script. See below for instructions and usage.

The buildDockerImage.sh script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call docker build with their prefered set of parameters.
Building Oracle Database Docker Install Images

IMPORTANT: You will have to provide the installation binaries of Oracle Database and put them into the dockerfiles/<version> folder. You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the Oracle Technology Network, make sure you use the linux link: Linux x86-64. The needed file is named linuxx64__database.zip. You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have chosen which edition and version you want to build an image of, go into the dockerfiles folder and run the buildDockerImage.sh script:

[oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h

Usage: buildDockerImage.sh -v [version] [-e | -s | -x] [-i] [-o] [Docker build option]
Builds a Docker Image for Oracle Database.

Parameters:
   -v: version to build
       Choose one of: 11.2.0.4  
   -e: creates image based on 'Enterprise Edition'
   -s: creates image based on 'Standard Edition 2'
   -x: creates image based on 'Express Edition'
   -i: ignores the MD5 checksums
   -o: passes on Docker build option

* select one edition only: -e, -s, or -x
 

To run your Oracle Database Docker image use the docker run command as follows:

docker run --name <container name> \
-p <host port>:1521 -p <host port>:8080 \
-e ORACLE_SID=<your SID> \
-e ORACLE_PDB=<your PDB name> \
-e ORACLE_PWD=<your database passwords> \
-e ORACLE_CHARACTERSET=<your character set> \
-v [<host mount point>:]/opt/oracle/oradata \
oracle/database:11.2.0.4-ee

Parameters:
   --name:        The name of the container (default: auto generated)
   -p:            The port mapping of the host port to the container port. 
                  Two ports are exposed: 1521 (Oracle Listener), 5500 (OEM Express)
   -e ORACLE_SID: The Oracle Database SID that should be used (default: ORCLCDB)
   -e ORACLE_PDB: The Oracle Database PDB name that should be used (default: ORCLPDB1)
   -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated)
   -e ORACLE_CHARACTERSET:
                  The character set to use when creating the database (default: AL32UTF8)
   -v /opt/oracle/oradata
                  The data volume to use for the database.
                  Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
                  If omitted the database will not be persisted over container recreation.
   -v /opt/oracle/scripts/startup | /docker-entrypoint-initdb.d/startup
                  Optional: A volume with custom scripts to be run after database startup.
                  For further details see the "Running scripts after setup and on startup" section below.
   -v /opt/oracle/scripts/setup | /docker-entrypoint-initdb.d/setup
                  Optional: A volume with custom scripts to be run after database setup.
                  For further details see the "Running scripts after setup and on startup" section below.

Once the container has been started and the database created you can connect to it just like to any other database:

sqlplus sys/<your password>@//localhost:1521/<your SID> as sysdba
sqlplus system/<your password>@//localhost:1521/<your SID>
 
  
The password for those accounts can be changed via the docker exec command. Note, the container has to be running:

docker exec <container name> ./setPassword.sh <your password>
 
修改部分：
    dbca -silent -createDatabase -initParams java_jit_enabled=false -responseFile $ORACLE_BASE/dbca.rsp 
    增加了：-initParams java_jit_enabled=false  ，解决创建数据库76% complete!问题。
 
docker-compose.yml:
version: '2'
services:
  database:
    image: oracle/database:11.2.0.4-ee
    container_name: db-name
    hostname: db-name
    environment:
      - TZ=Asia/Shanghai
      - ORACLE_TOTALMEMORY=4096
      - ORACLE_SID=ORCL
      - ORACLE_PWD=*****
      - ORACLE_CHARACTERSET=ZHS16GBK
    volumes:
      - /path/oradata:/u01/app/oracle/oradata 
      - /path/fast_recovery_area:/u01/app/oracle/fast_recovery_area
      - /path/docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d
    ports:
      - 1521:1521
      - 28080:8080
# docker-compose up -d
# docker-compose down/stop/start
