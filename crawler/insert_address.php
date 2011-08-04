<?php
// Insert record into database

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0 ||
    !isset($_POST[id]) || strlen($_POST[id]) == 0) {
  die("Error: missing variable - either database, user, password or id");
}


$keys="id";
$values="'$_POST[id]'";
$updates="";
foreach ($_POST as $key => $value) { 
  if ($key == "street") {
    $updates=$updates."street1='$value',";
  }

  if ($key == "city") {
    $updates=$updates."city='$value',";
  }

  if ($key == "state") {
    $updates=$updates."state='$value',";
  }

  if ($key == "country") {
    $updates=$updates."country='$value',";
  }

  if ($key == "zipcode") {
    $updates=$updates."zipcode='$value',";
  }

  if ($key == "latitude") {
    $updates=$updates."latitude='$value',";
  }

  if ($key == "longitude") {
    $updates=$updates."longitude='$value',";
  }
}

// Remove trailing comma from updates
$updates = rtrim($updates, ',');
$sql = "UPDATE Addresses SET $updates WHERE id='$_POST[id]'";

// Make a MySQL Connection
$con = mysql_connect("localhost", "$_GET[user]", "$_GET[password]");
if (!$con) {
  die("Error: could not connect: " . mysql_error());
}
mysql_select_db("$_GET[database]", $con) or die(mysql_error());

if (!mysql_query($sql, $con)) {
  die('Error: '.mysql_error());
} else {
  echo "Successfully inserted into Addresses.";
}


?>