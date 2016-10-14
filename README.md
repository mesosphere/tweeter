# Tweeter

Tweeter is a sample service that demonstrates how easy it is to run a Twitter-like service on DCOS.

Capabilities:

* Stores tweets in Cassandra
* Streams tweets to Kafka as they come in
* Real time tweet analytics with Spark and Zeppelin


## Install and Configure Prerequisites on the Cluster

Install the Azure tools but be sure to use a version <= 1.10

```
sudo npm install -g azure-cli@0.10.0

azure --version
0.10.0 (node: 4.2.4)
- or -
0.10.0 (node: 5.10.1)
```

*Note: The version of node (4.x/5.x) doesn't appear to affect the behavior of the Azure CLI

```
azure config mode arm
```

```

Setup the Azure storage account and capture connection string

```
	azure group create <resource_group>-static <location>

	azure storage account create --type LRS --resource-group <resource_group>-static --location <location> <account_name>

	azure storage account connectionstring show <account_name>

    export AZURE_STORAGE_CONNECTION_STRING=<connection_string>

	azure storage container create 1dot8

    azure storage blob upload dcos_generate_config.ee.sh 1dot8 dcos_generate_config.ee.sh
```

Setup the Azure Cluster using the repo ARM template for 1.7.x

```
azure group delete <name>-demo

azure group create <name>-demo westus

azure group deployment create --template-file ee.tweeter.azuredeploy.json <name>-demo
```


You'll need a DCOS cluster with one public node and at least five private nodes, DCOS CLI, and DCOS package CLIs.

Install package CLIs:

```
$ dcos package install cassandra --cli
$ dcos package install kafka --cli
```

## Demo steps

Install packages for DCOS UI:
* kafka
* cassandra
* zeppelin
* marathon-lb

Wait until the Kafka and Cassandra services are healthly. You can check their status with:

```
$ dcos kafka connection
...
$ dcos cassandra connection
...
```

## Edit the Tweeter Service Config

Edit the `HAPROXY_0_VHOST` label in `tweeter.json` to match your public ELB hostname. Be sure to remove the leading `http://` and the trailing `/` For example:

```json
{
  "labels": {
    "HAPROXY_0_VHOST": "brenden-7-publicsl-1dnroe89snjkq-221614774.us-west-2.elb.amazonaws.com"
  }
}
```

## Run the Tweeter Service

Launch three instances of Tweeter on Marathon using the config file in this repo:

```
$ dcos marathon app add tweeter.json
```

The service talks to Cassandra via `node-0.cassandra.mesos:9042`, and Kafka via `broker-0.kafka.mesos:9557` in this example.

Traffic is routed to the service via marathon-lb. Navigate to `http://<public_elb>` to see the Tweeter UI and post a Tweet.


## Post a lot of Tweets

Post a lot of Shakespeare tweets from a file:

``` 
dcos marathon app add post-tweets.json
```

This will post more than 100k tweets one by one, so you'll see them coming in steadily when you refresh the page. Take a look at the Networking page on the UI to see the load balancing in action.


## Streaming Analytics

Next, we'll do real-time analytics on the stream of tweets coming in from Kafka.

Navigate to Zeppelin at `https://<master_public_ip>/service/zeppelin/`, click `Import note` and import `tweeter-analytics.json`. Zeppelin is preconfigured to execute Spark jobs on the DCOS cluster, so there is no further configuration or setup required.

Run the *Load Dependencies* step to load the required libraries into Zeppelin. Next, run the *Spark Streaming* step, which reads the tweet stream from Zookeeper, and puts them into a temporary table that can be queried using SparkSQL. Next, run the *Top Tweeters* SQL query, which counts the number of tweets per user, using the table created in the previous step. The table updates continuously as new tweets come in, so re-running the query will produce a different result every time.


NOTE: if /service/zeppelin is showing as Disconnected (and hence can’t load the notebook), make sure you're using HTTPS instead of HTTP, until [this PR](https://github.com/dcos/dcos/pull/27) gets merged. Alternatively, you can use marathon-lb. To do this, add the following labels to the Zeppelin service and restart:


`HAPROXY_0_VHOST = [elb hostname]`

`HAPROXY_GROUP = external`

You can get the ELB hostname from the CCM “Public Server” link.  Once Zeppelin restarts, this should allow you to use that link to reach the Zeppelin GUI in “connected” mode.



## Developing Tweeter

You'll need Ruby and a couple of libraries on your local machine to hack on this service. If you just want to run the demo, you don't need this.

### Homebrew on Mac OS X

Using Homebrew, install `rbenv`, a Ruby version manager:

```bash
$ brew update
$ brew install rbenv
```

Run this command and follow the instructions to setup your environment:

```bash
$ rbenv init
```

To install the required Ruby version for Tweeter, run from inside this repo:

```bash
$ rbenv install
```

Then install the Ruby package manager and Tweeter's dependencies. From this repo run:

```bash
$ gem install bundler
$ bundle install
```
