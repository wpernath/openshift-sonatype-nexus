# Sonatype Nexus on OpenShift

This repo contains OpenShift templates and scripts for deploying Sonatype Nexus 3 AND IQ Server, 
and pre-configuring Red Hat and JBoss maven repositories on Nexus via post deploy hooks.
You can modify the post hook in the templates and add other Nexus repositories by using these [helper
functions](scripts/nexus-functions).

```yaml
post:
  execNewPod:
    containerName: ${SERVICE_NAME}
    command:
      - "/bin/bash"
      - "-c"
      - "curl -o /tmp/nexus-functions -s https://raw.githubusercontent.com/kenmoini/openshift-sonatype-nexus/master/scripts/nexus-functions; source /tmp/nexus-functions; add_nexus3_redhat_repos admin admin123 http://${SERVICE_NAME}:8081"
```

## Import Templates

In order to add Sonatype Nexus 3 templates to OpenShift service catalog run the following commands:

```bash
$ oc create -f https://raw.githubusercontent.com/kenmoini/openshift-sonatype-nexus/master/nexus3-template.yaml # Nexus 3, Ephemeral storage
$ oc create -f https://raw.githubusercontent.com/kenmoini/openshift-sonatype-nexus/master/nexus3-persistent-template.yaml # Nexus 3, Persistent Storage
$ oc create -f https://raw.githubusercontent.com/kenmoini/openshift-sonatype-nexus/master/nexus3-template-secure.yaml # Nexus 3, Ephemeral storage with Edge Terminated TLS
$ oc create -f https://raw.githubusercontent.com/kenmoini/openshift-sonatype-nexus/master/nexus3-persistent-template-secure.yaml # Nexus 3, Persistent Storage with Edge Terminated TLS
```

## Deploy Nexus 3

Deploy Sonatype Nexus 3 using one of the provided templates. If you have persistent volumes available in your cluster:

```bash
$ oc new-app nexus3-persistent
```

Otherwise:

```bash
$ oc new-app nexus3
```

### Deploy Specific Version
In order to specify the Nexus version to be deployed use ```NEXUS_VERSION``` parameter:

```bash
$ oc new-app nexus3 -p NEXUS_VERSION=3.16.2
```

The last version tested that has worked with the post-deployment configuration script is ***3.16.2***.

## Deploy Sonatype Nexus IQ Server

If you'd like to also deploy Sonatype Nexus IQ Server to handle policies/firewalling/etc then jump into the ***openshift-sonatype-nexus-iq*** repo and check out the instructions and objects there.

# Nexus Repository Configuration

## Installing a License

In order to install a Sonatype Nexus license you can upload it via the Administration > System > Licensing portion of the Settings panel.

***NOTE***: You will need to have launched Nexus via the Persistent template as the container needs to restart to load the license.  An ephemeral container is not able to have a license (at this time, ConfigMaps are being explored).

## LDAP

The whole point of Nexus Repo Manager is to centrally manage components and repositories across your organization so every developer shouldn't have their own Nexus.  The easiest way to deploy Nexus centrally is via LDAP.

### Configure LDAP

1. Log into Nexus as an Admin, click on the ***Settings*** cog button to the left of the Search bar at the top.
2. Use the pane to the left to navigate to ```Administration > Security > LDAP```
3. Click ***Create Connection***
4. Configure the Connection as follows *(assuming Red Hat Identity Management setup for LDAPS)*:
  - **Name**: IDM
  - **Protocol**: LDAPS
  - **Hostname**: idm.example.com
  - **Port**: 636
  - **Use the Nexus truststore:** Check the box, click ***View Certificate***, and then click ***Add certificate to truststore***
  - **Search Base**: dc=example,dc=com
  - **Authentication Method**: Simple Authentication
  - **Username or DN**: CN=Directory Manager
  - **Password**: duh
  - **Connection Rules**: Default is fine
5. Click ***Verify Connection*** and if successful, click **Next**
6. Now set the User and Group configuration as such:
  - **Configuration template**: Generic LDAP Server
  - **Base DN**: CN=accounts
  - **User subtree**: *Checked*
  - **Object class**: inetOrgPerson
  - **User filter**: *(blank)*
  - **User ID attribute**: uid
  - **Real name attribute**: cn
  - **Email attribute**: mail
  - **Password attribute**: *(blank)*
  - **Map LDAP groups as roles**: *Checked*
  - **Group type**: Dynamic Groups
  - **Group member of attribute**: memberOf
7. Click ***Verify user mapping*** to ensure it can enumerate the targeted group of users
8. Click ***Verify login*** and select a random user from LDAP to test
9. Click ***Save***
10. Log out and log in as one of the users from LDAP for a final test.  You should see nothing because the user group has not been mapped to a role yet.

### Configure LDAP Groups <-> Nexus Roles

Once LDAP is configured and tested to work, we need to set the Group from LDAP to be associate with a Role in Nexus.  For conveinence sake, we'll create a new Role with almost all permissions.

1. Log into Nexus as an Admin, click on the ***Settings*** cog button to the left of the Search bar at the top.
2. Use the pane to the left to navigate to ```Administration > Security > Roles```
3. Click ***Create Role > External Role Mapping > LDAP***
4. Configure the Role as follows:
  - **Mapped Role**: ipausers
  - **Role Name**: LDAPUsers
  - **Role Description**: Whatever your heart desires
  - **Privileges, Available**: Click on one, then press ***Ctrl+A*** on your keyboard to select them all, and click add.
  - **Privileges, Given**: Remove the following:
    - nx-all
    - nx-capabilities-all
    - nx-capabilities-create
    - nx-capabilities-delete
    - nx-capabilities-update
    - nx-ldap-all
    - nx-ldap-create
    - nx-ldap-delete
    - nx-ldap-update
    - nx-licensing-all
    - nx-licensing-create
    - nx-licensing-read
    - nx-licensing-uninstall
    - nx-privileges-all
    - nx-privileges-create
    - nx-privileges-delete
    - nx-privileges-update
    - nx-roles-all
    - nx-roles-create
    - nx-roles-delete
    - nx-roles-update
    - nx-settings-all
    - nx-settings-update
    - nx-users-all
    - nx-users-create
    - nx-users-delete
    - nx-users-update
    - nx-userschangepw
5. Click ***Create role***

Now once users login from LDAP they can do almost everything outside of administrative tasks that could affect others in the environment.