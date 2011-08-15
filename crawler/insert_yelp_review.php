<?php
// Insert record into database

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0 ||
    !isset($_POST[url]) || strlen($_POST[url]) == 0) {
  die("Error: missing variable - either database, user, password or url");
}


$updates = "";
foreach ($_POST as $key => $value) {
  if (strcmp($key, "url") != 0) {
    $updates = $updates."$key='$value',";

  }
}

// Remove trailing comma from updates
$updates = rtrim($updates, ',');
$sql = "UPDATE Deals SET $updates WHERE url='$_POST[url]'";

// Make a MySQL Connection
$con = mysql_connect("localhost", "$_GET[user]", "$_GET[password]");
if (!$con) {
  die("Error: could not connect: " . mysql_error());
}
mysql_select_db("$_GET[database]", $con) or die(mysql_error());

if (!mysql_query($sql, $con)) {
  die('Error: '.mysql_error());
} else {
  echo "Successfully inserted yelp review";
}


?>