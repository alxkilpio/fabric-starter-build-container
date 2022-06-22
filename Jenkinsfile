import com.cloudbees.plugins.credentials.impl.*;
import com.cloudbees.plugins.credentials.*;
import com.cloudbees.plugins.credentials.domains.*;
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

CRED = '\033[1;31m'
CGREEN = '\033[1;32m'
CYELLOW = '\033[1;33m'
CBLUE = '\033[1;34m'
CMAGENTA = '\033[1;35m'
CCYAN = '\033[1;36m'
CWHITE = '\033[1;37m'
CFRAMED = '\033[51m'
CNOTFRAMED = '\033[54m'
CUNDERLINED = '\033[4m'
CNOTUNDERLINED = '\033[24m'
CNORMAL = '\033[0m'

DEBUG = true

node {
    properties([
                //https://docs.openstack.org/infra/jenkins-job-builder/parameters.html
                parameters([
                        credentials(name: "BUILDER_CONTAINER_SSH_CREDENTIALS_ID", description: "Builder Container ssh username with private key", defaultValue: '', credentialType: "com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey", required: true),
                ])
        ])

    printErrToStdout = '2>&1'
    printErrToDevNull = '2>/dev/null'
    DBG_STDOUTPUT = (DEBUG == 'true') ? printErrToStdout : printErrToDevNull

    ansiColor('xterm') {

        reportList = ["\n${CMAGENTA}======== MAIN OPERATIONS OF THE PIPELINE ========${CNORMAL}\n"]

        stage('Key-Gen') {

            sh "rm ./id_rsa"
            sh "rm ./id_rsa.pub"
            sh "ssh-keygen -t rsa -b 4096 -C 'JenkinsController' -f ./id_rsa -P ''"

        }

        wrappedStage('Remove-Prev-Credentials',CMAGENTA,'Remove old FSBuilderContainerKey credentials') {

            def credentialsStore = jenkins.model.Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
            allCreds = credentialsStore.getCredentials(Domain.global())

            id_name ='FSBuilderContainerKey'

            allCreds.each{
              if (it.id == id_name){
                echodbg ("Remove ID: ${id_name} ")
                credentialsStore.removeCredentials(Domain.global(), it)
              }
            }
        }

        wrappedStage('Create-Credentials',CGREEN, "Add new FSBuilderContainerKey credentials ") {
            sh "ls -la"

            def pk = readFile ("./id_rsa")
            println (pk)

            def ok = readFile ("./id_rsa.pub")
            println (ok)

            def source = new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(pk)
            def ck1 = new BasicSSHUserPrivateKey(CredentialsScope.GLOBAL,"FSBuilderContainerKey", "gradle", source, "", "FSBuilderContainerKey")

            SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), ck1)
        }

        wrappedStage('Check SSH connection',CBLUE, "Check ssh key") {
            sshagent(credentials: ['${BUILDER_CONTAINER_SSH_CREDENTIALS_ID}']) {
                    //sh "GIT_SSH_COMMAND='ssh -vvvvv' git clone git@github.com:${GIT_USER}/${repositoryName}.git"
                    sh "ssh gradle@fabric_starter_builder_container hostname"
                }
            }
    }
}

def echodbg(message) {
    if (DEBUG == 'true') {
        echo message
    }
}


def wrappedStage(name, def color = CNORMAL, def description = null, def currentDir = ".", Closure closure) {
    stage(name) {
        dir(currentDir) {
            echo color
            echodbg("======================================= START ${name} ===========================================================")
            if (fileExists('./.gitignore') == 'true') {
                shdbg("git branch || true")
            }
            echo "${CFRAMED}${STAGE_NAME}${CNOTFRAMED}"
            reportList.add("STAGE: ${STAGE_NAME}")

            try {
                result = closure.call()
            } catch (e) {
                echo "${CRED}${CUNDERLINED}"
                currentBuild.description = e.getMessage()
                echo "----------------------------FAILURE--------------------------------------"
                echo "ERROR: " + e.getMessage() + " in ${STAGE_NAME} stage."
                currentBuild.result = 'FAILURE'
                throw e
            }
            echodbg("======================================= FINISH ${name} ===========================================================")
            echo CNORMAL
            return result
        }
    }
}
