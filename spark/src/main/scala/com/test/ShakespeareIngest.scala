package com.test

import com.datastax.spark.connector._
import org.apache.spark.sql.SQLContext
import org.apache.spark.{SparkContext, SparkConf}
import java.util.{Calendar, UUID, Date}
import scala.collection.immutable.HashSet

case class Oink(kind: String, id: String, content: String, created_at: UUID, handle: String)

object ShakespeareIngest {
  //weird date hack for cassandra
  def uuidForDate(d: Date): UUID = {
    val NUM_100NS_INTERVALS_SINCE_UUID_EPOCH: Long = 0x01b21dd213814000L
    val origTime = d.getTime
    val time = origTime * 10000 + NUM_100NS_INTERVALS_SINCE_UUID_EPOCH
    val timeLow = time &       0xffffffffL
    val timeMid = time &   0xffff00000000L
    val timeHi = time & 0xfff000000000000L
    val upperLong = (timeLow << 32) | (timeMid >> 16) | (1 << 12) | (timeHi >> 48)
    return new java.util.UUID(upperLong, 0xC000000000000000L)
  }

  def main(args: Array[String]): Unit = {
    val conf = new SparkConf(true)
      .set("spark.cassandra.connection.host", args.lift(0).getOrElse("localhost")) //connect to cassandra
      .setExecutorEnv("HADOOP_CONF_DIR", "/opt/mesosphere/etc/hadoop") //connect to HDFS configuration
    val sc = new SparkContext("local", "Shakespeare Ingest", conf)

    val shakespeare = new SQLContext(sc) //creating a Row RDD from JSON file. One object per line
      .jsonFile("hdfs://namenode1.hdfs.mesos:50071" + args.lift(1).getOrElse("/user/root/shakespeare_data.json"))
    shakespeare.printSchema() //null, line_id, line_number, play name, speaker, speech_number, text_entry

    val shakespeareRDD = shakespeare.rdd
      .filter(!_.isNullAt(1)) //filter erroneous rows
      .map( r => Oink( //create Oink object
        "oink",
        r.getLong(1).hashCode.toString, //random id
        r.getString(6).substring(0, Math.min(r.getString(6).length,140)), //max 140 characters
        uuidForDate(Calendar.getInstance.getTime),
        r.getString(4).replaceAll("[^a-zA-Z ]","") //speaker name
      ))
      .cache //save for multiple operations

    //get speakers as hashset
    val authorSet = new HashSet() ++ shakespeareRDD
      .map(_.handle)
      .distinct
      .toLocalIterator

    //add @mentions
    val modifiedLines = shakespeareRDD map { line =>
      var text = line.content
      authorSet foreach { author => //find author name in content
        text = line.content.replaceAllLiterally(author, "@"+author.toLowerCase.replace(" ", "_")) //add underscores
        text = text.substring(0, Math.min(text.length, 140)) //trim in case we exceed the 140 char limit
      }
      val author = line.handle.toLowerCase.replace(" ", "_") //underscores in handles
      Oink(line.kind, line.id, text, line.created_at, author)
    }

    //save to cassandra
    modifiedLines.saveToCassandra("oinker", "oinks", SomeColumns("kind", "id", "content", "created_at", "handle"))
  }
}
