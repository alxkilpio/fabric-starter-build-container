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
                        stringParam(name: "GIT_URL", defaultValue: "https://github.com/", description: "Git URL"),
                        stringParam(name: "BUILDER_REPOSITORY", defaultValue: "alxkilpio", description: "Name of the git repo to get Builder code"),
                        stringParam(name: "BUILDER_PROJECT", defaultValue: "fabric-starter-build-container", description: "Builder project name"),
                        stringParam(name: "BUILDER_BRANCH", defaultValue: "main", description: "Builder project branch"),
                        booleanParam(name: "SKIP_BUILD", defaultValue: false, description: "True if we do not want to build container image"),
                ])
        ])

    printErrToStdout = '2>&1'
    printErrToDevNull = '2>/dev/null'
    DBG_STDOUTPUT = (DEBUG == 'true') ? printErrToStdout : printErrToDevNull

    ansiColor('xterm') {

        reportList = ["\n${CMAGENTA}======== MAIN OPERATIONS OF THE PIPELINE ========${CNORMAL}\n"]

        wrappedStage('Cleaning-job-workspace', CMAGENTA, "Cleaning job workspace: ${WORKSPACE}") {
            def isWorkspaceNotOK = !(WORKSPACE?.trim())
            if (isWorkspaceNotOK) {
                echo 'Failure: WORKSPACE variable is undefined!'
                currentBuild.result = 'FAILURE'
                return
            } else {
                dir(WORKSPACE) {
                    deleteDir()
                    shdbg 'ls -ld $(find .)'
                }
            }
        }

        wrappedStage('Clone-Repo',CBLUE,'Clone Builder project from git'){
            checkoutFromGithubToSubfolderHTTPS("${BUILDER_PROJECT}","${BUILDER_BRANCH}")
        }

        wrappedStage('Build-Image',CCYAN,'Create Builder container docker image'){
          if (SKIP_BUILD != 'true') {
                dir("${BUILDER_PROJECT}") {
                    sh "./build_fabric-starter-builder_image.sh ${BUILDER_REPOSITORY}"
                }
            }
        }

        wrappedStage('Launch-Container',CGREEN,'Launch Builder container'){
            dir("${BUILDER_PROJECT}") {
                sh "./start-build-container.sh"
            }
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

        wrappedStage('Generate-and-Install-Keys',CBLUE, "Generate SSH keyset and copy public key to the container") {
            dir("${BUILDER_PROJECT}") {
                sh "./genkeys.sh"
            }
        }

        wrappedStage('Create-Credentials',CCYAN, "Add new FSBuilderContainerKey credentials") {
            dir("${BUILDER_PROJECT}") {
                sh "ls -la"

                def pk = readFile ("./keys/id_rsa_builder")
                println (pk)

                def ok = readFile ("./keys/id_rsa_builder.pub")
                println (ok)

                def source = new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(pk)
                def ck1 = new BasicSSHUserPrivateKey(CredentialsScope.GLOBAL,"FSBuilderContainerKey", "gradle", source, "", "FSBuilderContainerKey")

                SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), ck1)
            }
        }

        wrappedStage('Check SSH connection',CGREEN, "Check ssh key") {
            sh "ssh-keygen -f '/var/jenkins_home/.ssh/known_hosts' -R fabric_starter_builder_container"
            dir("${BUILDER_PROJECT}") {
                sh "ssh -o StrictHostKeyChecking=no -i ./keys/id_rsa_builder gradle@fabric_starter_builder_container hostname"
            }
            sshagent(credentials: ['FSBuilderContainerKey']) {
                    sh "hostname"
                }
            }
//
//         wrappedStage('Add github public key',CMAGENTA, "Check ssh key") {
//             sshagent(credentials: ['FSBuilderContainerKey']) {
//                     sh "ssh-keyscan -H github.com >> ~/.ssh/known_hosts"
//                     sh "ls -la ~/.ssh/known_hosts"
//                 }
//             }
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

def checkoutFromGithubToSubfolderHTTPS(repositoryName, def branch = 'master') {
    echo 'If login fails here with right credentials,please add github.com to known hosts for jenkins user (ssh-keyscan -H github.com >> .ssh/known_hosts)'
        sh "git clone ${GIT_URL}${BUILDER_REPOSITORY}/${repositoryName}.git"
        dir(repositoryName) {
            sh "git checkout $branch "
            sh 'git pull'
        }
        reportList.add("checkoutFromGithubToSubfolder: git clone ${GIT_URL}/${BUILDER_REPOSITORY}/${repositoryName}.git; git checkout ${branch}; git pull")
}


def echodbg(message) {
    if (DEBUG == 'true') {
        echo message
    }
}

def setBuildDescription(description) {
    currentBuild.description = description
}

def shdbg(command) {
    if (DEBUG == 'true') {
        sh command
    }
}