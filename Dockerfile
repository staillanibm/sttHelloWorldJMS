FROM cp.icr.io/cp/webmethods/integration/ibm-webmethods-integration-microservicesruntime:11.1.0.9

ADD --chown=1724:0 . /opt/softwareag/IntegrationServer/packages/sttHelloWorldJMS

ADD --chown=1724:0 tibcoems/lib/jms-2.0.jar /opt/softwareag/IntegrationServer/lib/jars/custom/jms-2.0.jar
ADD --chown=1724:0 tibcoems/lib/tibemsd_sec.jar /opt/softwareag/IntegrationServer/lib/jars/custom/tibemsd_sec.jar
ADD --chown=1724:0 tibcoems/lib/tibjms.jar /opt/softwareag/IntegrationServer/lib/jars/custom/tibjms.jar
ADD --chown=1724:0 tibcoems/lib/tibjmsadmin.jar /opt/softwareag/IntegrationServer/lib/jars/custom/tibjmsadmin.jar
ADD --chown=1724:0 tibcoems/lib/tibjmsapps.jar /opt/softwareag/IntegrationServer/lib/jars/custom/tibjmsapps.jar
ADD --chown=1724:0 tibcoems/lib/tibrvjms.jar /opt/softwareag/IntegrationServer/lib/jars/custom/tibrvjms.jar
# Cryptography dependency missing here (not available in Tibco EMS community edition)
# ADD --chown=1724:0 tibcoems/lib/tibcrypt.jar /opt/softwareag/IntegrationServer/lib/jars/custom/tibcrypt.jar
