# Red Hat Developer CRUD Soak Test
## How to run the automated test
### Start a Jenkins job
* Go to the Jenkins [job](https://fuse-qe-jenkins-rhel7.rhev-ci-vms.eng.rdu2.redhat.com/view/Performance/job/devtools-performance-core-crud-soak/) and hit the [Build with Parameters](https://fuse-qe-jenkins-rhel7.rhev-ci-vms.eng.rdu2.redhat.com/view/Performance/job/devtools-performance-core-crud-soak/build?delay=0sec) button.
* Keep the parameters intact for the duration of 12 hours and to test the Core server locally. 
   * ```SERVER_HOST``` and ```SERVER_PORT``` are the host name or the IP address and a port number of the Core server's REST API, where the requests to perform CRUD operations are sent by the clients.
     If the value is ```localhost``` (the default) a fresh instance of the Core server and a PostgreSQL DB is created and started locally as a Docker containers at the same node so all the traffic is over localhost.
### Create a report
* Go to the [PerfRepo](http://perfrepo.mw.lab.eng.bos.redhat.com) instance and login.
* Go to the [Reports](http://perfrepo.mw.lab.eng.bos.redhat.com/reports/) section and create a new [Metric history](http://perfrepo.mw.lab.eng.bos.redhat.com/reports/metric) report.
   * Name the report: ```Red Hat Developer CRUD: SOAK (<YYYY-MM-DD>)```
   * Set permissions:
      * Click to [Permission setting] to open a permission table
      * Using [+] button on the right-top corner of the table add 2 new permissions to the report one-by-one:
         * Access type: ```READ```, Access Level: ```Public```
         * Access type: ```WRITE```, Access Level: ```Public```
   * Using the [+ Add chart] button create 4 charts:
      * Name: ```CREATE```, Test: ```Red Hat Developer Core: CREATE```
      * Name: ```READ```, Test: ```Red Hat Developer Core: READ```
      * Name: ```UPDATE```, Test: ```Red Hat Developer Core: UPDATE```
      * Name: ```DELETE```, Test: ```Red Hat Developer Core: DELETE```
   * Using [+ Add seiries] button create 4 series:
      * Chart: ```CREATE```, Series name: ```<YYYY-MM-DD> #<build-number>```, Metric: ```throughput```, Tags: ```jenkins=jenkins-<jenkins-job>-<build-number>```
      * Chart: ```READ```, Series name: ```<YYYY-MM-DD> #<build-number>```, Metric: ```throughput```, Tags: ```jenkins=jenkins-<jenkins-job>-<build-number>```
      * Chart: ```UPDATE```, Series name: ```<YYYY-MM-DD> #<build-number>```, Metric: ```throughput```, Tags: ```jenkins=jenkins-<jenkins-job>-<build-number>```
      * Chart: ```DELETE```, Series name: ```<YYYY-MM-DD> #<build-number>```, Metric: ```throughput```, Tags: ```jenkins=jenkins-<jenkins-job>-<build-number>```
   * Using [Save] button, save the report
   * TODO: @ldimaggi insert a link to the bluejeans recording of the report creation
* The report can now be found in the report list under the [Reports](http://perfrepo.mw.lab.eng.bos.redhat.com/reports/) section.

#