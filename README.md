# Tweeter

Tweeter is a sample service that demonstrates how easy it is to run a Twitter-like service on DC/OS.

Capabilities:

* Stores tweets in Cassandra
* Streams tweets to Kafka as they come in
* Real time tweet analytics with Spark and Zeppelin


## Install and Configure Prerequisites on the Cluster

You'll need a DC/OS cluster with one public node and at least five private nodes, DC/OS CLI, and DC/OS package CLIs.

Run `bash stage_ebc_demo.sh [master_ip] [ELB_Hostname]`

The above command will do the following:

* Update your Python Env to work with the latest CLI
* Install a local CLI at ./dcos
* Configure the local CLI
* Install Marathon-LB, Kafka, Cassandra, and the 'Tweeter' app
* Output the commands to run to connect to Tweeter, Start posting Tweets, and Connecting to Zeppelin

## Demo steps

See "EBC Demo - Tweeter" doc on Google drive for more details and a demonstration video, but the technical steps are as follows:

* Install Zeppelin from the GUI using the default values
* Log into the Tweeter UI at http://[elb_hostname] and post a sample tweet
* Start the tweeter load job from the CLI using the command `dcos/bin/dcos marathon app add post-tweets.json`
* Kill one of the Tweeter containers in Marathon and show that the Tweeter is still up and tweets are still flowing in
* Log into Zeppelin using the https interface at https://[master_ip]/service/zeppelin
* Click `Import note` and import `tweeter-analytics.json` from the Tweeter repo clone you made locally
* Open the newly loaded "Tweeter Analytics" Notebook
* Run the *Load Dependencies* step to load the required libraries into Zeppelin
* Run the *Spark Streaming* step, which reads the tweet stream from Zookeeper, and puts them into a temporary table that can be queried using SparkSQL - this spins up the Zeppelin spark context so you can show them the increased utilization on the dashboard 
* Next, run the *Top Tweeters* SQL query, which counts the number of tweets per user, using the table created in the previous step
* The table updates continuously as new tweets come in, so re-running the query will produce a different result every time
