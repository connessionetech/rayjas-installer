#!/bin/bash
#!/usr/bin/bash 

## This file is part of `Grahil` 
## Copyright 2018 Connessione Technologies
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


# shell argument variables
args_module_request=
args_update_request=
args_update_mode=
args_install_request=
args_requirements_file=
args_module_name=v
args_profile_request=
args_profile_name=


CURRENT_INSTALLATION_PROFILE=

CONFIGURATION_FILE=conf.ini

LOGGING=true
LOG_FILE_NAME=grahil_installer.log
LOG_FILE=$PWD/$LOG_FILE_NAME

OS_TYPE=
OS_DEB="DEBIAN"
OS_RHL="REDHAT"

PROGRAM_INSTALL_AS_SERVICE=true 
PROGRAM_SERVICE_LOCATION=/lib/systemd/system
PROGRAM_SERVICE_NAME=grahil.service
DEFAULT_PROGRAM_PATH=/usr/local/grahil
PYTHON_MAIN_FILE=run.py
PROGRAM_INSTALL_REPORT_NAME=report.json
PROGRAM_CONFIGURATION_MERGER=/python/smartmerge.py

IS_64_BIT=0
OS_NAME=
OS_VERSION=
PLATFORM_ARCH=
OS_MAJ_VERSION=


PROGRAM_DEFAULT_DOWNLOAD_FOLDER_NAME="tmp"
PROGRAM_DEFAULT_DOWNLOAD_FOLDER=
INSTALLER_OPERATIONS_CLEANUP=1

PROGRAM_DOWNLOAD_URL=
PROGRAM_VERSION=

virtual_environment_exists=0
virtual_environment_valid=0

PYTHON_VIRTUAL_ENV_DEFAULT_LOCATION=
PYTHON_VIRTUAL_ENV_INTERPRETER=
CUSTOM__VIRTUAL_ENV_LOCATION=false
PROGRAM_ERROR_LOG_FILE_NAME="log/error.log"


PROGRAM_UPDATE_CRON_HOUR=11
PYTHON_VERSION=
INSTALLATION_PYTHON_VERSION=

PYTHON_REQUIREMENTS_FILENAME=base.txt
PYTHON_RPI_REQUIREMENTS_FILENAME=rpi.txt
SPECIFIED_REQUIREMENTS_FILE=
RASPBERRY_PI=

has_min_python_version=0
unzip_check_success=0
jq_check_success=0
mail_check_success=0
git_check_success=0
wget_check_success=0
bc_check_success=0
python_install_success=0
virtual_environment_exists=0
virtual_environment_valid=0
latest_download_success=0
service_install_success=0


PROGRAM_SUPPORTED_INTERPRETERS=
PROGRAM_VERSION=
PROGRAM_HASH=


#############################################
# Change directory to the script's directory
# GLOBALS:
#	BASH_SOURCE
# RETURN:
#	
#############################################
switch_dir()
{
	local SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
	cd $SCRIPT_DIR
}



#############################################
# Check if super user permissiosn have been 
# granted or not.
#
# GLOBALS:
#	
# RETURN:
#	true if permissiosn have been granted,
#	false otherwise.
#	
#############################################
validatePermissions()
{
	#if [[ $EUID -ne 0 ]]; then
	#	echo "This script does not seem to have / has lost root permissions. Please re-run the script with 'sudo'"
	#	exit 1
	#fi
	if sudo -n true 2>/dev/null; then 
    	true
	else
		false
	fi
}


#############################################
# Force request super user permissions
#
# GLOBALS:
#	
# RETURN:
#	
#############################################
request_permission()
{
	sudo -v
}

######################################################################################
################################## LOGGER ############################################

#############################################
# Write content to external log file.
#
# GLOBALS:
#		LOGGING
# ARGUMENTS:
#		String to print
# RETURN:
#	
#############################################
write_log()
{
	if [ $# -eq 0 ]; then
		return
	else
		if $LOGGING; then			
			sudo sh -c "logger -s $1 2>> $LOG_FILE"
		fi
	fi
}



#############################################
# Write content to external log file and also 
# print to console.
#
# GLOBALS:
#		LOGGING, LOG_FILE
# ARGUMENTS:
#		String to print
# RETURN:
#	
#############################################
lecho()
{
	if [ $# -eq 0 ]; then
		return
	else
		echo $1

		if $LOGGING; then
			sudo sh -c "logger -s $1 2>> $LOG_FILE"
		fi
	fi
}



#############################################
# Write error to external log file and also 
# print to console.
#
# GLOBALS:
#		LOGGING, LOG_FILE
# ARGUMENTS:
#		Error string to print
# RETURN:
#	
#############################################
lecho_err()
{
	if [ $# -eq 0 ]; then
		return
	else
		# Red in Yellow
		echo -e "\e[41m $1\e[m"

		if $LOGGING; then
			sudo sh -c "logger -s $1 2>> $LOG_FILE"
		fi
	fi
}




#############################################
# Write notice message to external log file and also 
# print to console.
#
# GLOBALS:
#		LOGGING, LOG_FILE
# ARGUMENTS:
#		Message string to print
# RETURN:
#	
#############################################
lecho_notice()
{
	if [ $# -eq 0 ]; then
		return
	else
		
		echo -e "\e[45m $1\e[m"

		if $LOGGING; then
			sudo sh -c "logger -s $1 2>> $LOG_FILE"
		fi
	fi
}



#############################################
# Clear external log file
#
# GLOBALS:
#		LOG_FILE
# ARGUMENTS:
#		String to print
# RETURN:
#	
#############################################
clear_log()
{
	> $LOG_FILE
}



#############################################
# Delete external log file
#
# GLOBALS:
#		LOG_FILE
# ARGUMENTS:
#		String to print
# RETURN:
#	
#############################################
delete_log()
{
	rm $LOG_FILE
}


######################################################################################
############################ MISC ----- METHODS ######################################


#############################################
# Clear console
#
# GLOBALS:
#		
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
cls()
{
	printf "\033c"
}



#############################################
# Create a interactive pause at console by 
# asking for an input from user
#
# GLOBALS:
#		
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
empty_pause()
{
	printf "\n"
	read -r -p 'Press any [ Enter ] key to continue...' key
}


#############################################
# Print newline at console
#
# GLOBALS:
#		
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
empty_line()
{
	printf "\n"
}


######################################################################################
############################ MISC TOOL INSTALLS ######################################


#############################################
# Check for available supported python versions 
# on local system, going by the list of possible 
# versions # provided by PROGRAM_SUPPORTED_INTERPRETERS. 
# On success PYTHON_VERSION is set to the best match 
# found.#
#
# GLOBALS:
#		has_min_python_version, PROGRAM_SUPPORTED_INTERPRETERS,
#		PYTHON_VERSION, PYTHON_LOCATION
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_python()
{
	write_log "Checking python requirements"
	has_min_python_version=0

	echo "Checking for compatible python installations on system"	
	for ver in "${PROGRAM_SUPPORTED_INTERPRETERS[@]}"
	do
		echo "Checking for python$ver on local system"
		local PYTHON_EXISTS=$(which python$ver)
		if [[ $PYTHON_EXISTS != *"no python"* ]]; then
			if [[ $PYTHON_EXISTS == *"python$ver"* ]]; then
				echo "python$ver found @ $PYTHON_EXISTS"
				has_min_python_version=1
				PYTHON_LOCATION=$PYTHON_EXISTS
				PYTHON_VERSION=$ver # only number
				break
			fi
		fi
	done
}



# Public


#############################################
# Check if unzip module is available on the 
# linux system. If true then unzip_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		unzip_check_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_unzip()
{
	write_log "Checking for unzip utility"			
	unzip_check_success=0

	if isinstalled unzip; then
	unzip_check_success=1
	write_log "unzip utility was found"		
	else
	unzip_check_success=0
	lecho "unzip utility not found."				
	fi
}



#############################################
# Check if jq module is available on the 
# linux system. If true then jq_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		jq_check_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_jq()
{
	write_log "Checking for jq utility"			
	jq_check_success=0

	if isinstalled jq; then
	jq_check_success=1
	write_log "jq utility was found"		
	else
	jq_check_success=0
	lecho "jq utility not found."				
	fi
}



#############################################
# Check if mail module is available on the 
# linux system. If true then mail_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		mail_check_success
# ARGUMENTS:
#		
# RETURN:
#	
############################################
check_mail()
{
	write_log "Checking for mail utility"			
	mail_check_success=0

	if isDebian; then
		if isinstalled mailutils; then
			mail_check_success=1
			write_log "mail utility was found"
		else
			mail_check_success=0
			lecho "mail utility not found."
		fi
	else
		if isinstalled mailx; then
			mail_check_success=1
			write_log "mail utility was found"	
		else
			mail_check_success=0
			lecho "mail utility not found."
		fi
	fi
}



#############################################
# Check if git module is available on the 
# linux system. If true then git_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		git_check_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_git()
{
	write_log "Checking for git software"	
	git_check_success=0

	if isinstalled git; then
	git_check_success=1
	write_log "git utility was found"
	else
	git_check_success=0
	lecho "git utility not found."
	fi
}




#############################################
# Check if curl module is available on the 
# linux system. If true then curl_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		curl_check_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_curl()
{
	write_log "Checking for curl utility"	
	curl_check_success=0

	if isinstalled curl; then
	curl_check_success=1
	write_log "curl utility was found"
	else
	curl_check_success=0
	lecho "curl utility not found."
	fi
}





#############################################
# Check if wget module is available on the 
# linux system. If true then wget_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		wget_check_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_wget()
{
	write_log "Checking for wget utility"	
	wget_check_success=0

	if isinstalled wget; then
	wget_check_success=1
	write_log "wget utility was found"
	else
	wget_check_success=0
	lecho "wget utility not found."
	fi
}



#############################################
# Check if bc module is available on the 
# linux system. If true then wget_check_success 
# is set to 1, otherwise 0.
#
# GLOBALS:
#		bc_check_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
check_bc()
{
	write_log "Checking for bc utility"	
	bc_check_success=0

	if isinstalled bc; then
	bc_check_success=1
	write_log "bc utility was found"
	else
	bc_check_success=0
	lecho "bc utility not found."
	fi
}



#############################################
# Installs additional dependencies and libraries 
# needed by python core installation.
#
# GLOBALS:
#		
# ARGUMENTS:
#		$1: Python version number. 
# 		For DEB it is major.minor and
# 		for major.minor RHLE.
# RETURN:
#	
#############################################
ensure_python_additionals()
{
	local ver=$1

	write_log "Ensuring additional softwares for python $1"
	
	if isDebian; then		
		install_python_additionals_deb $ver
	else
		 # remove dot from version number for rhle
		local vernum=$(echo $ver | sed -e 's/\.//g')
		install_python_additionals_rhl $vernum
	fi
}




#############################################
# Installs additional dependencies and libraries 
# needed by python core installation on Debian.
#
# GLOBALS:
#		
# ARGUMENTS:
#		$1: Python version number.
# RETURN:
#	
#############################################
install_python_additionals_deb()
{
	local ver=$1
	sudo apt install -y python3-pip python$ver-dev python$ver-venv python3-venv
}




#############################################
# Installs additional dependencies and libraries 
# needed by python core installation on RHLE/Centos.
#
# GLOBALS:
#		
# ARGUMENTS:
#		$1: Python version number.
# RETURN:
#	
#############################################
install_python_additionals_rhl()
{
	local ver=$1
	sudo yum install -y python$ver-pip python$ver-devel
}




#############################################
# Installs python core on Debain and RHLE. If
# installation is successful python_install_success
# is set to 1, otherwise 0
# GLOBALS:
#		python_install_success
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
install_python()
{	
	write_log "Could not locate python. Attempting to install a recommended version"
	python_install_success=0

	if isDebian; then
	install_python_deb	
	else
	install_python_rhl
	fi

	# verify
	check_python

	if [ $has_min_python_version -eq 1 ]; then
		lecho "Python $PYTHON_VERSION successfully installed at $PYTHON_LOCATION"
		python_install_success=1
	else
		lecho "Could not install required version of python"
	fi
}


# Private


#############################################
# Installs python 3.7 core from PPA on Debain.
# GLOBALS:

# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_python_deb_3_7_ppa()
{
	sudo apt install -y software-properties-common
	sudo add-apt-repository -y ppa:deadsnakes/ppa
	prerequisites_update_deb
	sudo apt install -y python3.7 python3-pip python3.7-dev python3.7-venv python3-venv
}



#############################################
# Installs python 3.7 core from source on Debain.
# GLOBALS:

# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_python_deb_3_7_src()
{
	lecho "Installing python from source"

	prerequisites_update_deb

	sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget libsqlite3-dev python-openssl bzip2 -y
	cd /tmp
	wget https://www.python.org/ftp/python/3.7.2/Python-3.7.2.tar.xz
	tar -xf Python-3.7.2.tar.xz
	cd Python-3.7.2
	./configure --enable-loadable-sqlite-extensions -y
	make
	make altinstall	
}



#############################################
# Checks available python versions on apt against
# the list of supported versions provided by
# PROGRAM_SUPPORTED_INTERPRETERS. Installs the one
# that is supported as well as available on apt. 
#
# GLOBALS:
#		PROGRAM_SUPPORTED_INTERPRETERS, PYTHON_VERSION
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_python_deb()
{
	local supported_python_package_check_success=0

	for ver in "${PROGRAM_SUPPORTED_INTERPRETERS[@]}"
	do
		echo "Checking for python$ver on apt"
		local PYTHON_PACKAGE_EXISTS=$(apt-cache search --names-only "^python$ver-.*")
		if [[ $PYTHON_PACKAGE_EXISTS == *"python$ver"* ]]; then
			# package found ...use this version			
			echo "python$ver found on apt"
			PYTHON_VERSION=$ver
			supported_python_package_check_success=1
			break
		fi
	done

	if [ $supported_python_package_check_success -eq 1 ]; then
		lecho "Installing from apt"	
		sudo apt-get install -y python$PYTHON_VERSION
		install_python_additionals_deb $PYTHON_VERSION
	else
		lecho "No supported python package in yum repo. Installing default"
		lecho "Installing python $PYTHON_VERSION for Debian";

		if [[ "$OS_MAJ_VERSION" -eq 16 ]]; then
			lecho "Installing python $PYTHON_VERSION for Ubuntu 16";
			install_python_deb_3_7_ppa
		elif [[ "$OS_MAJ_VERSION" -eq 18 ]]; then
			lecho "Installing python $PYTHON_VERSION for Ubuntu 18";
			install_python_deb_3_7_ppa
		elif [[ "$OS_MAJ_VERSION" -eq 20 ]]; then
			lecho "Installing python $PYTHON_VERSION for Ubuntu 20";
			install_python_deb_3_7_ppa
		else
			lecho "Unsupported debian version. Attempting to install from source"
			install_python_deb_3_7_src
		fi
	fi	

}




#############################################
# Installs python 3.7 from source on RHLE/CentOS.
# GLOBALS:

# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_python_rhl_3_7_src()
{
	lecho "Installing python from source"

	sudo yum install -y python3-devel.x86_64
	sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel

	cd /tmp
	sudo wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz
	sudo tar xzf Python-3.7.0.tgz
	cd Python-3.7.0
	sudo ./configure --enable-optimizations
	sudo make altinstall
	sudo rm /tmp/Python-3.7.0.tgz
}



# Private

#############################################
# Checks available python versions on yum against
# the list of supported versions provided by
# PROGRAM_SUPPORTED_INTERPRETERS. Installs the one
# that is supported as well as available on yum. 
#
# GLOBALS:
#		PROGRAM_SUPPORTED_INTERPRETERS, PYTHON_VERSION
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_python_rhl()
{
	local vernum=0
	local supported_python_package_check_success=0	

	for ver in "${PROGRAM_SUPPORTED_INTERPRETERS[@]}"
	do
		echo "Checking for python$ver on yum"
		vernum=$(echo $ver | sed -e 's/\.//g')
		local PYTHON_PACKAGE_EXISTS=$(sudo yum list available | grep "python$vernum")
		if [[ $PYTHON_PACKAGE_EXISTS == *"python$vernum"* ]]; then
			# package found ...use this version			
			echo "python$ver found on yum"
			PYTHON_VERSION=$ver
			supported_python_package_check_success=1
			break
		fi
	done


	if [ $supported_python_package_check_success -eq 1 ]; then
		lecho "Installing from yum"		
		sudo yum install -y python$vernum
		install_python_additionals_rhl $vernum
	else
		lecho "No supported python package in yum repo. Installing default"
		install_python_rhl_3_7_src
	fi	
}


# Public


#############################################
# Installs unzip on the linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_unzip()
{
	write_log "Installing unzip"

	if isDebian; then
	install_unzip_deb	
	else
	install_unzip_rhl
	fi		
}



#############################################
# Installs jq on the linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_jq()
{
	write_log "Installing jq"

	if isDebian; then
	install_jq_deb	
	else
	install_jq_rhl
	fi		
}



#############################################
# Installs mail utilities on the linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_mail()
{
	write_log "Installing mail"

	if isDebian; then
	install_mail_deb	
	else
	install_mail_rhl
	fi
}


# Private

#############################################
# Installs mail utilities on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_mail_deb()
{
	write_log "Installing mail on debian"

	sudo apt-get install -y mailutils

	install_mail="$(which mailutils)";
	lecho "mailutils installed at $install_mail"
}



#############################################
# Installs mail utilities on RHLE/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_mail_rhl()
{
	write_log "Installing mail on rhle"

	sudo yum -y install mailx

	install_mail="$(which mailx)";
	lecho "mailx installed at $install_mail"
}



#############################################
# Installs jq on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_jq_deb()
{
	write_log "Installing jq on debian"

	sudo apt-get install -y jq

	install_jq="$(which jq)";
	lecho "jq installed at $install_jq"
}



#############################################
# Installs jq on RHLE/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_jq_rhl()
{
	write_log "Installing jq on rhle"

	sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	sudo yum install jq -y

	install_jq="$(which jq)";
	lecho "jq installed at $install_jq"
}




#############################################
# Installs unzip on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_unzip_deb()
{
	write_log "Installing unzip on debian"

	sudo apt-get install -y unzip

	install_unzip="$(which unzip)";
	lecho "Unzip installed at $install_unzip"
}



#############################################
# Installs unzip on RHLe/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_unzip_rhl()
{
	write_log "Installing unzip on rhle"

	# yup update
	sudo yum -y install unzip

	install_unzip="$(which unzip)";
	lecho "Unzip installed at $install_unzip"
}



#############################################
# Installs git utility on linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_git()
{
	write_log "Installing git"

	if isDebian; then
	install_git_deb	
	else
	install_git_rhl
	fi		
}




#############################################
# Installs curl utility on linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_curl()
{
	write_log "Installing curl"

	if isDebian; then
	install_curl_deb	
	else
	install_curl_rhl
	fi		
}




#############################################
# Installs wget utility on linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_wget()
{
	write_log "Installing wget"

	if isDebian; then
	install_wget_deb	
	else
	install_wget_rhl
	fi		
}



#############################################
# Installs bc utility on linux system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_bc()
{
	write_log "Installing bc"

	if isDebian; then
	install_bc_deb	
	else
	install_bc_rhl
	fi		
}


#############################################
# Installs git on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_git_deb()
{
	write_log "Installing git on debian"

	sudo apt-get install -y git

	local install_loc="$(which git)";
	lecho "git installed at $install_loc"
}



#############################################
# Installs git on RHLE/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_git_rhl()
{
	write_log "Installing git on rhle"

	sudo yum -y install git

	local install_loc="$(which git)";
	lecho "git installed at $install_loc"
}



#############################################
# Installs curl on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_curl_deb()
{
	write_log "Installing curl on debian"

	sudo apt-get install -y curl

	local install_loc="$(which curl)";
	lecho "curl installed at $install_loc"
}




#############################################
# Installs curl on RHLE/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_curl_rhl()
{
	write_log "Installing curl on rhle"

	# yup update
	sudo yum -y install curl

	local install_loc="$(which curl)";
	lecho "curl installed at $install_loc"
}





#############################################
# Installs wget on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_wget_deb()
{
	write_log "Installing wget on debian"

	sudo apt-get install -y wget

	local install_loc="$(which wget)";
	lecho "wget installed at $install_loc"
}



#############################################
# Installs wget on RHLE/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_wget_rhl()
{
	write_log "Installing wget on rhle"

	# yup update
	sudo yum -y install wget

	local install_loc="$(which wget)";
	lecho "wget installed at $install_loc"
}




#############################################
# Installs bc on Debian
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_bc_deb()
{
	write_log "Installing bc on debian"

	sudo apt-get install -y bc

	local install_loc="$(which bc)";
	lecho "bc installed at $install_loc"
}



#############################################
# Installs git on RHLE/CentOS
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_bc_rhl()
{
	write_log "Installing bc on rhle"

	# yup update
	sudo yum -y install bc

	local install_loc="$(which bc)";
	lecho "bc installed at $install_loc"
}

# Public

######################################################################################



#############################################
# Check if grahil is installed on system
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#		True if it is installed, false otherwise
#############################################
program_exists()
{	
	if [ -d "$DEFAULT_PROGRAM_PATH" ]; then
		
		local main_file="$DEFAULT_PROGRAM_PATH/$PYTHON_MAIN_FILE"
		local rules_directory="$DEFAULT_PROGRAM_PATH/rules"

		if [ -f "$main_file" ]; then
			if [ -d "$rules_directory" ]; then
				true
			fi
		else
			false
		fi
	else
	  false
	fi
}


# Creates virtual environment for grahil
#############################################
# Check and create virtual environment for grahil,
# using the python version determined.If environment
# already exists, determine its usability. Then
# either reuse the same environment or create new.
# 
# GLOBALS:
#		virtual_environment_exists, VENV_FOLDER
# ARGUMENTS:
#
# RETURN:
#		
#############################################
check_create_virtual_environment()
{
	virtual_environment_exists=0


	VENV_FOLDER="$PYTHON_VIRTUAL_ENV_LOCATION/$PROGRAM_FOLDER_NAME"


	if [ ! -d "$PYTHON_VIRTUAL_ENV_LOCATION" ]; then	
		mkdir -p "$PYTHON_VIRTUAL_ENV_LOCATION"
		sudo chown -R $USER: $PYTHON_VIRTUAL_ENV_LOCATION
	fi	

	python=$(which python$PYTHON_VERSION)
	pipver=$(which pip3)

	$python -m pip install --upgrade pip
	$pipver install --upgrade setuptools wheel	
	

	if [ ! -d "$VENV_FOLDER" ]; then

		echo "Creating virtual environment @ $VENV_FOLDER"
		$python -m venv $VENV_FOLDER
		sudo chown -R $USER: $VENV_FOLDER

		if [ -f "$VENV_FOLDER/bin/activate" ]; then
			lecho "Virtual environment created successfully"
			virtual_environment_exists=1
		else
			lecho "Fatal error! Virtual environment could not be created." && exit 1
		fi

	else

		echo "Virtual environment folder already exists.. let me check it.." && sleep 1
		if [ ! -f "$VENV_FOLDER/bin/activate" ] || [ ! -f "$VENV_FOLDER/bin/pip" ] || [ ! -f "$VENV_FOLDER/bin/python3" ]; then
			lecho "Virtual environment seems broken. Trying to re-create"
			rm -rf "$VENV_FOLDER" && sleep 1
			check_create_virtual_environment # Create virtual environment again
		else
			source $VENV_FOLDER/bin/activate
			local venv_python=$(python --version)
			deactivate
			
			if [[ "$venv_python" == *"python$PYTHON_VERSION"* ]]; then
				echo "Virtual environment has same version of python."
			else
				rm -rf "$VENV_FOLDER" && sleep 1
				check_create_virtual_environment # Create virtual environment again
			fi

			echo "Virtual environment is folder is ok to use." && sleep 1
			virtual_environment_exists=1
		fi		

	fi
}


#############################################
# Activate the virtual environment for grahil
# 
# GLOBALS:
#		virtual_environment_valid, VENV_FOLDER
# ARGUMENTS:
#
# RETURN:
#		
#############################################
activate_virtual_environment()
{
	lecho "Activating virtual environment"

	virtual_environment_valid=0

	VENV_FOLDER="$PYTHON_VIRTUAL_ENV_LOCATION/$PROGRAM_FOLDER_NAME"

	if [ -d "$VENV_FOLDER" ] && [ -f "$VENV_FOLDER/bin/activate" ]; then		
		source "$VENV_FOLDER/bin/activate"
		
		local pipver=$(which pip3)		
		$pipver install --upgrade setuptools wheel

		local path=$(pip -V)
		if [[ $path == *"$VENV_FOLDER"* ]]; then
			virtual_environment_valid=1	
			lecho "Virtual environment active"	
		else
			lecho "Incorrect virtual environment path"	
		fi		
	else
		virtual_environment_valid=0
		lecho "Oops something is wrong! Virtual environment is invalid"
	fi	
}



#############################################
# Install dependencies in virtual environment
# from the specified requirements file
# 
# GLOBALS:
#		RASPBERRY_PI, REQUIREMENTS_FILE, DEFAULT_PROGRAM_PATH,
#		PYTHON_RPI_REQUIREMENTS_FILENAME, PYTHON_REQUIREMENTS_FILENAME,
#		SPECIFIED_REQUIREMENTS_FILE
# ARGUMENTS:
#
# RETURN:
#		
#############################################
install_python_program_dependencies()
{	
	lecho "Installing dependencies"

	if $RASPBERRY_PI; then
		REQUIREMENTS_FILE="$DEFAULT_PROGRAM_PATH/requirements/$PYTHON_RPI_REQUIREMENTS_FILENAME"
	else
		REQUIREMENTS_FILE="$DEFAULT_PROGRAM_PATH/requirements/$PYTHON_REQUIREMENTS_FILENAME"
	fi	

	if [ ! -z "$SPECIFIED_REQUIREMENTS_FILE" ]; then 
		REQUIREMENTS_FILE="$DEFAULT_PROGRAM_PATH/requirements/$SPECIFIED_REQUIREMENTS_FILE"
	fi
	
	pip3 install -r "$REQUIREMENTS_FILE"
}




#############################################
# Deactivates previously activated virtual 
# environment.
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
deactivate_virtual_environment()
{
	deactivate
}




#############################################
# Downloads and installs grahil distribution 
# from a url. If files are copied properly to 
# location, the value of latest_download_success
# is set to 1.
# 
# GLOBALS:
#		PROGRAM_ARCHIVE_NAME, latest_download_success,
#		PROGRAM_MANIFEST_LOCATION, PROGRAM_DOWNLOAD_URL,
# 		DEFAULT_PROGRAM_PATH, PYTHON_MAIN_FILE
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
install_from_url()
{
	clear
		
	latest_download_success=0
	
	local ARCHIVE_FILE_NAME=$PROGRAM_ARCHIVE_NAME
	local PROGRAM_DOWNLOAD_URL=$(curl -s "$PROGRAM_MANIFEST_LOCATION" | grep -Pom 1 '"url": "\K[^"]*')
	local TMP_DIR=$(mktemp -d -t ci-XXXXXXXXXX)

	lecho "Downloading program url $PROGRAM_DOWNLOAD_URL"
	wget -O "/tmp/$ARCHIVE_FILE_NAME" "$PROGRAM_DOWNLOAD_URL"
	

	if [ -f "/tmp/$ARCHIVE_FILE_NAME" ]; then
		lecho "download success"
		lecho "Extracting files"
		unzip "/tmp/$ARCHIVE_FILE_NAME" -d "$TMP_DIR"		
		if [ -f "$TMP_DIR/$PYTHON_MAIN_FILE" ]; then
			# Extraction successful - copy to main location
			lecho "Moving files to program location $DEFAULT_PROGRAM_PATH"
			sudo cp -R "$TMP_DIR"/. "$DEFAULT_PROGRAM_PATH/"	
			sudo chown -R $USER: "$DEFAULT_PROGRAM_PATH"
			sudo chmod a+rwx "$DEFAULT_PROGRAM_PATH"
			if [ -f "$DEFAULT_PROGRAM_PATH/$PYTHON_MAIN_FILE" ]; then	
				# Copying successful 
				lecho "files copied to program path"

				# Unpack runtime so files
				unpack_runtime_libraries
			fi	
		fi
	fi


	if program_exists; then
		latest_download_success=1
	else
		latest_download_success=0
	fi

}





#############################################
# Unpacks runtime libraries meant for current 
# platform from the archives and deployes them
# to appropriate location in the program installation.
#
# NOTE: Requires build manifest, system detection
# as well as python detection.
# 
# GLOBALS:
#		DEFAULT_PROGRAM_PATH, PLATFORM_ARCH
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
unpack_runtime_libraries()
{
	local current_python="${PYTHON_VERSION//./}"
	local tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
	local runtime_base_dir="$DEFAULT_PROGRAM_PATH/runtime/$PLATFORM_ARCH"
	local deploy_base_dir=$DEFAULT_PROGRAM_PATH

	for i in $(find $runtime_base_dir -type f -print)
	do
		if [[ $i == *.zip ]]; then

			local filename=$(basename -- "$i")
			local extension="${filename##*.}"
			local filename="${filename%.*}"
			local dest=$tmp_dir/$filename			
			local deploy_file=$(echo $i | sed "s#.zip#.so#g")
			local deploy_path=$(echo $deploy_file | sed "s#$runtime_base_dir#$deploy_base_dir#g")

			sudo unzip $i -d $dest/

			for j in $(find $dest -type f -print)
			do				
				local soname=$(basename -- "$j")
				if [[ $soname == *$current_python.so ]]; then					
					# Move tmp file to main location
					lecho "Moving runtime file $j to $deploy_path"
					sudo mv $j $deploy_path
				fi
			done
		fi

	done
}




#############################################
# Downloads and installs grahil distribution 
# from github.
# 
# GLOBALS:
#		PROGRAM_GIT_LOCATION, PROGRAM_INSTALL_LOCATION,
#		PROGRAM_GIT_BRANCH, latest_download_success
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
install_from_git()
{
	cd "$PROGRAM_INSTALL_LOCATION"
	

	if [ -z "$PROGRAM_GIT_BRANCH" ]; then
		git clone "$PROGRAM_GIT_LOCATION" grahil
	else
		git clone -b "$PROGRAM_GIT_BRANCH"  "$PROGRAM_GIT_LOCATION" grahil
	fi

	if program_exists; then
		latest_download_success=1
	else
		latest_download_success=0
	fi
}




#############################################
# Reads installation manifest from the internet
# url defined and parses.
# 
# GLOBALS:
#		PROGRAM_GIT_LOCATION, PROGRAM_INSTALL_LOCATION,
#		PROGRAM_GIT_BRANCH, latest_download_success
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
get_install_info()
{
	local UNIQ=$(date +%s)
	local manifestdata=$(curl -H 'Cache-Control: no-cache' -sk "$PROGRAM_MANIFEST_LOCATION?$UNIQ")

	if [ -z "$manifestdata" ]; then 
		echo "Failed to get manifest data" && exit
	fi


	if [ "$PLATFORM_ARCH" == "x86_64" ]; then
		eval "$(jq -M -r '@sh "package_enabled=\(.payload.platform.x86_64.enabled) package_url=\(.payload.platform.x86_64.url) package_hash=\(.payload.platform.x86_64.md5) package_version=\(.payload.version) supported_interpreters=\(.payload.platform.x86_64.dependencies.interpreters)"' <<< "$manifestdata")"	
	elif [ "$PLATFORM_ARCH" == "arm64" ]; then
		eval "$(jq -M -r '@sh "package_enabled=\(.payload.platform.arm64.enabled) package_url=\(.payload.platform.arm64.url) package_hash=\(.payload.platform.arm64.md5) package_version=\(.payload.version) supported_interpreters=\(.payload.platform.arm64.dependencies.interpreters)"' <<< "$manifestdata")"	
	else
		lecho_err "Unknown/unsupported cpu architecture!!.Contact support for further assistance."
		exit
	fi

	# if package is disabled notify and exit	
	if [ "$package_enabled" = false ] ; then
		lecho_err "Package installation is unavailable or disabled.Contact support for further assistance."
		exit
	fi

		
	PROGRAM_ARCHIVE_LOCATION=$package_url
	PROGRAM_VERSION=$package_version
	PROGRAM_HASH=$package_hash
	
	# Change comma (,) to whitespace and add under braces
	PROGRAM_SUPPORTED_INTERPRETERS=(`echo $supported_interpreters | tr ',' ' '`)
	echo "Supported interpreters: ${PROGRAM_SUPPORTED_INTERPRETERS[@]}"
	echo "Version: $PROGRAM_VERSION"
}





#############################################
# Returns module package download url (if exists), 
# using the main program package url and module name.
# empty variable/unset variable is returned if module
# does not exist (owing to incorrect name)
# This method does not check if url exists or not
# 
# GLOBALS:
#		PROGRAM_ARCHIVE_LOCATION#
# ARGUMENTS:
#		$1 : module name
# RETURN:
#		Module download url (if exists). Else
# empty variable/unset variable is returned
#############################################
get_module_url()
{
	local module_name="$1.zip"
	local url=$PROGRAM_ARCHIVE_LOCATION
	url=$(echo "$url" | sed "s/core/modules/")
	url=$(echo "$url" | sed "s/grahil.zip/$module_name/")

	if http_file_exists $url; then
		echo $url
	else
		local NULL
		echo $NULL
	fi
}




#############################################
# Returns profile package download url (if exists), 
# using the main program package url and profile name.
# empty variable/unset variable is returned if profile
# does not exist (owing to incorrect name)
# This method does not check if url exists or not
# 
# GLOBALS:
#		PROGRAM_ARCHIVE_LOCATION#
# ARGUMENTS:
#		$1 : profile name
# RETURN:
#		profile download url (if exists). Else
# empty variable/unset variable is returned
#############################################
get_profile_url()
{
	local profile_name="$1.zip"
	local url=$PROGRAM_ARCHIVE_LOCATION
	url=$(echo "$url" | sed "s/core/profiles/")
	url=$(echo "$url" | sed "s/grahil.zip/$profile_name/")
	url=$(echo "$url" | sed "s#$PLATFORM_ARCH/##")	

	if http_file_exists $url; then
		echo $url
	else
		local NULL
		echo $NULL
	fi
}





#############################################
# Check if file exists over a http url
# 
# GLOBALS:
#		
# ARGUMENTS:
#		$1: HTTP url of the file
# RETURN:
#		true if file exists otherwise false
#############################################
http_file_exists()
{
	local module_url=$1
	if wget --spider $module_url 2>/dev/null; then
		true
	else
		false
	fi
}



#############################################
# Enable a grahil module
# 
# GLOBALS:
#		
# ARGUMENTS:
#		$1: Module name
# RETURN:
#		
#############################################
enable_module()
{
	local module_name=$1
	local module_conf_path="$DEFAULT_PROGRAM_PATH/modules/conf/$module_name.json"

	if [ -f "$module_conf_path" ]; then
		echo "$(jq '.enabled = "true"' $module_conf_path)" > $module_conf_path
	else
		echo "Module config for '$module_name' not found!"
	fi
}




#############################################
# Disable a grahil module
# 
# GLOBALS:
#		
# ARGUMENTS:
#		$1: Module name
# RETURN:
#		
#############################################
disable_module()
{
	local module_name=$1
	local module_conf_path="$DEFAULT_PROGRAM_PATH/modules/conf/$module_name.json"
	
	if [ -f "$module_conf_path" ]; then
		echo "$(jq '.enabled = "false"' $module_conf_path)" > $module_conf_path
	else
		echo "Module config for '$module_name' not found!"
	fi
}




#############################################
# Installs a grahil module meant for current 
# platform/python version from the archives to
# the currently active grahil installation
# 
# NOTE: Requires build manifest, system detection
# as well as python detection.
#
# GLOBALS:
#		DEFAULT_PROGRAM_PATH, PROGRAM_NAME
#
# ARGUMENTS:
#			$1 = module name - String
#			$2 = base directory path of grahil installation. defaults to DEFAULT_PROGRAM_PATH - String path
#			$3 = Whether to force install (overwriting without prompt). - Boolean
#
#
# RETURN:
#		
#############################################
install_module()
{
	local module_name=
	local base_dir=$DEFAULT_PROGRAM_PATH	
	local force=false
	local return_status=0
	local error=0
	local err_message=

	check_current_installation 1 1

	if [ "$program_exists" -eq 1 ]; then

		if [ $# -lt 0 ]; then
			error=1
			err_message="Minimum of 1 parameter is required!"
		else
			if [ $# -gt 3 ]; then
				module_name=$1
				base_dir=$2
				force=$3
				return_status=$4
				if [[ "$return_status" -eq 1 ]]; then
					force=true
				fi
			elif [ $# -gt 2 ]; then
				module_name=$1
				base_dir=$2
				force=$3
			elif [ $# -gt 1 ]; then
				module_name=$1
				base_dir=$2
			elif [ $# -gt 0 ]; then
				module_name=$1 
			fi


			# check and see if module excists and if yes fetch url
			local deploy_path="$base_dir/oneadmin/modules"
			local module_conf="$deploy_path/conf/$module_name.json"
			local url=$(get_module_url $module_name)			


			if [ -z "$url" ]; then

				error=1
				err_message="Module not found/cannot be installed!"
			
			elif [ -f "$module_conf" ]; then

				if [ "$force" = false ] ; then

					local response=
					lecho "Module already exists. Proceeding forward operation will overwrite the existing module."
					read -r -p "Do you wish to continue? [y/N] " response
						case $response in
						[yY][eE][sS]|[yY]) 
							lecho "Installing module.."
						;;
						*)
							error=1
							err_message="Module installation cancelled!"
						;;
						esac
				fi
			fi
		fi


		# ALL OK -> Do Ops	
		if [[ "$error" -eq 0 ]]; then			

			local current_python="${PYTHON_VERSION//./}"
			local tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
			local module="$tmp_dir/$module_name.zip"	
			local dest="$tmp_dir/$module_name"

			sudo wget -O "$module" "$url"
			sudo unzip $module -d "$dest"

			for j in "$dest"/*; do

				local name=$(basename -- "$j")
				local filename="${name%.*}"

				if [[ "$name" == *"$current_python.so" ]]; then				
					# Move tmp file to main location
					lecho "Moving runtime file $j to $deploy_path/$module_name.so"
					sudo mv $j $deploy_path/$module_name.so
					sudo chown $USER: "$deploy_path/$module_name.so"

					# so and py versions of same module are mutually exclusive
					if [ -f "$deploy_path/$filename.py" ]; then
						sudo rm "$deploy_path/$module_name.py"
					fi

				elif [[ $name == *".json" ]]; then					
					# Move tmp file to main location
					lecho "Moving conf file $j to $deploy_path/conf/$module_name.json"
					sudo mv $j $deploy_path/conf/$module_name.json
					sudo chown $USER: "$deploy_path/conf/$module_name.json"
				elif [[ $name == *".py" ]]; then					
					# Move tmp file to main location
					lecho "Moving runtime file $j to $deploy_path/$module_name.py"
					sudo mv $j $deploy_path/$module_name.py
					sudo chown $USER: "$deploy_path/$module_name.py"

					# so and py versions of same module are mutually exclusive
					if [ -f "$deploy_path/$filename.so" ]; then
						sudo rm "$deploy_path/$module_name.so"
					fi			
				fi

			done

			if [[ "$return_status" -eq 1 ]]; then
				error=0 && echo $error
			else
				lecho "Processing completed. You may want to restart $PROGRAM_NAME service"
			fi

		else

			if [[ "$return_status" -eq 1 ]]; then
				error=1 && echo $error
			else
				lecho_err "An error occurred. $err_message"
			fi		

		fi			
	
	else

		if [[ "$return_status" -eq 1 ]]; then
			error=1 && echo $error
		else
			lecho_err "Program core was not found. Please install the program before attempting to install modules."
		fi		
	fi
}




#############################################
# Removes a grahil module meant from
# the currently active grahil installation
# 
# GLOBALS:
#		DEFAULT_PROGRAM_PATH, PROGRAM_NAME
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
remove_module()
{
	#local current_python="38"
	local module_name=$1
	local deploy_path="$DEFAULT_PROGRAM_PATH/oneadmin/modules"
	local found=false
	

	for j in $(find $deploy_path -type f -print)
	do				
		local name=$(basename -- "$j")
		local filename="${name%.*}"

		if [[ $name == *$module_name.so ]]; then					
			# Move tmp file to main location
			found=true
			lecho "Removing module file $j"
			sudo rm -rf $j
		elif [[ $name == *$module_name.json ]]; then					
			# Move tmp file to main location
			found=true
			lecho "Removing module config $j"
			sudo rm -rf $j
		elif [[ $name == *$module_name.py ]]; then					
			# Move tmp file to main location
			found=true
			lecho "Removing module file $j"
			sudo rm -rf $j
		fi

	done
	
	if $found
	then 
		lecho "Processing completed. You may want to restart $PROGRAM_NAME service"
	else
		lecho "Module not found. Nothing was removed"
	fi
}



#############################################
# Installs a grahil profile meant for current 
# platform/python version from the archives to
# the currently active grahil installation
# 
# NOTE: Requires build manifest, system detection
# as well as python detection.
#
# GLOBALS:
#		DEFAULT_PROGRAM_PATH, PROGRAM_NAME
#
# ARGUMENTS:
#			$1 = profile name - String
#			$2 = base directory path of grahil installation. defaults to DEFAULT_PROGRAM_PATH - String path
#			$3 = Whether to force install (overwriting without prompt). - Boolean
#
#
# RETURN:
#		
#############################################
install_profile()
{
	local profile_name=
	local base_dir=$DEFAULT_PROGRAM_PATH	
	local force=false
	local return_status=0
	local error=0
	local err_message=	

	check_current_installation 1 1

	if [ "$program_exists" -eq 1 ]; then

		if [ $# -lt 0 ]; then
			error=1
			err_message="Minimum of 1 parameter is required!"
		else
			if [ $# -gt 2 ]; then
				profile_name=$1
				base_dir=$2
				force=$3
			elif [ $# -gt 1 ]; then
				profile_name=$1
				base_dir=$2
			elif [ $# -gt 0 ]; then
				profile_name=$1 
			fi

			local url=$(get_profile_url $profile_name)			
			if [ -z "$url" ]; then
				error=1
				err_message="Profile not found/cannot be installed!"
			fi

			# ALL OK -> Do Ops		
			if [[ "$error" -eq 0 ]]; then

				local tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
				local profile_archive="$tmp_dir/$profile_name.zip"	
				local profile_package_path="$tmp_dir/$profile_name"

				local module_conf_source_path="$profile_package_path/modules/conf"
				local scripts_source_path="$profile_package_path/scripts"
				local rules_source_path="$profile_package_path/rules"
				
				local module_install_path="$base_dir/oneadmin/modules"
				local module_conf_install_path="$base_dir/oneadmin/modules/conf"
				local scripts_install_path="$base_dir/scripts"
				local rules_install_path="$base_dir/rules"

				# extract profile archive to a tmp location

				sudo wget -O "$profile_archive" "$url"
				sudo unzip $profile_archive -d $profile_package_path	

				# read meta file
				local meta_file="$profile_package_path/meta.json"
				local result=$(<$meta_file)

				local profile_name=$(jq -r '.name' <<< ${result})		
				local add_modules=($(jq -r '.modules.add' <<< ${result}  | tr -d '[]," '))		
				local remove_modules=($(jq -r '.modules.remove' <<< ${result}  | tr -d '[]," '))
				local add_rules=($(jq -r '.rules.add' <<< ${result}  | tr -d '[]," '))
				local remove_rules=($(jq -r '.rules.remove' <<< ${result}  | tr -d '[]," '))
				local add_scripts=($(jq -r '.scripts.add' <<< ${result}  | tr -d '[]," '))
				local remove_scripts=($(jq -r '.scripts.remove' <<< ${result}  | tr -d '[]," '))

				# install required modules
				local module_install_error=0

				for module in "${add_modules[@]}"
				do
				
					local install_error=$(install_module $module $DEFAULT_PROGRAM_PATH true 1)
					
					if [ "$install_error" -eq 1 ]; then					
						err_message="Failed to install module $module."
						module_install_error=1 && error=1
						break
					fi

					local module_conf_source_file="$module_conf_source_path/$module.json"
					local module_conf_target_file="$module_conf_install_path/$module.json"			

					# copy over any specific configuration
					if [ -f "$module_conf_source_file" ]; then
						lecho "Copying over custom module configuration $module_conf_source_file to $module_conf_target_file"
						sudo mv $module_conf_source_file $module_conf_target_file				
					fi

					# enable required modules
					local tmpfile=$(echo "${module_conf_target_file/.json/.tmp}")
					sudo echo "$( jq '.enabled = "true"' $module_conf_target_file )" > $tmpfile
					sudo mv $tmpfile $module_conf_target_file

				done

				# If no module installer error -> continue profile setup

				if [[ "$module_install_error" -eq 0 ]]; then

					# remove unwanted modules
					for module in "${remove_modules[@]}"
					do
						local module_so_file="$module_install_path/$module.so"
						local module_py_file="$module_install_path/$module.py"
						local module_conf_file="$module_conf_install_path/$module.json"

						# delete module file
						if [ -f "$module_so_file" ]; then
							lecho "Deleting module file $module_so_file"
							sudo rm $module_so_file
						elif [ -f "$module_py_file" ]; then
							lecho "Deleting module file $module_py_file"
							sudo rm $module_py_file
						fi

						# delete module conf file
						if [ -f "$module_conf_file" ]; then
							lecho "Deleting module config file $module_conf_file"
							sudo rm $module_conf_file
						fi

					done


					# install required rules

					for rule in "${add_rules[@]}"
					do

						local installable_rule="$rules_source_path/$rule.json" 
						local target_rule="$rules_install_path/$rule.json"

						if [ -f "$installable_rule" ]; then
							if [ ! -f "$target_rule" ]; then
								lecho "Moving rule $installable_rule to $target_rule"
								sudo mv $installable_rule $target_rule
							else
								lecho "Target rule already exists. Skipping rule installation for $installable_rule"					
							fi
						else
							lecho "Something is wrong! Installable rule $installable_rule does not exist in the profile package."					
						fi

					done



					# remove unwanted rules

					for rule in "${remove_rules[@]}"
					do

						local removable_rule="$rules_install_path/$rule.json"

						if [ -f "$removable_rule" ]; then
							sudo rm $removable_rule
						else
							lecho "Rule $removable_rule does not exist at target location. Nothing to remove here!."					
						fi

					done


					# install required scripts

					for script in "${add_scripts[@]}"
					do
							
						local installable_script="$scripts_install_path/$script.json" 
						local target_script="$scripts_source_path/$script.json"

						if [ -f "$installable_script" ]; then
							if [ ! -f "$target_script" ]; then
								lecho "Moving script $installable_script to $target_script"
								sudo mv $installable_script $target_script
							else
								lecho "Target script already exists. Skipping rule installation for $installable_script"					
							fi
						else
							lecho "Something is wrong! Installable script $installable_script does not exist in the profile package."					
						fi

					done


					# remove unwanted scripts

					for script in "${remove_scripts[@]}"
					do

						local removable_script="$scripts_install_path/$script.json"

						if [ -f "$removable_script" ]; then
							sudo rm $removable_script
						else
							lecho "Script $removable_script does not exist at target location. Nothing to remove here!."					
						fi

					done


					# once eveything is done mark current profile selection 
					# => store active profile somewhere
					if [ ! -f "$PROGRAM_INSTALLATION_REPORT_FILE" ]; then
						echo "No installation report found."
					else
						update_installation_meta $profile_name
					fi


					# restart service
					restart_grahil_service


					if [[ "$return_status" -eq 1 ]]; then
						error=0 && echo $error
					else
						lecho "Processing completed. You may want to restart $PROGRAM_NAME service"
					fi

				else

					# If there is module instalaltion error during profile installation,
					# we remove all profile related modules
					
					for module in "${add_modules[@]}"
					do

						local module_so_file="$module_install_path/$module.so"
						local module_py_file="$module_install_path/$module.py"
						local module_conf_file="$module_conf_install_path/$module.json"

						# delete module file
						if [ -f "$module_so_file" ]; then
							lecho "Deleting module file $module_so_file"
							sudo rm $module_so_file
						elif [ -f "$module_py_file" ]; then
							lecho "Deleting module file $module_py_file"
							sudo rm $module_py_file
						fi

						# delete module conf file
						if [ -f "$module_conf_file" ]; then
							lecho "Deleting module config file $module_conf_file"
							sudo rm $module_conf_file
						fi

					done


					if [[ "$return_status" -eq 1 ]]; then
						error=1 && echo $error
					else
						lecho_err "Error in module installation to install module $err_message."
					fi									
				fi				
			else
				if [[ "$return_status" -eq 1 ]]; then
					error=1 && echo $error
				else
					lecho_err "An error occurred. $err_message"
				fi
			fi
		fi	
	else

		if [[ "$return_status" -eq 1 ]]; then
			error=1 && echo $error
		else
			lecho_err "Program core was not found. Please install the program before attempting to install profiles."
		fi		
	fi
	
}




#############################################
# Registers cron in root's crontab to run autoupdater
# once a day at designated hour.
# 
# GLOBALS:
#		PROGRAM_UPDATE_CRON_HOUR
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
register_updater()
{
	local SCRIPT_PATH=$(realpath $0)

	# file method
	#sudo crontab -l > cronjobs.txt
	#sudo crontab -l | grep -v "$SCRIPT_PATH -u 1" > cronjobs.txt
	#echo "0 11 * * * $SCRIPT_PATH -u 1" >> cronjobs.txt
	#sudo crontab cronjobs.txt	

	# direct method
	lecho "Registering autoupdater..."
	sudo crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH -u 1" | sudo crontab -	
	(sudo crontab -l 2>/dev/null; echo "0 $PROGRAM_UPDATE_CRON_HOUR * * * $SCRIPT_PATH -u 1") | sudo crontab -
}





#############################################
# Deregisters autoupdate cron from root's crontab.
# 
# GLOBALS:
#		PROGRAM_UPDATE_CRON_HOUR
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
deregister_updater()
{
	local SCRIPT_PATH=$(realpath $0)

	# direct method
	write_log "Deregistering autoupdater..."
	sudo crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH -u 1" | sudo crontab -	
}



# Parse the major, minor and patch versions
# out.
# You use it like this:
#    semver="3.4.5+xyz"
#    a=($(parse_semver "$semver"))
#    major=${a[0]}
#    minor=${a[1]}
#    patch=${a[2]}
#    printf "%-32s %4d %4d %4d\n" "$semver" $major $minor $patch
function parse_semver() {
    local token="$1"
    local major=0
    local minor=0
    local patch=0

    if egrep '^[0-9]+\.[0-9]+\.[0-9]+' <<<"$token" >/dev/null 2>&1 ; then
        # It has the correct syntax.
        local n=${token//[!0-9]/ }
        local a=(${n//\./ })
        major=${a[0]}
        minor=${a[1]}
        patch=${a[2]}
    fi
    
    echo "$major $minor $patch"
}




#############################################
# Reads and returns program's version string
# 
# GLOBALS:
#		PROGRAM_UPDATE_CRON_HOUR
#
# ARGUMENTS:
#
# RETURN:
#		String representing version number
#		
#############################################
get_program_version()
{
	local version_file="$1"
	local existing_version=
	local version=
	local old_version_num=

	while IFS= read -r line
	do
	if [[ $line = __version__* ]]
		then
			existing_version="${line/$target/$blank}" 
			break
	fi

	done < "$version_file"

	local replacement=""
	version=$(echo "$existing_version" | sed "s/__version__/$replacement/")
	version=$(echo "$version" | sed "s/=/$replacement/")
	version=$(echo "$version" | sed "s/'/$replacement/")
	version=$(echo "$version" | sed "s/'/$replacement/")
	version=`echo $version`
	echo $version
}




#############################################
# Performs rollback on a recently failed update
# 
# GLOBALS:
#		INSTALLATION_PYTHON_VERSION, DEFAULT_PROGRAM_PATH
#		PYTHON_MAIN_FILE
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
rollback_update()
{
	local err=0
	lecho "Attempting roll back"


	# We need to get back esrlier python version or compatible python version
	PYTHON_VERSION=$INSTALLATION_PYTHON_VERSION


	# delete from main location where updated content was placed
	sudo rm -rf $DEFAULT_PROGRAM_PATH/*


	# stop running service of program
	echo "Stopping running program"
	if is_service_installed; then
		if is_service_running; then
			stop_grahil_service
		fi
	fi


	# copy back old files into main location
	local temp_dir_for_existing=$1	
	sudo cp -a $temp_dir_for_existing/. $DEFAULT_PROGRAM_PATH/
	if [ ! -f "$DEFAULT_PROGRAM_PATH/$PYTHON_MAIN_FILE" ]; then
		lecho "Copy unsuccessful. Update will now exit! Installation is probably broken. Remove & Re-Install program manually to fix the issue."
		exit 1
	fi


	# We need to create virtual environment for esrlier python
	post_download_install	
}




#############################################
# Performs an update of the currently installed
# program.
# 
# GLOBALS:
#		PROGRAM_CONFIGURATION_MERGER, PROGRAM_VERSION,
#		PROGRAM_DOWNLOAD_URL, DEFAULT_PROGRAM_PATH, 
#		PYTHON_MAIN_FILE, PYTHON_VIRTUAL_ENV_INTERPRETER,
#		PROGRAM_SUPPORTED_INTERPRETERS, PROGRAM_ERROR_LOG_FILE_NAME
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
update()
{	
	
	local CAN_UPDATE=0

	if is_first_time_install; then
		lecho "This is a first time installation. Update cannot proceed!"
		exit 1
	fi	

	
	local MERGE_SCRIPT="$PWD/$PROGRAM_CONFIGURATION_MERGER"	

	## get version info of available file 
	local available_version_string=$PROGRAM_VERSION
	local available_version=($(parse_semver "$available_version_string"))
	local major_new=${available_version[0]}
	local minor_new=${available_version[1]}
	local patch_new=${available_version[2]}

	# read version info from installed program
	local version_file="$DEFAULT_PROGRAM_PATH/oneadmin/version.py"
	local installed_version_string=($(get_program_version "$version_file"))
	local installed_version=($(parse_semver "$installed_version_string"))
	local major_old=${installed_version[0]}
	local minor_old=${installed_version[1]}
	local patch_old=${installed_version[2]}

	
	# check to see if upgrade is possible
	if [[ "$major_new" -gt "$major_old" ]]; then
		CAN_UPDATE=1
	elif [[ "$minor_new" -gt "$minor_old" ]]; then
		CAN_UPDATE=1
	elif [[ "$patch_new" -gt "$patch_old" ]]; then
		CAN_UPDATE=1
	fi


	# check if can update and exit if not
	if [ $CAN_UPDATE -eq 0 ]; then
		lecho "Program is not elligible for an update. Update will now exit!"
		exit 1
	else
		lecho "Ready to update!"
	fi

	
	# download archive and extract into a tmp location
	local latest_download_success=0
	local ARCHIVE_FILE_NAME=$PROGRAM_ARCHIVE_NAME
	local PROGRAM_DOWNLOAD_URL=$(curl -s "$PROGRAM_MANIFEST_LOCATION" | grep -Pom 1 '"url": "\K[^"]*')

	local temp_dir_for_latest=$(mktemp -d -t ci-XXXXXXXXXX)
	local temp_dir_for_existing=$(mktemp -d -t ci-XXXXXXXXXX)
	local temp_dir_for_download=$(mktemp -d -t ci-XXXXXXXXXX)
	local temp_dir_for_updated=$(mktemp -d -t ci-XXXXXXXXXX)
	local downloaded_archive="$temp_dir_for_download/$ARCHIVE_FILE_NAME"

	echo "Downloading program url $PROGRAM_DOWNLOAD_URL"
	sudo wget -O "$downloaded_archive" "$PROGRAM_DOWNLOAD_URL"

	# extract package to tmp
	if [ -f "$downloaded_archive" ]; then
		echo "download success"
		archive_hash=md5=`md5sum ${downloaded_archive} | awk '{ print $1 }'`
		sudo unzip "$downloaded_archive" -d "$temp_dir_for_latest"

		if [ -f "$temp_dir_for_latest/$PYTHON_MAIN_FILE" ]; then
			echo "Extraction successful"

			# double check version number
			local new_version_file="$temp_dir_for_latest/oneadmin/version.py"
			local new_version=($(get_program_version "$new_version_file"))

			if [[ "$available_version_string" != "$new_version" ]]; then
				echo "Version defined by manifest $available_version_string and actual version of downloaded file $new_version are not same"
				exit 1
			fi
		else
			echo "Extraction failed. Update will now exit!"
			exit 1
		fi
	fi


	# stop running service of program	
	if is_service_installed; then
		echo "Stopping running program"
		if is_service_running; then
			stop_grahil_service
		fi
	fi


	# check to see if python version has changed. if yes create new virtual environment	
	local gotpython=0
	echo "Checking to see if we already have necessary version of python for this update or we need to install"
	for ver in "${PROGRAM_SUPPORTED_INTERPRETERS[@]}"
	do
		if [[ "$ver" == "$INSTALLATION_PYTHON_VERSION" ]]; then
			gotpython=1
			break
		fi
	done

	# installs python + creates virtual environment and install dependencies as well
	if [ $gotpython -eq 0 ]; then
		# python version has changed so we need tro install compatible version fo python and create Virtual environment again
		echo "Installing required version of python" && sleep 5
		prerequisites_python && post_download_install
	else
		#python version is unchanged so just install requirements again
		echo "Python version is ok. No need to install new version. Simply reinstall dependencies" && sleep 5
		install_python_program_dependencies
	fi


	# Discover list of modules found in the new build
	local new_modules=()
	local module_conf_dir2="$temp_dir_for_latest/oneadmin/modules/conf"
	for i in $(find $module_conf_dir2 -type f -print)
	do
		if [[ $i == *.json ]]; then
			local filename=$(basename -- "$i")
			local extension="${filename##*.}"
			local filename="${filename%.*}"
			new_modules+=($filename)		
		fi
	done


	# >>> Collect list of modules in existing <<<
	local existing_modules=()
	local module_conf_dir="$DEFAULT_PROGRAM_PATH/oneadmin/modules/conf"
	for i in $(find $module_conf_dir -type f -print)
	do
		if [[ $i == *.json ]]; then
			local filename=$(basename -- "$i")
			local extension="${filename##*.}"
			local filename="${filename%.*}"
			existing_modules+=($filename)	
		fi
	done


	# >>> Install updates for existing modules as well <<<
	lecho "Installing addon modules for latest build"
	local base_dir=$temp_dir_for_latest
	for i in "${existing_modules[@]}"
	do
	: 		
		if [[ ! " ${new_modules[*]} " == *" $i "* ]]; then
			sleep 1
			lecho "Module $i was not found in latest core build. attempting to install as an addon.."
			install_module $i $temp_dir_for_latest true # force install module into latest build download
		fi
	done


	# copy current to tmp workspace
	sudo cp -a $DEFAULT_PROGRAM_PATH/. $temp_dir_for_existing/
	if [ ! -f "$temp_dir_for_existing/$PYTHON_MAIN_FILE" ]; then
		lecho "Copy unsuccessful. Update will now exit!"
		exit 1
	fi	


	## First we copy all old files into update workspace
	sudo cp -a $temp_dir_for_existing/. $temp_dir_for_updated/
	if [ ! -f "$temp_dir_for_updated/$PYTHON_MAIN_FILE" ]; then
		lecho "Copy unsuccessful. Update will now exit!"
		exit 1
	fi


	
	# leave all files that are in old version but not in new version (custom modules and custom rules and custom scripts)
	# carefully merge old configuration json with new configuration json -> validate jsons	
	# carefully merge old rules json with new rules json -> validate jsons	
	local EXECUTABLE_PYTHON=$PYTHON_VIRTUAL_ENV_INTERPRETER


	
	# pass tmp dir paths to merger	
	sudo chmod +x $MERGE_SCRIPT
	local merge_result=$(sudo $EXECUTABLE_PYTHON $MERGE_SCRIPT $temp_dir_for_latest $temp_dir_for_updated)
	if [[ $merge_result != *"merge ok"* ]]; then
		lecho "Merging failed. Update will now exit!"
		exit 1
	fi

	if [ ! -f "$temp_dir_for_updated/$PYTHON_MAIN_FILE" ]; then
		lecho "Merging incorrect.Update will now exit!"
		exit 1
	fi


	lecho "Configuration merge successful! @ $temp_dir_for_updated" && sleep 2


	# merge successfull updated tmp dir contains updated program files
	# Overwrite updated installation to active installation
	lecho "Moving updated files to main program directory"

	sudo cp -a $temp_dir_for_updated/. $DEFAULT_PROGRAM_PATH/
	if [ ! -f "$DEFAULT_PROGRAM_PATH/$PYTHON_MAIN_FILE" ]; then
		lecho "Overwrite unsuccessful. Update will now exit!" && exit
	else
		lecho "Unpacking runtime files. Warning old runtime files will be overwritten!"

		# Unpack runtime so files
		unpack_runtime_libraries
	fi	

	
	
	# restart service	
	if is_service_installed; then
		lecho "Restarting program"
		if ! is_service_running; then
			start_grahil_service
		fi
		#optionally monitor error log of the program post startup. 
		#if we see startup errors then revert to old version
		sleep 8 # wait for few seconds to allow service to startup

		local ERROR_LOG_FILE="$DEFAULT_PROGRAM_PATH/$PROGRAM_ERROR_LOG_FILE_NAME"

		if [ -f "$ERROR_LOG_FILE" ]; then
			local error_status=$(grep ERROR $ERROR_LOG_FILE)
			if [ ! -z "$error_status" ]; then 
				lecho "Program seems to have startup errors. Update needs to be reverted"		
				lecho "Update failed!"
				rollback_update $temp_dir_for_existing
			fi
		
		else
			write_installation_meta
			lecho "Update completed successfully"		
		fi
	else

		# if service is not installed we cannot autostart it. so tell user to do it manually instead
		lecho_notice "Update was installed, but you need to run it to see if there are ny errors or not. If you see errors, we advise a rollback of the update or a clean re-install."
	fi
}




#############################################
# Installs grahil
# 
# GLOBALS:
#		latest_download_success
#
# ARGUMENTS:
#
# RETURN:
#		
#############################################
auto_install_program()
{
	write_log "Starting auto-installer"

	latest_download_success=0


	# Download zip or clone from repo based on config
	echo "Preparing to install to $DEFAULT_PROGRAM_PATH"
	sleep 2


	if [ ! -d "$DEFAULT_PROGRAM_PATH" ]; then
		sudo mkdir -p -m "$DEFAULT_PROGRAM_PATH"
		sudo chown -R $USER: "$DEFAULT_PROGRAM_PATH"
	fi


	if [ ! -z "$PROGRAM_GIT_LOCATION" ]; then
		lecho "install_from_git"
		install_from_git
	else
		lecho "install_from_url"
		install_from_url
	fi
		

	if [ "$latest_download_success" -eq 0 ]; then
		lecho_err "Failed to get distribution from source. Please contact support!"
		empty_pause
	fi


	lecho "Program installed successfully!"
	sleep 2
	
}



#############################################
# Starts grahil service using systemctl
# 
# GLOBALS:
#		PROGRAM_SERVICE_LOCATION, PROGRAM_SERVICE_NAME
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################	
start_grahil_service()
{
    lecho "Start grahil service"
    
    sudo systemctl start grahil.service
	if [ "0" -eq $? ]; then
		lecho "grahil service started!"
	else
		lecho "grahil service file was not started!"
		lecho "Please check service file $PROGRAM_SERVICE_LOCATION/$PROGRAM_SERVICE_NAME"
	fi
    sleep 2
}





#############################################
# Restarts grahil service using systemctl
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
restart_grahil_service()
{
	if is_service_installed; then
		stop_grahil_service && sleep 2 && start_grahil_service
	else
		lecho_err "Service not found!"
	fi
}




#############################################
# Stops grahil service using systemctl
# 
# GLOBALS:
#		PROGRAM_SERVICE_LOCATION, PROGRAM_SERVICE_NAME
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################	
stop_grahil_service(){
    lecho "Stop grahil service"
    sudo systemctl stop grahil.service
    sleep 2
}




#############################################
# Checks installation and registers grahil 
# as system service
# 
# GLOBALS:
#		PROGRAM_SERVICE_LOCATION, PROGRAM_SERVICE_NAME
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################	
register_as_service()
{
	check_current_installation 1

	if [ "$program_exists" -eq 1 ]; then

		write_log "Registering service for grahil"

		if [ -f "$PROGRAM_SERVICE_LOCATION/$PROGRAM_SERVICE_NAME" ]; then
			lecho "Service already exists. Do you wish to re-install ?" 
			read -r -p "Are you sure? [y/N] " response

			case $response in
			[yY][eE][sS]|[yY]) 
			register_service
			;;
			*)
			lecho "Service installation cancelled"
			;;
			esac

		else
			register_service
		fi
	fi

	if [ $# -eq 0 ]
	  then
	    empty_pause
	fi
}



#############################################
# Unregister grahil as system service
# 
# GLOBALS:
#		PROGRAM_SERVICE_LOCATION, PROGRAM_SERVICE_NAME
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
unregister_as_service()
{
	check_current_installation 0

	if [ "$program_exists" -eq 1 ]; then

		if [ ! -f "$PROGRAM_SERVICE_LOCATION/$PROGRAM_SERVICE_NAME" ]; then
			lecho "Service does not exists. Nothing to remove" 
		else
			unregister_service
		fi

	fi

	if [ $# -eq 0 ]
	  then
	    empty_pause
	fi
}


#############################################
# Install from archive
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install_archive()
{			
	clear
	lecho "Installing from zip not implemented" && exit
}



#############################################
# Checks if file is a valid archive of grahil
# dist.
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
isValidArchive()
{
	local archive_path=$1

	if [ ! -f "$archive_path" ]; then
		lecho "Invalid archive file path $archive_path"
		false
	else
		local filename=$(basename "$archive_path")

		local extension="${filename##*.}"
		filename="${filename%.*}"

		local filesize=$(stat -c%s "$archive_path")
		
		if [ "$filesize" -lt 30000 ]; then
			lecho "Invalid archive file size detected for $archive_path. Probable corrupt file!"
			false
		else
			case "$extension" in 
			zip|tar|gz*) 
			    true
			    ;;	
			*)
			    lecho "Invalid archive type $extension"
			    false
			    ;;
			esac
		fi
	fi
}



#############################################
# Checks if archive is single level or not
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#		true is it is single level, false otherwise
#	
#############################################
isSingleLevel()
{
	local lvl_tmp=$1
	local count=$(find $lvl_tmp -maxdepth 1 -type d | wc -l)

	if [ $count -gt 2 ]; then
		true
	else
		false
	fi
}


#############################################
# Writes system service file for grahil
# 
# GLOBALS:
#		PYTHON_VIRTUAL_ENV_LOCATION, PROGRAM_FOLDER_NAME,
#		PYTHON_VERSION, PYTHON_VIRTUAL_ENV_INTERPRETER,
#		DEFAULT_PROGRAM_PATH, PYTHON_MAIN_FILE,
#		PROGRAM_SERVICE_LOCATION, PROGRAM_SERVICE_NAME,
#		service_install_success
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
register_service()
{
	# Permission check
	if ! validatePermissions; then
		request_permission;
	fi	

	service_install_success=0


	lecho "Preparing to install service..."
	sleep 2

	
	PYTHON_VIRTUAL_ENV_INTERPRETER="$PYTHON_VIRTUAL_ENV_LOCATION/$PROGRAM_FOLDER_NAME/bin/python$PYTHON_VERSION"

#######################################################

service_script="[Unit]
Description=Grahil Service
After=multi-user.target

[Service]
Type=simple
ExecStart=$PYTHON_VIRTUAL_ENV_INTERPRETER $DEFAULT_PROGRAM_PATH/$PYTHON_MAIN_FILE
Restart=always

[Install]
WantedBy=multi-user.target
"

#######################################################


	lecho "Writing service script"
	sleep 1

	local SERVICE_SCRIPT_PATH="$PROGRAM_SERVICE_LOCATION/$PROGRAM_SERVICE_NAME"

	sudo touch "$SERVICE_SCRIPT_PATH" && sudo chmod 777 "$SERVICE_SCRIPT_PATH"

	# write script to file
	echo "$service_script" > "$SERVICE_SCRIPT_PATH"

	# make service file executable
	sudo chmod 644 "$SERVICE_SCRIPT_PATH"

	lecho "Registering service \"$PROGRAM_SERVICE_NAME\""
	sleep 1	

	# Reload daemon 
	sudo systemctl daemon-reload

	lecho "Enabling service \"$PROGRAM_SERVICE_NAME\""

	# enable service
	sudo systemctl enable "$PROGRAM_SERVICE_NAME"

	lecho "Service installed successfully!"
	service_install_success=1	
}


#############################################
# Removes system service file for grahil
# 
# GLOBALS:
#		PROGRAM_SERVICE_NAME, PROGRAM_SERVICE_LOCATION
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
unregister_service()
{
	# Permission check
	if ! validatePermissions; then
		request_permission;
	fi

	lecho "Unregistering service \"$PROGRAM_SERVICE_NAME\""
	sleep 1	

	local SERVICE_SCRIPT_PATH="$PROGRAM_SERVICE_LOCATION/$PROGRAM_SERVICE_NAME"


	if [ -f "$SERVICE_SCRIPT_PATH" ];	then

		# Reload daemon 
		sudo systemctl daemon-reload

		lecho "Disabling service \"$PROGRAM_SERVICE_NAME\""

		# disaable service
		sudo systemctl disable "$PROGRAM_SERVICE_NAME"
		
		# remove service
		sudo rm -f "$SERVICE_SCRIPT_PATH"

		lecho "Service removed successfully"
	fi
}



#############################################
# Checks to see if service is installed or not.
# 
# GLOBALS:
#		PROGRAM_SERVICE_NAME, PROGRAM_SERVICE_LOCATION
#
# ARGUMENTS:
#
# RETURN:
#		true is service is installed, false otherwise
#	
#############################################
is_service_installed()
{
	if [ ! -f "$PROGRAM_SERVICE_LOCATION/$PROGRAM_SERVICE_NAME" ];	then
	false
	else
	true
	fi
}



#############################################
# Checks to see if service is installed or not.
# 
# GLOBALS:
#		PROGRAM_SERVICE_NAME
#
# ARGUMENTS:
#
# RETURN:
#		true is service is installed, false otherwise
#	
#############################################
is_service_running()
{
	if systemctl is-active --quiet $PROGRAM_SERVICE_NAME; then
		true
	else
		false
	fi
}



#############################################
# Checks and verifies the current installation 
# of grahil. Takes two optional arguments.
# 
# GLOBALS:
#		PROGRAM_SERVICE_NAME
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
check_current_installation()
{
	program_exists=0
	local check_silent=0
	local version=""

	# IF second param is set then turn on silent mode quick check
	if [ $# -eq 2 ]; then
		check_silent=1		
	fi


	if [ ! "$check_silent" -eq 1 ] ; then
		lecho "Looking for program at install location..."
		sleep 2
	fi


	if [ ! -d $DEFAULT_PROGRAM_PATH ]; then
		if [ ! "$check_silent" -eq 1 ] ; then
  		lecho "No installation found at install location : $DEFAULT_PROGRAM_PATH"
		fi
	else
		local executable="$DEFAULT_PROGRAM_PATH/$PYTHON_MAIN_FILE"
		local rules_directory="$DEFAULT_PROGRAM_PATH/rules"

		
		if [ -f $executable ]; then			
			if [ -d "$rules_directory" ]; then
				program_exists=1

				version_file="$DEFAULT_PROGRAM_PATH/oneadmin/version.py"
				while IFS= read -r line
				do
				if [[ $line = __version__* ]]
					then
						version_found_old="${line/$target/$blank}" 
						break
				fi

				done < "$version_file"

				local replacement=""
				version=$(echo "$version_found_old" | sed "s/__version__/$replacement/")
				version=$(echo "$version" | sed "s/=/$replacement/")


				local old_version_num=
				IFS='.'
				read -ra ADDR <<< "$version_found_old"
				count=0
				ver_num=""
				for i in "${ADDR[@]}"; do # access each element of array
					old_version_num="$old_version_num$i"
					count=$((count+1))	
					if [[ $count -eq 3 ]]; then
					break
					fi	
				done
				IFS=' '

				old_version_num=$(echo "${old_version_num// /}")
				old_version_num=${old_version_num//\'/}
				old_version_num=$__version__

				if [ ! "$check_silent" -eq 1 ] ; then
					lecho "Installation of version $version found at install location : $DEFAULT_PROGRAM_PATH"
				fi
			fi
		else
			lecho "There were files found at install location : $DEFAULT_PROGRAM_PATH, but the installation might be broken !. I could not locate version information"
		fi
				
	fi

	if [ $# -eq 0 ]; then
		empty_line		
	fi


	# return true or false
	if [ ! "$program_exists" -eq 1 ] ; then
		true
	else
		false
	fi

}


#############################################
# Writes instalaltion report after a successful
# installation.
# 
# GLOBALS:
#		PYTHON_VERSION, PYTHON_VIRTUAL_ENV_LOCATION,
#		REQUIREMENTS_FILE, PROGRAM_INSTALLATION_REPORT_FILE
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
write_installation_meta()
{
	local now=$(date)
	local installtime=$now
	local profile=$CURRENT_INSTALLATION_PROFILE
	local pythonversion=${PYTHON_VERSION/python/$replacement}
	local replacement=""
	local subject="python"
	local interpreterpath="$PYTHON_VIRTUAL_ENV_LOCATION/$PROGRAM_FOLDER_NAME/bin/python$PYTHON_VERSION"
	local requirements_filename=$(basename -- "$REQUIREMENTS_FILE")
	
	jq -n --arg profile "$profile" --arg interpreterpath "$interpreterpath" --arg pythonversion "$pythonversion" --arg installtime "$installtime" --arg requirements_filename "$requirements_filename" '{install_time: $installtime, python_version: $pythonversion, interpreter: $interpreterpath, requirements: $requirements_filename}' | sudo tee "$PROGRAM_INSTALLATION_REPORT_FILE" > /dev/null
}





#############################################
# Updates current instalaltion profile in the instalaltion report
# 
# GLOBALS:
#	PROGRAM_INSTALLATION_REPORT_FILE
#
# ARGUMENTS:
#	$1: Profile name
#
# RETURN:
#	
#############################################
update_installation_meta()
{
	if [ ! -f "$PROGRAM_INSTALLATION_REPORT_FILE" ]; then
		lecho_err "No installation report found."
	else

		if [ $# -gt 0 ]; then
			profile_name=$1	
			CURRENT_INSTALLATION_PROFILE=$profile_name
			local result=$(<$PROGRAM_INSTALLATION_REPORT_FILE)
			local tmpfile=$(echo "${PROGRAM_INSTALLATION_REPORT_FILE/.json/.tmp}")
			sudo echo "$( jq '.profile = "$CURRENT_INSTALLATION_PROFILE"' $PROGRAM_INSTALLATION_REPORT_FILE )" > $tmpfile
			sudo mv $tmpfile $PROGRAM_INSTALLATION_REPORT_FILE
		else
			lecho_err "Minimum of 1 parameter is required!"
		fi	

	fi
}




#############################################
# Reads from existing instalaltion report
# 
# GLOBALS:
#		INSTALLATION_PYTHON_VERSION, PROGRAM_INSTALLATION_REPORT_FILE,
#		PYTHON_VIRTUAL_ENV_INTERPRETER, PYTHON_REQUIREMENTS_FILENAME
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
read_installation_meta()
{
	if [ ! -f "$PROGRAM_INSTALLATION_REPORT_FILE" ]; then
		echo "No installation report found."
	else
		local result=$(<$PROGRAM_INSTALLATION_REPORT_FILE)
		local installtime=$(jq -r '.install_time' <<< ${result})
		local pythonversion=$(jq -r '.python_version' <<< ${result})
		local interpreterpath=$(jq -r '.interpreter' <<< ${result})
		local requirements_filename=$(jq -r '.requirements' <<< ${result})
		local profile=$(jq -r '.profile' <<< ${result})

		INSTALLATION_PYTHON_VERSION="$pythonversion"
		PYTHON_VIRTUAL_ENV_INTERPRETER=$interpreterpath
		PYTHON_REQUIREMENTS_FILENAME=$requirements_filename
		CURRENT_INSTALLATION_PROFILE=profile
	fi
}




#############################################
# Deletes existing instalaltion report
# 
# GLOBALS:
#		PROGRAM_INSTALLATION_REPORT_FILE
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
clear_installation_meta()
{
	if [ -f "$PROGRAM_INSTALLATION_REPORT_FILE" ]; then
		sudo rm -rf "$PROGRAM_INSTALLATION_REPORT_FILE"
	fi
}



#############################################
# Checks to see if this is first time installation
# or not. Also reads the installation report to memory.
# 
# GLOBALS:
#		PROGRAM_INSTALLATION_REPORT_FILE
#
# ARGUMENTS:
#
# RETURN:
#		true if thsi is first time installation , otherwise false
#	
#############################################
is_first_time_install()
{
	if [ -f "$PROGRAM_INSTALLATION_REPORT_FILE" ]; then
		read_installation_meta
		if [ -z ${INSTALLATION_PYTHON_VERSION+x} ]; then 
			true 
		else
			false
		fi
	else
		true
	fi

}




#############################################
# Performs additional steps needed after 
# installing the main python program. This usually 
# includes creating virtual enviromnent, installing
# dependencies etc:
# 
# GLOBALS:
#		virtual_environment_exists, virtual_environment_valid,
#		PROGRAM_SERVICE_AUTOSTART
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
post_download_install()
{
	check_create_virtual_environment

	if [[ $virtual_environment_exists -eq 1 ]]; then	
		
		activate_virtual_environment

		if [[ $virtual_environment_valid -eq 1 ]]; then	
			
			install_python_program_dependencies

			deactivate_virtual_environment

			write_installation_meta

			if $PROGRAM_INSTALL_AS_SERVICE; then

				# stop if running
				if is_service_installed; then
					if is_service_running; then
						stop_grahil_service	
					fi
				fi

				# Remove if exists
				if is_service_installed; then
					unregister_as_service 1
				fi
				
				# Install
				register_as_service 1				

				if $PROGRAM_SERVICE_AUTOSTART; then
					start_grahil_service
				fi
			fi

			# register cron for update
			# deregister_updater && register_updater
		else
			echo -e "\e[41m Invalid virtual environment!\e[m"
		fi
	else
		echo -e "\e[41m Failed to create virtual environment!\e[m"
	fi
}




#############################################
# Removes the existing installation of grahil
# 
# GLOBALS:
#		PYTHON_VIRTUAL_ENV_LOCATION, PROGRAM_FOLDER_NAME,
#		VENV_FOLDER, DEFAULT_PROGRAM_PATH
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
uninstall()
{
	# stop if running
	if is_service_installed; then
		if is_service_running; then
			stop_grahil_service	
		fi
	fi

	# Remove if exists
	if is_service_installed; then
		unregister_as_service 1
	fi
	

	# remove virtual environment
	VENV_FOLDER="$PYTHON_VIRTUAL_ENV_LOCATION/$PROGRAM_FOLDER_NAME"
	if [ -d "$VENV_FOLDER" ]; then	
		sudo rm -rf "$VENV_FOLDER"
	fi

	# remove program files
	if [ -d "$DEFAULT_PROGRAM_PATH" ]; then	
		sudo rm -rf "$DEFAULT_PROGRAM_PATH"
	fi

	# remove installation info
	clear_installation_meta

	# remove autoupdater (if exists)
	deregister_updater

	lecho "Uninstall completed successfully!"
}




#############################################
# Main install method 
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
install()
{
	if ! validatePermissions; then
		request_permission;
	fi

	auto_install_program

	if [[ $latest_download_success -eq 1 ]]; then
		post_download_install
	else
		echo -e "\e[41m Failed to install program!\e[m"
	fi	
}


######################################################################################
################################ INIT FUNCTIONS ######################################


#############################################
# Loads installer configuration from config.ini file
# 
# GLOBALS:
#		CONFIGURATION_FILE, PROGRAM_INSTALL_LOCATION
#		CURRENT_DIRECTORY, DEFAULT_PROGRAM_PATH
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
load_configuration()
{
	if [ ! -f $CONFIGURATION_FILE ]; then

		echo -e "\e[41m CRITICAL ERROR!! - Configuration file not found!\e[m"
		echo -e "\e[41m Exiting...\e[m"
		exit 1
	fi

	# Load config values
	source "$CONFIGURATION_FILE"


	# Set install location if not set

	CURRENT_DIRECTORY=$PWD


	if [ -z ${PROGRAM_FOLDER_NAME+x} ]; then 
		PROGRAM_FOLDER_NAME=$PROGRAM_NAME
	fi
	

	if [ -z ${PROGRAM_INSTALL_LOCATION+x} ]; then 
		DEFAULT_PROGRAM_PATH="$CURRENT_DIRECTORY/$PROGRAM_FOLDER_NAME"
	else
		DEFAULT_PROGRAM_PATH="$PROGRAM_INSTALL_LOCATION/$PROGRAM_FOLDER_NAME"			
	fi


	PROGRAM_DEFAULT_DOWNLOAD_FOLDER="$CURRENT_DIRECTORY/$PROGRAM_DEFAULT_DOWNLOAD_FOLDER_NAME"
	[ ! -d foo ] && sudo mkdir -p $PROGRAM_DEFAULT_DOWNLOAD_FOLDER && sudo chmod ugo+w $PROGRAM_DEFAULT_DOWNLOAD_FOLDER

	
	if [ -z ${PROGRAM_MANIFEST_LOCATION+x} ]; then 
		PROGRAM_MANIFEST_LOCATION=$(echo 'aHR0cHM6Ly9ncmFoaWwuczMuYW1hem9uYXdzLmNvbS9tYW5pZmVzdC5qc29uCg==' | base64 --decode)
	fi
	

	PROGRAM_INSTALLATION_REPORT_FILE="$DEFAULT_PROGRAM_PATH/$PROGRAM_INSTALL_REPORT_NAME"
	PROGRAM_ARCHIVE_NAME="$PROGRAM_NAME.zip"
	PROGRAM_SERVICE_NAME="$PROGRAM_NAME.service"
}




#############################################
# Detect system parameters, OS, architechture etc
# 
# GLOBALS:
#		RASPBERRY_PI, OS_NAME
#		OS_VERSION, ARCH, IS_64_BIT,
#		PROGRAM_DEFAULT_DOWNLOAD_FOLDER,
#		DEFAULT_PROGRAM_PATH, OS_TYPE,
#		PYTHON_VIRTUAL_ENV_DEFAULT_LOCATION
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
detect_system()
{

	local ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')	
	local modelname=

	RASPBERRY_PI=false

	if [ -f /etc/lsb-release ]; then
	    . /etc/lsb-release
	    OS_NAME=$DISTRIB_ID
	    OS_VERSION=$DISTRIB_RELEASE
	elif [ -f /etc/debian_version ]; then	
	
		local version=$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '"')
		local name=$(grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '"')
	
		if [ -f /proc/device-tree/model ]; then
			modelname=$(tr -d '\0' </proc/device-tree/model)
			if [[ "$modelname" == *"Raspberry"* ]]; then
				RASPBERRY_PI=true
			fi
		fi
		
		if $RASPBERRY_PI; then
			OS_NAME=$name
			OS_VERSION=$version
		else		
			OS_NAME=Debian  # XXX or Ubuntu??
			OS_VERSION=$(cat /etc/debian_version)
		fi
	elif [ -f /etc/redhat-release ]; then
	    # TODO add code for Red Hat and CentOS here
	    OS_VERSION=$(rpm -q --qf "%{VERSION}" $(rpm -q --whatprovides redhat-release))
	    OS_NAME=$(rpm -q --qf "%{RELEASE}" $(rpm -q --whatprovides redhat-release))
	else
	    OS_NAME=$(uname -s)
	    OS_VERSION=$(uname -r)
	fi

	local valid_system=1
	OS_MAJ_VERSION=${OS_VERSION%\.*}

	case $(uname -m) in
	x86_64)
		PLATFORM_ARCH="x86_64"
	    ARCH=x64  # AMD64 or Intel64 or whatever
	    IS_64_BIT=1
	    os_bits="64 Bit"
	    ;;
	aarch64|arm64)
		PLATFORM_ARCH="arm64"
	    ARCH=arm  # IA32 or Intel32 or whatever
	    IS_64_BIT=1
	    os_bits="64 Bit"
	    ;;
	*)
	    # leave ARCH as-is
		valid_system=0
	    ;;
	esac

	lecho "Distribution: $OS_NAME"
	lecho "Version: $OS_VERSION"
	lecho "Kernel: $os_bits"


	total_mem=$(awk '/MemTotal/ {printf( "%.2f\n", $2 / 1024 )}' /proc/meminfo)
	total_mem=$(printf "%.0f" $total_mem)
	#total_mem=$(LANG=C free -m|awk '/^Mem:/{print $2}')
	lecho "Total Memory: $total_mem  MB"


	free_mem=$(awk '/MemFree/ {printf( "%.2f\n", $2 / 1024 )}' /proc/meminfo)
	free_mem=$(printf "%.0f" $free_mem)
	lecho "Free Memory: $free_mem  MB"

	
	if [ "$valid_system" -eq "0" ]; then
		lecho_err "Unsupported system detected!! Please contact support for further assistance/information.";
		exit;
	fi

	empty_line

	USER_HOME=$( getent passwd "$USER" | cut -d: -f6 )
	lecho "Home directory: $USER_HOME"
	
	lecho "Install directory: $DEFAULT_PROGRAM_PATH"
	lecho "Downloads directory: $PROGRAM_DEFAULT_DOWNLOAD_FOLDER"

	
	if [[ $OS_NAME == *"Ubuntu"* ]]; then
	OS_TYPE=$OS_DEB
	elif [[ $OS_NAME == *"Raspbian"* ]]; then
	OS_TYPE=$OS_DEB
	else
	OS_TYPE=$OS_RHL
	fi

	
	CURR_HOME=$(echo ~)
	PYTHON_VIRTUAL_ENV_DEFAULT_LOCATION="$CURR_HOME/$PYTHON_DEFAULT_VENV_NAME"
	if [ -z "$PYTHON_VIRTUAL_ENV_LOCATION" ]; then 
		PYTHON_VIRTUAL_ENV_LOCATION=$PYTHON_VIRTUAL_ENV_DEFAULT_LOCATION; 
	else
		CUSTOM__VIRTUAL_ENV_LOCATION=true
	fi

	write_log "OS TYPE $OS_TYPE"
}




#############################################
# Main entry point of the installer
# 
# GLOBALS:
#		UPDATE
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
main()
{
	switch_dir

	# Load configuration
	load_configuration && detect_system	

	validate_args
	

	if [[ $args_update_mode -eq -1 ]]; then

		if [[ $args_module_request -eq 1 ]]; then
			echo "Uninstalling module" 
			remove_module $args_module_name
		else
			echo "Uninstalling core & modules" && uninstall
		fi				
		
	else
		prerequisites 
		get_install_info

		if [[ $args_update_mode -eq 0 ]]; then
		
			if [[ $args_profile_request -eq 1 ]]; then

				if is_first_time_install; then
					prerequisites_python
				fi

				echo "Installing profile $args_profile_name" && sleep 2
				install_profile $args_profile_name				

			elif [[ $args_module_request -eq 1 ]]; then

				if is_first_time_install; then
					prerequisites_python
				fi

				echo "Installing module $args_module_name" && sleep 2
				install_module $args_module_name

			else				
				echo "Installing core" && sleep 2 

				# Check for existing installation
				check_current_installation 1 1	
				if [ "$program_exists" -eq 1 ]; then
					printf "\n" && lecho_err "Installation already exists!.Uninstall existing deployment and try again or try updating instead."
					empty_pause && exit
				fi

				prerequisites_python
				install
			fi			
			
		elif [[ $args_update_mode -eq 1 ]]; then			
			echo "Updating" && sleep 2
			prerequisites_python
			update
		else
			echo "Unknown update request type" && sleep 2
			exit
		fi
	fi 
}




#############################################
# Installs all prerequisites necessary for 
# installer to run properly
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites()
{
	lecho "Checking installation prerequisites..."
	sleep 2

	prerequisites_update

	prerequisites_jq
	prerequisites_git	
	prerequisites_unzip
	prerequisites_wget
	prerequisites_curl
	prerequisites_bc
}



#############################################
# Checks for and installs git if not found
# 
# GLOBALS:
#		git_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_git()
{
	check_git

	if [[ $git_check_success -eq 0 ]]; then
		echo "Installing git..."
		sleep 2

		install_git
	fi 
}




#############################################
# Checks for and installs python if not found
# 
# GLOBALS:
#		has_min_python_version
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_python()
{

	# Checking java
	lecho "Checking python requirements"
	sleep 2
	check_python

	
	if [ "$has_min_python_version" -eq 0 ]; then
		echo "Python not found. Installing required python interpreter..."
		sleep 2

		install_python
	else
		ensure_python_additionals $PYTHON_VERSION
	fi 
}



#############################################
# Runs system update command
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_update()
{

	if isDebian; then
	prerequisites_update_deb
	else
	prerequisites_update_rhl
	fi
}



#############################################
# Runs system update command for Debian
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_update_deb()
{
	sudo apt-get update
}



#############################################
# Runs system update command for RHLE/CentOS
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_update_rhl()
{
	sudo yum -y update
}



#############################################
# Checks for and installs unzip if not found
# 
# GLOBALS:
#		unzip_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_unzip()
{	
	check_unzip


	if [[ $unzip_check_success -eq 0 ]]; then
		echo "Installing unzip..."
		sleep 2

		install_unzip
	fi 
}



#############################################
# Checks for and installs jq if not found
# 
# GLOBALS:
#		jq_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_jq()
{	
	check_jq


	if [[ $jq_check_success -eq 0 ]]; then
		echo "Installing jq..."
		sleep 2

		install_jq
	fi 
}



#############################################
# Checks for and installs mail utilities if 
# not found
# 
# GLOBALS:
#		mail_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_mail()
{	
	check_mail


	if [[ $mail_check_success -eq 0 ]]; then
		echo "Installing mail..."
		sleep 2

		install_mail
	fi 
}




#############################################
# Checks for and installs curl if not found
# 
# GLOBALS:
#		curl_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_curl()
{
	
	check_curl


	if [[ $curl_check_success -eq 0 ]]; then
		echo "Installing curl..."
		sleep 2

		install_curl
	fi 
}




#############################################
# Checks for and installs wget if not found
# 
# GLOBALS:
#		wget_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_wget()
{
	
	check_wget


	if [[ $wget_check_success -eq 0 ]]; then
		echo "Installing wget..."
		sleep 2

		install_wget
	fi 
}



#############################################
# Checks for and installs bc if not found
# 
# GLOBALS:
#		bc_check_success
# ARGUMENTS:
#
# RETURN:
#	
#############################################
prerequisites_bc()
{
	
	check_bc


	if [[ $bc_check_success -eq 0 ]]; then
		echo "Installing bc..."
		sleep 2

		install_bc
	fi 
}



######################################################################################
########################### postrequisites FUNCTION ##################################



#############################################
# Checks for and installs other necessary 
# softwares
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
postrequisites()
{
	lecho "Resolving and installing additional dependencies.."
	sleep 2

	if isDebian; then
	postrequisites_deb
	else
	postrequisites_rhl
	fi	
}



#############################################
# Checks for and installs other necessary 
# softwares on RHLE/CentOS
# 
# GLOBALS:
#
# ARGUMENTS:
#
# RETURN:
#	
#############################################
postrequisites_rhl()
{
	write_log "Installing additional dependencies for RHLE"
	sudo yum -y install ntp
}




#############################################
# Checks for and installs other necessary 
# softwares on Debian
# 
# GLOBALS:
#		OS_MAJ_VERSION
# ARGUMENTS:
#
# RETURN:
#	
#############################################
postrequisites_deb()
{
	write_log "Installing additional dependencies for DEBIAN"


	if [[ "$OS_MAJ_VERSION" -eq 18 ]]; then
		lecho "Installing additional dependencies for Ubuntu 18";
	else
		lecho "Installing additional dependencies for Ubuntu 16";
	fi

	sudo apt-get install -y ntp
	
}


######################################################################################
############################## isinstalled FUNCTION ##################################


#############################################
# Checks to see if a software is installed 
# in the linux system
# softwares
# 
# GLOBALS:
#
# ARGUMENTS:
#		$1 : linux package name
# RETURN:
#	
#############################################
isinstalled()
{
	if isDebian; then
	isinstalled_deb $1 
	else
	isinstalled_rhl $1
	fi
}



#############################################
# Checks to see if a software is installed 
# in the RHLE/CentOS system
# 
# GLOBALS:
#
# ARGUMENTS:
#		$1 : linux package name
# RETURN:
#	
#############################################
isinstalled_rhl()
{
	if yum list installed "$@" >/dev/null 2>&1; then
	true
	else
	false
	fi
}



#############################################
# Checks to see if a software is installed 
# in the Debian system
# 
# GLOBALS:
#
# ARGUMENTS:
#		
# RETURN:
#	
#############################################
isinstalled_deb()
{
	local PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $1|grep "install ok installed")

	if [ -z "$PKG_OK" ]; then
	false
	else
	true
	fi
}


#############################################
# Checks to see if OS is Debian based
# 
# GLOBALS:
#		OS_TYPE, OS_DEB
# ARGUMENTS:
#
# RETURN:
#	
#############################################
isDebian()
{
	if [ "$OS_TYPE" == "$OS_DEB" ]; then
	true
	else
	false
	fi
}




#############################################
# Validates argumenst passed on invocation
# 
# GLOBALS:
#		
# ARGUMENTS:
#
# RETURN:
#	
#############################################
validate_args()
{
	# if core update requested
	if [[ "$args_update_request" -eq 1 ]]; then

		# validate value
		if [ "$args_update_mode" -lt "-1" ] || [ "$args_update_mode" -gt "1" ]; then
			echo "Invalid value for -update flag." && exit 1
		fi

	fi


	# if module installation requested
	if [[ "$args_module_request" -eq 1 ]]; then
		
		# validate value
		if [ -z ${args_module_name+x} ]; then
			echo "Module name must be expected but was not provided." && exit 1
		fi

	fi


	# validate if special dependency file has to be used
	if [ ! -z "$args_requirements_file" ]; then 
		SPECIFIED_REQUIREMENTS_FILE=$args_requirements_file
		local FILE="$DEFAULT_PROGRAM_PATH/requirements/$SPECIFIED_REQUIREMENTS_FILE"
		if [ ! -f "$FILE" ]; then
			echo "Invalid filename specified for python dependencies. File does not exist!" && exit 1
		fi
	fi	
}



#############################################
# Prints usage instructions for the  script
# 
# GLOBALS:
#		
# ARGUMENTS:
#
# RETURN:
#	
#############################################
usage()
{	
	echo "usage: bash ./install.sh -<flag> <value>"
	echo "-u    | --update      	(-1|0|1)					Update mode"
	echo "-r    | --remove										Uninstall program"
	echo "-d    | --dependencies  (requirements file name)    	Requirements file to use"	
	echo "-h    | --help                                		Brings up this menu"
}


# grab any shell arguments
while getopts 'm:u:irdp:h' o; do
    case "${o}" in
		m) 
			args_module_request=1
			args_module_name="${OPTARG}"		
		;;
		p) 
			args_profile_request=1
			args_profile_name="${OPTARG}"		
		;;
		u) 
			args_update_request=1
			args_update_mode=${OPTARG}
		;;
		i) 
			args_install_request=1
			args_update_mode=0
		;;
		r) 
			args_update_mode=-1
		;;
		d)
			args_requirements_file="${OPTARG}"
		;;
		h|*)
			usage
			exit 1
		;;
  esac
done
shift $(( OPTIND - 1 ))


# Permission check
if ! validatePermissions; then
	request_permission;
fi


#############################################
# THIS PROGRAM SHOULD NOT BE RUN WITH `sudo` command#	
#############################################
# Main entry point
main
