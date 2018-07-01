# Makefile for hiveserver2-service-check.py
# Author: Michael DeGuzis <mtdeguzis@geisinger.edu>
# https://udajira:8443/browse/HO-1713
# https://udajira:8443/browse/HO-1806

# https://hortonworks.com/downloads/
SIMBA_DRIVERS = 'https://s3.amazonaws.com/public-repo-1.hortonworks.com/HDP/hive-jdbc4/1.0.42.1054/Simba_HiveJDBC41_1.0.42.1054.zip'
CURRENT_USER = $(shell echo $whoami)

all: build

build: clean
	#rm -rf $(CURDIR)/hivejars && mkdir $(CURDIR)/hivejars
	#cd  $(CURDIR)/hivejars && curl -O $(SIMBA_DRIVERS) && unzip Simba_HiveJDBC*.zip
	mvn package

install: build
	# Specifying sqlline for groupID should place the hivejars folder under .m2/repository/sqlline/hivejars
	# For version on the hive jars, this should be replaced by a var with the Simba download URL... TODO
	@echo "Install Maven project to user .m2 directory"
	mvn install
	@echo "Installing RPM"
	find $(CURDIR) -name "*.rpm" -exec sudo rpm -i {} \;

install-icinga: build
	# Build pipenv environment for python wrapper
	export HOME=/home/icinga && \
	pipenv install
	# Install symlinks
	rm -f /usr/lib64/nagios/plugins/sqlline-service-check
	ln -s $(CURDIR)/bin/sqlline-service-check /usr/local/bin/sqlline-service-check
	ln -s $(CURDIR)/bin/sqlline-service-check /usr/lib64/nagios/plugins/sqlline-service-check
	ln -s $(CURDIR)/bin/sqlline /usr/local/bin/sqlline

clean:
	# If needed, for local .m2 repo
	# rm -rf ~/.m2/repository/{net,de,asm,io,tomcat,javaolution,commons-pool,commons-dbcp,javax,co,ch,org,com,it}
	@echo "Cleaning and purging project files and local repository artifacts..."
	mvn clean
	mvn build-helper:remove-project-artifact
	@-sudo rpm -e sqlline
	# If RPM was inspected/unpacked for testing
	rm -rf usr/

test:
	java -jar target/sqlline-1.4.0-SNAPSHOT-jar-with-dependencies.jar
