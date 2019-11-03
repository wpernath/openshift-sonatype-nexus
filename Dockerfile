FROM sonatype/nexus3:3.16.2

USER root

RUN yum install ca-certificates -y

USER nexus