pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "ci-nginx"
        DOCKER_TAG   = "${BUILD_NUMBER}"
        CONTAINER_NAME = "ci-nginx-test"
        HOST_PORT    = "9889"
        NGINX_URL    = "http://localhost:9889"
	GITHUB_URL   = "https://github.com/miBBB/ci-nginx.git"
    }

    triggers {
        // Триггер: опрос GitHub каждые 2 минуты
        pollSCM('H/2 * * * *')
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: ${GITHUB_URL}
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    // Удаляем старый контейнер, если есть
                    sh "docker rm -f ${CONTAINER_NAME} || true"

                    // Запускаем контейнер с пробросом порта 80→9889
                    sh """
                        docker run -d \
                            --name ${CONTAINER_NAME} \
                            -p ${HOST_PORT}:80 \
                            ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """

                    // Ждём запуска nginx
                    sleep 5
                }
            }
        }

        stage('Test HTTP Status Code') {
            steps {
                script {
                    def statusCode = sh(
                        script: "curl -s -o /dev/null -w '%{http_code}' ${NGINX_URL}",
                        returnStdout: true
                    ).trim()

                    echo "HTTP Status Code: ${statusCode}"

                    if (statusCode != '200') {
                        error("❌ Expected HTTP 200, got ${statusCode}")
                    } else {
                        echo "✅ HTTP status code is 200 — OK"
                    }
                }
            }
        }

        stage('Compare MD5 Checksums') {
            steps {
                script {
                    // MD5 файла в образе
                    def md5Image = sh(
                        script: """
                            docker exec ${CONTAINER_NAME} md5sum /usr/share/nginx/html/index.html | awk '{print \$1}'
                        """,
                        returnStdout: true
                    ).trim()

                    // MD5 файла, отдаваемого nginx по HTTP
                    def md5Http = sh(
                        script: """
                            curl -s ${NGINX_URL} | md5sum | awk '{print \$1}'
                        """,
                        returnStdout: true
                    ).trim()

                    echo "MD5 (inside container): ${md5Image}"
                    echo "MD5 (HTTP response):    ${md5Http}"

                    if (md5Image != md5Http) {
                        error("❌ MD5 mismatch: ${md5Image} != ${md5Http}")
                    } else {
                        echo "✅ MD5 checksums match — OK"
                    }
                }
            }
        }

    }

    post {
        always {
            script {
                // Удаляем контейнер в любом случае
                sh "docker rm -f ${CONTAINER_NAME} || true"
            }
        }

        success {
            echo '🎉 All tests passed!'
        }

        failure {
            script {
                def subject = "🚨 CI FAILED: ${env.JOB_NAME} #${BUILD_NUMBER}"
                def body = """
                    <h2>Сборка <b>#${BUILD_NUMBER}</b> завершилась с ошибкой</h2>
                    <table border="1" cellpadding="8" cellspacing="0">
                        <tr><td><b>Проект</b></td><td>${env.JOB_NAME}</td></tr>
                        <tr><td><b>Номер сборки</b></td><td>#${BUILD_NUMBER}</td></tr>
                        <tr><td><b>Ветка</b></td><td>main</td></tr>
                        <tr><td><b>Статус</b></td><td style="color:red;"><b>FAILURE</b></td></tr>
                        <tr><td><b>Подробнее</b></td>
                            <td><a href="${env.BUILD_URL}">${env.BUILD_URL}</a></td></tr>
                    </table>
                    <p>Проверьте логи сборки по ссылке выше.</p>
                """

                emailext(
                    subject: subject,
                    body: body,
                    mimeType: 'text/html',
                    to: 'vbhjyjd@gmail.com'
                )
            }
        }
    }
}
