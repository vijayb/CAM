<?php

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0 ||
    !isset($_GET[max_days]) ||
    !preg_match("/^[1-9][0-9]?+$/", $_GET[max_days])) {
  die("Error: missing variable - either database,user,password or max_days");
}

// Make a MySQL Connection
$con = mysql_connect("localhost", $_GET[user], $_GET[password]);

if (!$con) {
  die('Error: could not connect. ' . mysql_error());
}

mysql_select_db($_GET[database], $con) or die(mysql_error());


$sql = "SELECT Deals.url,Deals.name,Deals.phone,Addresses.latitude,".
  "Addresses.longitude FROM Deals,Addresses WHERE ".
  "(TIME_TO_SEC(TIMEDIFF(UTC_TIMESTAMP(), Deals.discovered)) < ".
  "$_GET[max_days]*24*60*60) ".
  "AND ((Deals.url=Addresses.deal_url) AND (Deals.yelp_rating IS NULL) AND ".
  "(Deals.name IS NOT NULL))";

$result = mysql_query($sql, $con);

if (!$result) {
  die('Error: ' . mysql_error());
}

$num=mysql_num_rows($result);
$i=0;
while ($i < $num) {
  $url = mysql_result($result, $i, "url");
  $name = mysql_result($result, $i, "name");
  $phone = mysql_result($result, $i, "phone");
  $latitude = mysql_result($result, $i, "latitude");
  $longitude = mysql_result($result, $i, "longitude");
  echo "$url\n$name\n$phone\n$latitude\n$longitude\n";
  $i++;
}

$sql = "SELECT url,name,phone FROM Deals WHERE ".
  "(TIME_TO_SEC(TIMEDIFF(UTC_TIMESTAMP(), discovered)) < ".
  "$_GET[max_days]*24*60*60) ".
  "AND (yelp_rating IS NULL) AND (name IS NOT NULL) AND ".
  "(address1_id IS NULL) AND (phone IS NOT NULL)";



$result = mysql_query($sql, $con);

if (!$result) {
  die('Error: ' . mysql_error());
}

$num=mysql_num_rows($result);
$i=0;
while ($i < $num) {
  $url = mysql_result($result, $i, "url");
  $name = mysql_result($result, $i, "name");
  $phone = mysql_result($result, $i, "phone");
  $latitude = "";
  $longitude = "";
  echo "$url\n$name\n$phone\n$latitude\n$longitude\n";
  $i++;
}



mysql_close($con)
?>