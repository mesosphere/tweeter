package com.test

/**
 * Created by abhay on 4/27/15.
 */
import com.datastax.spark.connector._
import org.apache.spark.{SparkContext, SparkConf}
import org.apache.spark.SparkContext._

object SparkCassandraTest {
  def main(args: Array[String]) {
    val conf = new SparkConf(true).set("spark.cassandra.connection.host", args.headOption.getOrElse("localhost"))
    val sc = new SparkContext("local", "Oinker Analytics", conf)
    val rdd = sc.cassandraTable("oinker", "oinks")
    val words = rdd flatMap {_.getString("content").replaceAll("[.?!,:'\"]","").split(" ")}
    val freqs = words.map(w => (w, 1)).reduceByKey(_ + _)
    freqs.saveToCassandra("oinker", "analytics", SomeColumns("key", "frequency"))
  }
}
