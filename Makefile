# Makefile for hiveserver2-service-check.py
# Author: Michael DeGuzis <mtdeguzis@geisinger.edu>
# https://udajira:8443/browse/HO-1713
# https://udajira:8443/browse/HO-1806
#
# NOTE: For Hive functionality, you will need the Simba Hive JDBC drivers
# This can be installed/built from the rpm GitHub repo -> simba-hive-jdbc
# If you need RPM deps: https://www.mojohaus.org/rpm-maven-plugin/adv-params.html#Dependency
# REQUIRES: maven > 3.2.1

CURRENT_USER = $(shell echo $whoami)
# Now packaged as simba-hive-jdbc in Artifactory
#SIMBA_DRIVERS = "https://public-repo-1.hortonworks.com/HDP/hive-jdbc4/2.6.2.1002/SimbaHiveJDBC41-2.6.2.1002.zip"
SQLLINE_VER = $(shell mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
MAVEN_DL = "http://mirrors.advancedhosters.com/apache/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz"
MVN_BINARY = "$(CURDIR)/maven/bin/mvn"

# Toggle hive driver support
HIVE_ENABLED ?= 0

all: build

configure:
	# Update for install dir
	@cp -v $(CURDIR)/bin/sqlline.template $(CURDIR)/bin/sqlline
	@cp -v $(CURDIR)/bin/sqlline.test.template $(CURDIR)/bin/sqlline.test
	@sed -i "s|@INSTALL_DIR@|/usr/lib/sqlline|g" $(CURDIR)/bin/sqlline
	@#@sed -i "s|@SQLLINE_VER@|$(SQLLINE_VER)|g" $(CURDIR)/bin/sqlline
	@if [[ $(HIVE_ENABLED) -eq 1 ]]; then \
		sed -i 's|#export CLASSPATH=@EXTERNAL_LIBS.*|export CLASSPATH=/usr/lib/simba-hive-jdbc/*:$$CLASSPATH|' $(CURDIR)/bin/sqlline; \
		sed -i 's|#export CLASSPATH=@EXTERNAL_LIBS.*|export CLASSPATH=/usr/lib/simba-hive-jdbc/*:$$CLASSPATH|' $(CURDIR)/bin/sqlline.test; \
	fi

build: configure clean
	# download required maven version
	@if [[ ! -f $(MVN_BINARY) ]]; then \
		rm -rf maven; \
		mkdir maven; \
		cd maven; \
		curl -O $(MAVEN_DL); \
		tar -xzf apache-maven*.tar.gz --strip-components=1; \
	fi
	# Package
	$(MVN_BINARY) -version
	$(MVN_BINARY) package
	@echo "To perform a quick test locally, issue: bin/sqlline.test"
	@echo "Binary written to bin/sqlline"
	@echo "RPM build result: "
	@find $(CURIDR) -name "*.rpm"

install-icinga:
	# Install symlinks
	rm -f /usr/lib64/nagios/plugins/sqlline-service-check
	ln -sf $(CURDIR)/bin/sqlline-service-check.py /usr/local/bin/sqlline-service-check
	ln -sf $(CURDIR)/bin/sqlline-service-check.py /usr/lib64/nagios/plugins/sqlline-service-check

clean:
	# If needed, for local .m2 repo
	# rm -rf ~/.m2/repository/{net,de,asm,io,tomcat,javaolution,commons-pool,commons-dbcp,javax,co,ch,org,com,it}
	@echo "Cleaning and purging project files and local repository artifacts..."
	@mvn clean
	@mvn build-helper:remove-project-artifact
	@rm -rf ./usr

verify:
	@# verify project version via mvn
	$(info SQLLINE_VER is [${SQLLINE_VER}])
