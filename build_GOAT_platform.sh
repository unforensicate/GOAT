#!/bin/bash
#######################################################################################
# GOAT/TARDIS VM/OS Build Script version 0.1.061818 
# Authors: RSA Incident Response - Riley, Trabing
# Applications Installed:
#	- Plaso (via GIFT for 16.04, Source for 18.04)
#	- Elasticsearch (5.6.9)
#	- Kibana (5.6.9)
#	- Logstash (5.6.9)
#	- Git
#	- Java 8 
#	- Pip
#	- Plaso
#	- Plaso Tools
#	- Yarn
#	- Node.js
#	- Postgres
#	- Timesketch
#	- Neo4J
#
#
# Changelog:
#	v0.1.061818
#	- Added RSA IR Mass Triage and ECAT queries a la Stevie B. (Git clone) - JWR
#	- Fixed issue with Postgres and Timesketch users not being created correctly. - JWR
#	- Fixed issue with path to log file when building Plaso - JWR
#	- Fixed issue with script lockup due to Oracle license acceptance - JWR 
#	- Added script output formatting/color for easier reading - JWR
#	- Fixed Timesketch Postgres database creation issue - JWR
#
#	v0.1.061518
#	- Removed required typing of password for PostgreSQL user - JWR
#	- Established working GitHub Repository (https://github.com/elysianblue/GOAT)
#	- Added Ubuntu 18.04 LTS (Bionic) support (Python 2.7. Python 3 not fully supported by Plaso)- JWR
#	- Added Ubuntu Distro Release check for OS Identification - JWR
#	- Installation of python3-software-properties and software-properties-common 
#	  in place of python-software-properties for Ubuntu Server 18.04.  For 16.04
#	  python-software-properties in still installed - JWR
#	- Ensured using Plaso >= 20180524 due to python-dvfvs timestamp issue
#
#	v0.1.061418.1 
#	- Script log output added - JWR
#	- Node.js added for Neo4J Integration - JWR
#	- Service checks added upon completion of script - JWR
#
#	v0.1.061418.0 - New Base Script Version - JWR
#######################################################################################

BUILD="0.1.061818"
PWD=`pwd`
LOG="$PWD/GOAT_build.log"
DISTRO=`grep DISTRIB_RELEASE /etc/lsb-release |cut -d= -f2`
INIT=`date`
SCRIPT_START=`date +%s`
echo -e  "\e[91m-------------------------------------------------------------------------------------------\e[0m"
echo -e  "			     *** NOT FOR PUBLIC RELEASE ***"
echo -e  " "
echo -e  "\e[91mRSA\e[0m Incident Response Global Operations Analysis Toolset - Platform Build Script"
echo -e  "Authors: RSA IR - Wes Riley, Joshua Trabing"
echo -e  "Version: \e[36m$BUILD\e[0m"
echo -e  "Requirements: Ubuntu Desktop or Server 16.04 or 18.04 LTS Base System or VM"
echo -e  "              Internet Access"
echo -e  "Purpose/Function: This is the build and deployment script for the RSA IR GOAT"
echo -e  "		platform.  It will download, build, install, and configure"
echo -e  "		all the required applications and libraries for a working"
echo -e  "		GOAT system instance.  This script is built in a very "
echo -e  "		specific manner, and any modification to this script is not"
echo -e  "		advised without discussion with the author."
echo -e  " "
echo -e  "		\e[91mDO NOT COME CRYING IF YOU CHANGE THIS AND FUCK IT UP.\e[0m"
echo -e " "
echo -e  "Applications: "
echo -e  "	- Elasticsearch"
echo -e  "	- Kibana"
echo -e  "	- Plaso"
echo -e  "	- Timesketch"
echo -e  "	- Postgres"
echo -e  "	- Neo4j"
echo -e  "	- Logstash"
echo -e  "	- RSA Mass Triage and Forensic State Analysis Processing"
echo -e " "
echo -e  "\e[91m-------------------------------------------------------------------------------------------\e[0m"
echo -e  " "
echo -e  "\e[36m[+] Beginning build v$BUILD...\e[0m"
echo -e  "[-] Updating current system via apt..\e[0m"
echo -e  "Begin GOAT Installation Log for $BUILD on Ubuntu $DISTRO at $INIT...\e[0m" >> $LOG
echo -e  "---------------------------------------------------------------------------------" >> $LOG
echo -e  " " >> $LOG
# Update Package Lists
if apt-get -q update -y >> $LOG; then
	echo -e  "\e[36m[+] System successfully updated!\e[0m"
else
	echo -e  "\e[91m[!] System update encountered an error.  Please resolve before attempting build again.\e[0m"
	exit
fi
# Installing general prerequisite packages for Ubuntu 16.04
echo -e  "[-] ($DISTRO) Installing required system packages for $DISTRO...\e[0m" 
if [ $DISTRO = "16.04" ]; then
	if apt-get -q install -y python-software-properties software-properties-common apt-transport-https git python-pip >> $LOG; then
		echo -e  "\e[36m[+] Required system packages for $DISTRO installed successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Error installing required system packages.  Please resolve before attempting build again.\e[0m"
		echo -e  "[**] Packages: python-software-properties software-properties-common apt-transport-https git"
		exit
	fi
# Installing general prerequisite packages for Ubuntu 18.04
echo -e  "[-] ($DISTRO) Installing required system packages for $DISTRO...\e[0m"
elif [[ $DISTRO = "18.04" ]]; then
	if apt-get -q install -y software-properties-common apt-transport-https git python-pip liblzma-dev python-lzma python-lzma-dbg >> $LOG; then
		echo -e  "\e[36m[+] Required system packages for $DISTRO installed successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Error installing required system packages.  Please resolve before attempting build again.\e[0m"
		echo -e  "[**] Packages: python3-software-properties software-properties-common apt-transport-https git python-pip"
		exit
	fi
fi
# Add universe repository for distro
echo -e  "[-] Adding 'universe' APT Repository...\e[0m"
if add-apt-repository universe >> $LOG; then
	echo -e  "\e[36m[+] 'Universe' APT Repository added successfully!\e[0m"
else 
	echo -e  "\e[91m[!] Error adding APT Repository 'universe'.\e[0m"
	exit
fi
# Update Package Lists
echo -e  "[-] Updating system package lists...\e[0m"
if apt-get -q update >> $LOG; then
	echo -e  "\e[36m[+] System package lists updated successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error updating system package lists.\e[0m"
	exit
fi
# Upgrade system to current
echo -e  "[-] Bringing currently installed packages and system up to date...\e[0m"
if apt-get -q -y upgrade >> $LOG; then
	echo -e  "\e[36m[+] System and installed packages up to date!\e[0m"
else
	echo -e  "\e[91m[!] Error updating system or installed packages.\e[0m"
	exit
fi
####################################################################
# Plaso Installation
# - 16.04 is using GIFT repository to install 20180524
# - 18.04 is not supported in GIFT, so installing 20180524 from pip
####################################################################
# Adding GIFT repository for 16.04
if [ $DISTRO = "16.04" ]; then
	echo -e  "[-] ($DISTRO) Adding Glorious Incident Feedback Tools (GIFT) APT Repository...\e[0m"
	if add-apt-repository -y ppa:gift/stable >> $LOG; then
		echo -e  "\e[36m[+] GIFT APT Repository added successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Error adding GIFT APT Repository.\e[0m"
		exit
	fi
# Adding required packages for 18.04 pip build install
elif [[ $DISTRO = "18.04" ]]; then
	echo -e  "[-] ($DISTRO) Addiing required build packages for Plaso source installation...\e[0m"
	if apt-get -q install -y aptitude build-essential autotools-dev automake zlib1g-dev libbz2-dev libfuse-dev libsqlite3-dev libssl-dev python-dev python-setuptools debhelper devscripts fakeroot quilt >> $LOG; then
		echo -e  "\e[36m[+] Plaso required build packages installed successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Error installing required build packages.  Please review $LOG for more information.\e[0m"
		exit
	fi
fi
# Update Package lists
echo -e  "[-] Updating system package lists...\e[0m"
if apt-get -q update >> $LOG; then
        echo -e  "\e[36m[+] System package lists updated successfully!\e[0m"
else
        echo -e  "\e[91m[!] Error updating system package lists.\e[0m"
        exit
fi
# Install Plaso via GIFT repository for Ubuntu 16.04
if [ $DISTRO = "16.04" ]; then
	echo -e  "[-] ($DISTRO) Installing Plaso toolset...(USING LATEST STABLE RELEASE (>= 20180524) UNTIL RSAIR PLASO COMPLETE.  DO NOT MODIFY!!!  YOU WILL BREAK PYTHON AND ALL THE THINGS!!!)"
	if apt-get -q install -y python-plaso plaso-tools >> $LOG; then
		echo -e  "\e[36m[+] Plaso toolset installed successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Error installing Plaso toolset.\e[0m"
		exit
	fi
# Install Plaso from source via Pip for Ubuntu 18.04
elif [ $DISTRO = "18.04" ]; then
	echo -e  "[-] ($DISTRO) Downloading Plaso source...\e[0m"
	if git clone https://github.com/log2timeline/plaso.git >> $LOG; then
		echo -e  "\e[36m[+] Plaso source downloaded successfully.\e[0m"
	else
		echo -e  "\e[91m[!] Plaso download failed!  Command attempted: git clone https://github.com/log2timeline/plaso.git.  See $LOG for more details.\e[0m"
		exit
	fi
	# Installing Plaso Python Requirements
	echo -e  "[-] Installing Plaso Python requirements...\e[0m"
	if cd plaso && sudo -H pip install -r requirements.txt >> $LOG; then
		echo -e  "\e[36m[+] Plaso Python requirements installed successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Plaso Python requirements installation failed.  See $LOG for more details.\e[0m"
		exit
	fi
	# Checking Plaso Python dependency status to make sure we have everything
	echo -e  "[-] Checking Plaso Python dependency status...\e[0m"
	if python utils/check_dependencies.py >> $LOG; then
		echo -e  "\e[36m[+] Dependencies checked.  Results in $LOG for troubleshooting.\e[0m"
	fi
	echo -e  "[-] Installing Plaso to system...\e[0m"
	# Installing Plaso 
	if sudo -H pip install . >> $LOG && cd ..; then
		echo -e  "\e[36m[+] Plaso installed successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Plaso installation failed!  See $LOG for more details.\e[0m"
		exit
	fi
fi 
echo -e  "[-] Installing Oracle Java APT Repository...\e[0m"
if add-apt-repository ppa:webupd8team/java -y >> $LOG; then
	echo -e  "\e[36m[+] Oracle Java APT Repository installed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error installing Oracle Java APT Repository.  Please resolve before attempting build again.\e[0m"
	exit
fi
echo -e  "[-] Updating system package lists...\e[0m"
if apt-get -q update >> $LOG; then
	echo -e  "\e[36m[+] System package lists updated successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error updating system package lists.  Please resolve before attempting build again.\e[0m"
	exit
fi
echo -e  "[-] Agreeing to Oracle License for Java 8...\e[0m"
echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
echo -e  "[-] Installing Oracle Java 1.8.0...\e[0m"
if apt-get -q install -y oracle-java8-installer >> $LOG; then
	echo -e  "\e[36m[+] Oracle Java installation complete!\e[0m"
	if [[ $(cat /usr/lib/jvm/java-*/release |grep JAVA_VERSION) = *1.8.0* ]]; then
		echo -e  "\e[36m[+] Java Version check passed! $(cat /usr/lib/jvm/java-*/release |grep JAVA_VERSION)"
	else
		echo -e  "\e[91m[!] Java Version check failed! $(cat /usr/lib/jvm/java-*/release |grep JAVA_VERSION). Please resolve before attempting build again.\e[0m"
		exit
	fi
else
	echo -e  "\e[91m[!] Oracle Java installation failed!  Please resolve before attempting build again.\e[0m"
	exit
fi
echo -e  "[-] Downloading and installing APT GPG Key for Elasticsearch APT Repository...\e[0m"
if [[ $(wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -) = OK ]]; then
	echo -e  "\e[36m[+] Elasticsearch APT GPG Key downloaded and installed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Elasticsearch APT GPG Key download or install failed.  Please resolve before attempting build again.\e[0m"
	exit
fi
echo -e  "[-] Adding Elasticsearch Version 5.x Repository to APT Sources List"
echo -e  "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
echo -e  "\e[36m[+] Elasticsearch Version 5.x Repository added to APT Sources List!\e[0m"
echo -e  "[-] Updating system package lists...\e[0m"
if apt-get -q update >> $LOG; then
	echo -e  "\e[36m[+] System package lists updated successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error updating system package lists.  Please resolve before attempting build again.\e[0m"
	exit
fi
echo -e  "[-] Installing Elasticsearch 5.6.2...\e[0m"
if apt-get -q install -y elasticsearch >> $LOG; then
	echo -e  "\e[36m[+] Elasticsearch 5.x installed successfully!\e[0m"
	ES_VERSION=`/usr/share/elasticsearch/bin/elasticsearch -V`
	echo -e  "[**] $ES_VERSION"
else 
	echo -e  "\e[91m[!] Error installing Elasticsearch 5.x (kinda important...).  Please resolve before attempting build again.\e[0m"
	exit
fi
#insert elasticsearch configuration steps here
echo -e  "[-] Downloading and installing Timesketch Elasticsearch Groovy scripts...\e[0m"
if wget -qO - https://raw.githubusercontent.com/google/timesketch/master/contrib/add_label.groovy >> /etc/elasticsearch/scripts/add_label.groovy; then
        echo -e  "\e[36m[+] Timesketch Add Label script downloaded and installed successfully!\e[0m"
else
        echo -e  "\e[91m[!] Error downloading or installing Timesketch Add Label script.\e[0m"
        exit
fi
if wget -qO - https://raw.githubusercontent.com/google/timesketch/master/contrib/toggle_label.groovy >> /etc/elasticsearch/scripts/toggle_label.groovy; then
        echo -e  "\e[36m[+] Timesketch Toggle Label script downloaded and installed successfully!\e[0m"
else
        echo -e  "\e[91m[!] Error downloading or installing Timesketch Toggle Label script.\e[0m"
        exit
fi
echo -e  "[-] Installing and Starting Elasticsearch service...\e[0m"
sudo systemctl daemon-reload >> $LOG
sudo systemctl enable elasticsearch >> $LOG
sudo systemctl start elasticsearch >> $LOG
echo -e  "\e[36m[+] Elasticsearch service installed and started!\e[0m"
echo -e  "[-] Installing Kibana 5.x...\e[0m"
if apt-get -q install -y kibana >> $LOG; then 
	echo -e  "\e[36m[+] Kibana 5.x installed successfully!\e[0m"
	KIB_VERSION=`/usr/share/kibana/bin/kibana -V`
	echo -e  "[**] Version: $KIB_VERSION"
else
	echo -e  "\e[91m[!] Error installing Kibana 5.x.  Please resolve before attempting build again.\e[0m"
	exit
fi
echo -e  "[-] Configuring Kibana...\e[0m"
if sed -i 's/#server\.host/server\.host/g' /etc/kibana/kibana.yml; then
	if sed -i 's/localhost/0\.0\.0\.0/g' /etc/kibana/kibana.yml; then
		echo -e  "\e[36m[+] Kibana host setting configured successfully!\e[0m"
	else
		echo -e  "\e[91m[!] Error modifying Kibana config file.\e[0m"
	fi
else
	echo -e  "\e[91m[!] Error modifying Kibana config file.\e[0m"
	exit
fi
echo -e  "[-] Installing and Starting Kibana service...\e[0m"
sudo systemctl enable kibana >> $LOG
sudo systemctl start kibana >> $LOG
echo -e  "\e[36m[+] Kibana service installed and started!\e[0m"
echo -e  "[-] Installing Logstash 5.x...\e[0m"
if apt-get -q install -y logstash >> $LOG; then
	echo -e  "\e[36m[+] Logstash 5.x installed successfully!\e[0m"
	LS_VERSION=`/usr/share/logstash/bin/logstash -V`
	echo -e  "[**] Version: $LS_VERSION"
else
	echo -e  "\e[91m[!] Error installing Logstash 5.x.  Please resolve before attempting build again.\e[0m"
	exit
fi
#insert logstash configuration steps here
echo -e  "[-] Installing and starting Logstash service...\e[0m"
sudo systemctl enable logstash >> $LOG
sudo systemctl start logstash >> $LOG
echo -e  "\e[36m[+] Logstash service installed and started!\e[0m"
#echo -e  "[-] Installing X-Pack Plugins for Elasticsearch...\e[0m"
#echo -e  "[*] Answer yes to the following prompts [*]"
#if /usr/share/elasticsearch/bin/elasticsearch-plugin install x-pack; then
#	echo -e  "    \e[36m[+] X-Pack for Elasticsearch installed successfully!\e[0m"
#else
#	echo -e  "\e[91m[!] Error installing X-Pack Elasticsearch plugin.\e[0m"
#	exit
#fi
#echo -e  "[-] Installing X-Pack Plugins for Kibana...\e[0m"
#if /usr/share/kibana/bin/kibana-plugin install x-pack; then
#	echo -e  "    \e[36m[+] X-Pack for Kibana installed successfully!\e[0m"
#else
#	echo -e  "\e[91m[!] Error installing X-Pack Kibana plugin.\e[0m"
#	exit
#fi
#if /usr/share/logstash/bin/logstash-plugin install x-pack; then
#	echo -e  "    \e[36m[+] X-Pack for Logstash installed successfully!\e[0m"
#else
#	echo -e  "\e[91m[!] Error installing X-Pack Logstash plugin.\e[0m"
#	exit
#fi
#echo -e  "[-] Configuring X-Pack Users...\e[0m"
#echo -e  "    \e[36m[+] Superuser account: elastic:changeme"
echo -e  "[-] Installing PostgreSQL...\e[0m"
if apt-get -q install -y postgresql && apt-get -q install -y python-psycopg2 >> $LOG; then
	echo -e  "\e[36m[+] PostgreSQL installed successfully!\e[0m"
	PG_VERSION=`/usr/bin/psql -V`
	echo -e  "[**] Version: $PG_VERSION"
else
	echo -e  "\e[91m[!] Error installing PostgreSQL.\e[0m"
	exit
fi
echo -e  "[-] Configuring PostgreSQL for Timesketch...\e[0m"
if echo -e  "local    all             timesketch                              md5" >> /etc/postgresql/*/main/pg_hba.conf; then
	echo -e  "\e[36m[+] Timesketch user successfully added to PostgreSQL config!\e[0m"
else
	echo -e  "\e[91m[!] Error adding Timesketch user to PostgreSQL config.\e[0m"
	exit
fi
if systemctl restart postgresql >> $LOG; then
	echo -e  "\e[36m[+] PostgreSQL service successfully restarted!\e[0m"
else
	echo -e  "\e[91m[!] Error restarting PostgreSQL service.\e[0m"
	exit
fi
#echo -e  "[-] Creating Timesketch user in PostgreSQL database...\e[0m"
#echo -e  "[*] Enter password 'timesketch' when propted [*]"
#if sudo -u postgres createuser -d -P -R -S timesketch >> $LOG; then
#	echo -e  "\e[36m[+] Timesketch user successfully added to PostgreSQL database!\e[0m"
#else
#	echo -e  "\e[91m[!] Error adding Timesketch user to PostgreSQL database.\e[0m"
#	exit
#fi
echo -e  "[-] Creating Timesketch user in PostgreSQL database...\e[0m"
if sudo -u postgres psql -c "CREATE USER timesketch WITH PASSWORD 'timesketch';" >> $LOG; then
	echo -e  "\e[36m[+] User 'timesketch' created with password 'timesketch'\e[0m"
	echo -e  "[-] Giving roles to user 'timesketch'...\e[0m"
	if sudo -u postgres psql -c "ALTER USER timesketch CREATEDB;" >> $LOG; then
		echo -e  "\e[36m[+] Role CREATEDB granted to user 'timesketch'\e[0m"
		sudo -u postgres psql -c "\du"
	else
		echo -e  "\e[91m[!] Role assignment to user 'timesketch' failed.  See $LOG for more details.\e[0m"
		exit
	fi
else
	echo -e  "\e[91m[!] Failed to create user 'timesketch'.  See $LOG for more details.\e[0m"
	exit
fi
echo -e "[-] Creating Timesketch PostgreSQL database..."
if sudo -u postgres createdb -O timesketch timesketch >> $LOG; then
	echo -e  "\e[36m[+] Timesketch PostgreSQL database successfully created!\e[0m"
else
	echo -e  "\e[91m[!] Error creating Timesketch PostgreSQL database.\e[0m"
	exit
fi
echo -e  "[-] Installing Timesketch Frontend build requirements...\e[0m"
if curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -; then
	echo -e  "\e[36m[+] Node.js 8.x APT Repository GPG Key downloaded and installed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Node.js 8.x APT Repository GPG Key download and installation failed.\e[0m"
	exit
fi
if echo -e  "deb https://deb.nodesource.com/node_8.x $(lsb_release -s -c) main"  | sudo tee /etc/apt/sources.list.d/nodesource.list; then
	echo -e  "\e[36m[+] Node.js 8.x APT Repository successfully added to Source List!\e[0m"
else
	echo -e  "\e[91m[!] Error adding Node.js 8.x APT Repository to Source List.\e[0m"
	exit
fi
if curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -; then
	echo -e  "\e[36m[+] Yarn APT Repository GPG Key downloaded and installed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error downloading and installing Yarn APT Repository GPG Key.\e[0m"
	exit
fi
if echo -e  "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list; then
	echo -e  "\e[36m[+] Yarn APT Repository successfully added to Source List!\e[0m"
else
	echo -e  "\e[91m[!] Error adding Yarn APT Repository to Source List.\e[0m"
	exit
fi
if apt-get -q update && apt-get -q install -y nodejs yarn >> $LOG; then
	echo -e  "\e[36m[+] Timesketch Frontend build requirements successfully installed!\e[0m"
else
	echo -e  "\e[91m[!] Error installing Timesketch Frontend build requirements.\e[0m"
	exit
fi
#echo -e  "[-] Setting Python Virtual Environment for Timesketch build...\e[0m"
#if sudo -H pip install virtualenv >> $LOG; then
#	echo -e  "    \e[36m[+] Python Virtual Environment package installed...\e[0m"
#else
#	echo -e  "\e[91m[!] Error installing Python Virtual Environment package.\e[0m"
#	exit
#fi
echo -e  "[-] Downloading current stable Timesketch build...\e[0m"
if git clone https://github.com/google/timesketch.git >> $LOG; then
	echo -e  "\e[36m[+] Current stable Timesketch build downloaded successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error downloading Timesketch.  See $LOG for more details.\e[0m"
	exit
fi
#echo -e  "[-] Building Python Virtual Environment for Timesketch...\e[0m"
#if cd timesketch && virtualenv timesketch; then
#	echo -e  "    \e[36m[+] Python Virtual Environment for Timesketch built successfully!\e[0m"
#else
#	echo -e  "\e[91m[!] Error building Python Virtual Environment for Timesketch.\e[0m"
#	exit
#fi
#echo -e  "[-] Activating Python Virtual Environment for Timesketch...\e[0m"
#if source timesketch/bin/activate; then
#	echo -e  "    \e[36m[+] Python Virtual Environment for Timesketch activated successfully!\e[0m"
#else
#	echo -e  "\e[91m[!] Error activating Python Virtual Environment for Timesketch.\e[0m"
#	exit
#fi
echo -e  "[-] Installing Timesketch Python package requirements...\e[0m"
if cd timesketch && sudo -H pip install -r requirements.in >> $LOG; then
	echo -e  "\e[36m[+] Timesketch Python package requirements installed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error installing Timesketch Python package requirements.\e[0m"
	exit
fi
echo -e  "[-] Building Timesketch Frontend...\e[0m"
if yarn install >> $LOG; then
	echo -e  "\e[36m[+] Node.js required packages downloaded and installed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error downloading and installing required Node.js packages.\e[0m"
	exit
fi
if yarn run build >> $LOG; then
	echo -e  "\e[36m[+] Timesketch Frontend build completed successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error building Timesketch Frontend.\e[0m"
	exit
fi
echo -e  "[-] Installing Timesketch to system...\e[0m"
if sudo -H pip install . >> $LOG && cd ..; then
	echo -e  "\e[36m[+] Timesketch successfully installed to system!\e[0m"
else
	echo -e  "\e[91m[!] Error installing Timesketch to system.\e[0m"
	exit
fi
echo -e  "[-] Configuring Timesketch...\e[0m"
if cp /usr/local/share/timesketch/timesketch.conf /etc/. && chmod 660 /etc/timesketch.conf; then
	echo -e  "\e[36m[+] Timesketch config file installed to /etc...\e[0m"
else
	echo -e  "\e[91m[!] Error installing Timesketch config file to /etc.\e[0m"
	exit
fi
if sed -i s'/<USERNAME>/timesketch/g' /etc/timesketch.conf && sed -i 's/<PASSWORD>/timesketch/g' /etc/timesketch.conf; then
        key=`openssl rand -base64 32`
        if sed -i "s|<KEY_GOES_HERE>|${key}|g" /etc/timesketch.conf; then
                if sed -i 's/<N4J_PASSWORD>/neo4j/g' /etc/timesketch.conf; then
			if sed -i 's/UPLOAD_ENABLED = False/UPLOAD_ENABLED = True/g' /etc/timesketch.conf; then
				if sed -i 's/GRAPH_BACKEND_ENABLED = False/GRAPH_BACKEND_ENABLED = True/g' /etc/timesketch.conf; then
                        		echo -e  "\e[36m[+] Timesketch configured successfully!\e[0m"
				else
					echo -e  "\e[91m[!] Error enabling Graph backend.\e[0m"
					exit
				fi
			else
				echo -e  "\e[91m[!] Error enabling file upload.\e[0m"
				exit
			fi
                else
                        echo -e  "\e[91m[!] Error setting Neo4j password.\e[0m"
                fi
        else
                echo -e  "\e[91m[!] Error in setting SECRET_KEY.\e[0m"
                exit
        fi
else
        echo -e  "\e[91m[!] Error configuring Timesketch.\e[0m"
        exit
fi
#tsuser=`grep -E "1000\:1000" /etc/passwd |cut -d":" -f1`
echo -e  "[-] Configuring Timesketch user as first non-system user: $tsuser...\e[0m"
echo -e  "[*] Enter 'timesketch' as password when prompted [*]"
if tsctl add_user --username timesketch --password timesketch; then
	echo -e  "\e[36m[+] Timesketch user timesketch:timesketch added successfully!\e[0m"
else
	echo -e  "\e[91m[!] Error adding Timesketch user.\e[0m"
	exit
fi
echo -e  "[-] Installing Timesketch systemd service...\e[0m"
if echo -e  "W1VuaXRdCkRlc2NyaXB0aW9uID0gVGltZXNrZXRjaCBTZXJ2aWNlIGZvciBzeXN0ZW1kCkFmdGVyID0gbmV0d29yay50YXJnZXQKW1NlcnZpY2VdCkV4ZWNTdGFydCA9IC91c3IvbG9jYWwvYmluL3RzY3RsIHJ1bnNlcnZlciAtaCAwLjAuMC4wCltJbnN0YWxsXQpXYW50ZWRCeSA9IG11bHRpLXVzZXIudGFyZ2V0Cg==" |base64 -d >> /etc/systemd/system/timesketch.service; then
	echo -e  "\e[36m[+] Timesketch systemd service successfully installed!\e[0m"
	if systemctl enable timesketch.service; then
		echo -e  "\e[36m[+] Timesketch systemd service successfully activated!\e[0m"
	else
		echo -e  "\e[91m[!] Error activating Timesketch systemd service.\e[0m"
		exit
	fi
else
	echo -e  "\e[91m[!] Error installing Timesketch systemd service.\e[0m"
	exit
fi
if which node; then
	echo -e  "	\e[36m[+] Node.js command 'node' found!\e[0m"
	if which npm; then
		echo -e  "	\e[36m[+] Node.js Package Manager found!\e[0m"
		echo -e  "	[-] Installing elasticsearch-tools via npm...\e[0m"
		if npm install -g elasticsearch-tools >> $LOG; then
			echo -e  "\e[36m[+] Elasticsearch-tools successfully installed!\e[0m"
		else
			echo -e  "\e[91m[!] Elasticsearch-tools failed to install.  See $LOG for more details.\e[0m"
			exit
		fi
	else
		echo -e  "	\e[91m[!] Node.js Package Manager not found!  Installing...\e[0m"
		if apt-get -q install npm -y >> $LOG; then
			echo -e  "\e[36m[+] Node.js Package Manager installed successfully!\e[0m"
		else
			echo -e  "\e[91m[!] Node.js Package Manager installtion failed.  See $LOG for more details.\e[0m"
			exit
		fi
	fi
else
	echo -e  "	\e[91m[!] Node.js command 'node' not found!  Checking 'nodejs'...\e[0m"
	if which nodejs; then
		echo -e  "\e[36m[+] Node.js command 'nodejs' found!  Symlinking 'node' to 'nodejs'...\e[0m"
		if ln `which nodejs` /usr/bin/node; then
			echo -e  "\e[36m[+] Symlink created!\e[0m"
		else
			echo -e  "\e[91m[!] Symlink failed.  Bailing.\e[0m"
			exit
		fi
	else
		echo -e  "\e[91m[!] Node.js not installed! Installing...\e[0m"
		if apt-get -q install nodejs -y >> $LOG; then
			echo -e  "\e[36m[+] Node.js installed successfully!\e[0m"
		else
			echo -e  "\e[91m[!] Node.js install failed.  Bailing.\e[0m"
			exit
		fi
	fi
	if which npm; then
		echo -e  "\e[36m[+] Node Package Manager found!\e[0m"
		echo -e  "[-] Installing elasticsearch-tools via npm....\e[0m"
		if npm install -g elasticsearch-tools >> $LOG; then
			echo -e  "\e[36m[+] Elasticsearch-tools successfully installed!\e[0m"
		else
			echo -e  "\e[91m[!] Elasticsearch-tools installation failed.  See $LOG for more details.\e[0m"
			exit
		fi
	else
		echo -e  "\e[91m[!] Node.js Package Manager not found!  Installing...\e[0m"
		if apt-get -q install npm -y >> $LOG; then
			echo -e  "\e[36m[+] Node.js Package Manager installed successfully!\e[0m"
			echo -e  "[-] Installing elasticsearch-tools via npm...\e[0m"
			if npm install -g elasticsearch-tools >> $LOG; then
				"\e[36m[+] Elasticsearch-tools installed successfully!\e[0m"
			else
				echo -e  "\e[91m[!] Elasticsearch-tools installation failed. See $LOG for more details.\e[0m"
				exit
			fi
		else
			echo -e  "\e[91m[!] Node.js Package Manager installation failed.  See $LOG for more details.\e[0m"
			exit
		fi
	fi
fi
echo -e  "[-] Downloading and installing Neo4j APT Repository GPG Key...\e[0m"
if wget --no-check-certificate -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -; then
        echo -e  "\e[36m[+] Neo4j APT Repository GPG Key downloaded and installed successfully!\e[0m"
else
        echo -e  "\e[91m[!] Error downloading or installing Neo4j APT Repository GPG Key.\e[0m"
        exit
fi
echo -e  "[-] Adding Neo4j APT Repository to Source List...\e[0m"
if echo -e  'deb http://debian.neo4j.org/repo stable/' | sudo tee /etc/apt/sources.list.d/neo4j.list; then
        echo -e  "\e[36m[+] Neo4j APT Repository successfully added to Source List!\e[0m"
else
        echo -e  "\e[91m[!] Error adding Neo4j APT Repository to Source List.\e[0m"
        exit
fi
echo -e  "[-] Installing Neo4j database...\e[0m"
if apt-get -q update && apt-get -q install -y neo4j >> $LOG; then
        echo -e  "\e[36m[+] Neo4j successfully installed!\e[0m"
        NEO_VERSION=`/usr/bin/neo4j version`
        echo -e  "Version: $NEO_VERSION"
else
        echo -e  "\e[91m[!] Error installing Neo4j. See $LOG for more details.\e[0m"
        exit
fi
########################################################################################
# Under Development
# 	- Download and Installation of ECAT queries and RSA Mass Triage scripts for 
# 	integration.
# 		- Integrate RSA Mass Triage to Forensic State Analysis Packages for 
#		transfer or processing directly to Elasticsearch
#		- Management of Artifact Acquisition WRT System Management, Artifact 
#		Tiers, and New Systems
#		- Workflow: RMT -> FSA Packages (Tier I, Tier II, or Ad Hoc -> Compressed)
#		- Multi-processing: Multiple processes for groups of artifacts. *TEST != ZeroMQ*
#		- Still testing FSA Packages between Compressed Artifacts (Processed off-ECAT)
#		or Compressed JSON (Processed on-ECAT).  May make this optional and up to 
#		discretion of analyst.
#	- Expected Working State in Alpha as is Primary Functionality
###########################################################################################
echo -e  "[-] Downloading and Installing RSA IR Mass Triage and Endpoint queries...\e[0m"
if git clone https://github.com/timetology/ecat.git >> $LOG; then
	echo -e  "\e[36m[+] RSA IR Mass Triage and Endpoint queries downloaded successfully.\e[0m"
else
	echo -e  "\e[91m[!] RSA IR Mass Triage and Endpoint queries download failed.  See $LOG for more details.\e[0m"
fi
clear
SCRIPT_END=`date +%s`
RUNTIME=$((SCRIPT_END - SCRIPT_START))
IPADDRESS=`hostname -i |awk '{print $1}'`
echo -e  "--------------------------------------------------------------------------------------------"
echo -e  "Installation Completed - Runtime: $RUNTIME seconds"
echo -e " "
echo -e  "The RSA IR GOAT Platform has now been installed and configured on this system.  Use the "
echo -e  "following to access and begin analysis: "
echo -e  " "
echo -e  "** Kibana **"
echo -e  "Version: $KIB_VERSION"
echo -e  "URL: http://$IPADDRESS:5601"
#echo -e  "User: elastic"
#echo -e  "Pass: changeme"
echo -e  " "
echo -e  "** Timesketch **"
echo -e  "URL: http://$IPADDRESS:5000"
echo -e  "User: timesketch"
echo -e  "Pass: timesketch"
echo -e  " "
echo -e  "-- Additional Ports and Services --"
echo -e  "** Elasticsearch **"
echo -e  "Version: $ES_VERSION"
echo -e  "HTTP REST URL: http://localhost:9200"
#echo -e  "User: elastic"
#echo -e  "Pass: changeme"
echo -e  " "
echo -e  "** Neo4j Browser **  (Not currently active, WIP)"
echo -e  "Version: $NEO_VERSION"
echo -e  "URL: http://$IPADDRESS:7474"
echo -e  "User: neo4j"
echo -e  "Pass: neo4j"
echo -e  " "
echo -e  " Service Checks in Progress..."
declare -a services=('elasticsearch' 'postgresql' 'celery' 'neo4j' 'redis' 'kibana' 'timesketch')
# Ensure all Services are started
for item in "${services[@]}"
do
    echo -e  "  Bringing up $item"
    sudo systemctl restart $item
    sleep 1
done

echo -e  ""

for item in "${services[@]}"
do
    echo -e  "  $item service is: $(systemctl is-active $item)"
done
echo -e  " "
echo -e  "				    Good luck, and good hunting."
