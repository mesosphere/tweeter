# Tweeter

Tweeter is a sample app that demonstrates how easy it is to run a Twitter-like app on DCOS.

Capabilities:

* stores tweets in Cassandra
* streams tweets to Kafka as they come in
* real time tweet analytics on via Spark and Zeppelin

## Configure Your Machine

You'll need Ruby and a couple of libraries on your local machine to hack on this
app, and to send tweets to it.

### Homebrew on Mac OS X

Using Homebrew, install `rbenv`, a Ruby version manager:

    brew update
    brew install rbenv

Run this command and follow the instructions to setup your environment:

    rbenv init

To install the required Ruby version for Tweeter, run from inside this repo:

    rbenv install

Then install the Ruby package manager and Tweeter's dependencies. From this repo run:

    gem install bundler
    bundle install

## Install and Configure Prerequisites on the Cluster

You'll need a DCOS cluster with one public node and at least five private nodes.

Add the Multiverse as a package source:

    dcos package repo add multiverse https://github.com/mesosphere/multiverse/archive/version-2.x.zip

Install packages:

    dcos package install --yes marathon-lb
    dcos package install --yes cassandra
    dcos package install --yes kafka

Wait until the Kafka service shows up in the DCOS UI, then add and start the Kafka brokers:

    dcos kafka broker add 0,1,2
    dcos kafka broker start 0,1,2

Look up the public slave IP in AWS. You need the IP of the EC2 host, not the ELB. Use this to replace `<public_ip>` further down.

## Run the Tweeter App

Launch three instances of Tweeter on Marathon using the config file in this repo:

    dcos marathon app add marathon.json

The app talks to Cassandra via `cassandra-dcos-node.cassandra.dcos.mesos`, and Kafka via `broker-0.kafka.mesos:1025`. If your cluster uses different names for Cassandra or Kafka, edit `marathon.json` first.

Traffic is routed to the app via marathon-lb. Navigate to `http://<public_ip>:10000` to see the Tweeter UI and post a Tweet.

## Post a lot of Tweets

Post a lot of Shakespeare tweets from a file:

    bin/rake shakespeare:tweet shakespeare-data.json http://<public_ip>:10000

This will post more than 100k tweets one by one, so you'll see them coming in steadily when you refresh the page.

## Streaming Analytics

Next, we'll do real-time analytics on the stream of tweets coming in from Kafka.

Install the Zeppelin package:

    dcos package install --yes zeppelin

Add the label `HAPROXY_0_PORT=10003` to the Zeppelin marathon app so that marathon-lb proxies to it on that port.

Navigate to Zeppelin at `http://<public_ip>:10003` and load the Spark Notebook from `spark-notebook.json`. Zeppelin is preconfigured to execute Spark jobs on the DCOS cluster, so there is no further configuration or setup required.

Run the *Load Dependencies* step to load the required libraries into Zeppelin. Next, run the *Spark Streaming* step, which reads the tweet stream from Zookeeper, and puts them into a temporary table that can be queried using SparkSQL. Next, run the *Top Tweeters* SQL query, which counts the number of tweets per user, using the table created in the previous step. The table updates continuously as new tweets come in, so re-running the query will produce a different result every time.
