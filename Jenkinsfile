// sqlline builder
properties([
	parameters([
		string(
			defaultValue: "gdchdpmn07prlx.geisinger.edu",
			description: "Hostname to build on",
			name: 'hostname'
		)
	])
])
node(params.hostname) {
	currentBuild.result = "SUCCESS"
	env.CREDENTIALS_STORE = 'udahadoopops'
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
		stage('Cleanup') {
			cleanWs()
		}
	}
	catch (err) {
		currentBuild.result = "FAILURE"
		throw err
	}
}
