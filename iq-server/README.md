# Sonatype IQ Server on OpenShift

This is actually not too bad to deploy - a bit more manual than the Nexus deployment, but still not hard.

1. Have Sonatype Nexus deployed already in your namespace/project
2. Modify the config.yaml file to suit your needs, keeping the /sonatype-work and license paths the same (unless you update the respective parts in the shell script and OpenShift Template)
3. Import your license file (rename to iq-server-license.lic) to this directory
4. Switch to your CI/CD namespace or where you have Nexus/want IQ
5. Create a ConfigMap from the config.yaml file:
  ```
  $ oc create configmap --from-file=config.yml iq-server-config
  ```
6. Create a Secret from the license file:
  ```
  $ oc create secret generic iq-server-license --from-file=iq-server-license.lic
  ```
7. Deploy IQ Server
  ```
  $ oc create -f iq-server.yml   #Ephermial
  $ oc create -f iq-server-persistent.yml   # Persistent Data Volume backed
  ```
8. ??????
9. PROFIT!!!!1
