FROM jenkins/jenkins:lts

USER root

# Cài công cụ unzip
RUN apt-get update && \
    apt-get install -y unzip && \
    rm -rf /var/lib/apt/lists/*

# Copy file Sonar Scanner vào container
COPY sonar-scanner-cli-5.0.1.3006-linux.zip /tmp/

# Giải nén và di chuyển vào /opt
RUN unzip /tmp/sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt/ && \
    mv /opt/sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
    rm /tmp/sonar-scanner-cli-5.0.1.3006-linux.zip

# Thiết lập biến môi trường
ENV SONAR_SCANNER_HOME=/opt/sonar-scanner
ENV PATH=$SONAR_SCANNER_HOME/bin:$PATH

USER jenkins

