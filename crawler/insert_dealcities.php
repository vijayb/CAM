<?php
// Insert record into database

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0 ||
    !isset($_POST[deal_url]) || strlen($_POST[deal_url]) == 0) {
  die("Error: missing variable - either database, user, password or id");
}

$i=0;
$city_ids = array();
foreach ($_POST as $key => $value) { 
  if (preg_match("/^city_ids_[0-9]+$/", $key) &&
      preg_match("/^[0-9]+$/", $value)) {
    $city_ids[$i] = $value;
    $i++;
  }
}  

if ($i==0) {
  die("Error: no valid city ids provided");
}

$sql = "INSERT INTO DealCities (deal_url,city_id,discovered) VALUES ".
  "('$_POST[deal_url]', $city_ids[0], UTC_TIMESTAMP())";
for ($i=1; $i < sizeof($city_ids); $i++) {
  $sql = $sql.",('$_POST[deal_url]', $city_ids[$i], UTC_TIMESTAMP())";
}
$sql = $sql." ON DUPLICATE KEY UPDATE deal_url=deal_url";
echo $sql;


// Make a MySQL Connection
$con = mysql_connect("localhost", "$_GET[user]", "$_GET[password]");
if (!$con) {
  die("Error: could not connect: " . mysql_error());
}
mysql_select_db("$_GET[database]", $con) or die(mysql_error());

if (!mysql_query($sql, $con)) {
  die('Error: '.mysql_error());
} else {
  echo "Successfully inserted into CityDeals.";
}


?>