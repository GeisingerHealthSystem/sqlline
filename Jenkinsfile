// sqlline builder
properties([
	parameters([
		string(
			defaultValue: "gdchdpmn07prlx.geisinger.edu",
			description: "Hostname to build on",
			name: 'hostname'
		),
        string(
            defaultValue: "rpm-rhel7-dev",
            description: 'Artifactory repository to push to',
            name: 'repo'
        ),  
        choice(
            // At the moment choices is bugged, as it expects the choice
            // parameters as a newline delimited string instead of an array
            choices: [
                'test',
                'deploy',
                ].join("\n"),
            description: 'test or deploy utility',
            name: 'deploy'
        )
	])
])
node(params.hostname) {
	currentBuild.result = "SUCCESS"
	env.CREDENTIALS_STORE = 'udahadoopops'
    //Define artifactory server
    //Definition by node-id does not seem to be working? 403, Jenkins system config is fine
    env.REPO_NAME = params.repo
    env.ARTIFACTORY_SERVER = 'https://ghsudarepo1rlxv.geisinger.edu/artifactory'
    env.RPM_ROOT = env.WORKSPACE + "/sqlline-repo/target/rpm/sqlline/RPMS"
    env.upload_spec = ""

    // Define upload spec for RPM uploads
    // Does not currently notify you if 0 artifacts were found (BUG?)"
    // "props": "type=rpm"
    echo "Defining upload spec"
    upload_spec = """{
      "files": [
        {
          "pattern": "${RPM_ROOT}/*/*.rpm",
          "target": "$REPO_NAME/sqlline/"
        }
     ]
    }"""
    echo upload_spec

	try {
		stage('Checkout') {
			dir('sqlline-repo') {
				git url: 'https://github.com/GeisingerHealthSystem/sqlline', credentialsId: env.CREDENTIALS_STORE
			}
		}
		stage('Build sqlline') {
			dir('sqlline-repo') {
				sh script: '''
				    HIVE_ENABLED=1 make
				'''
			}
		}
        stage('Upload RPM to Artifactory') {
            echo "Verifying existance of file"
            env.RPMPKG = sh(returnStdout: true, script: "find ${RPM_ROOT} -name *.rpm").trim()
            if(fileExists(env.RPMPKG)) {
                echo "Verified RPM: " + env.RPMPKG
            } else {
                error("RPM File not found! Aborting")
            }
            if (params.deploy == 'deploy') {
                echo "Uploading RPM package to Artifactory"
                server = Artifactory.newServer url: env.ARTIFACTORY_SERVER, credentialsId: 'cdis_sys_prod'
                buildInfo = server.upload spec: upload_spec

                // Publish build info (doesn't work?)
                //artifactory_server.publishBuildInfo buildinfo
            }
        }
		stage('Cleanup') {
			cleanWs()
		}
	}
	catch (err) {
		currentBuild.result = "FAILURE"
		throw err
	}
}
