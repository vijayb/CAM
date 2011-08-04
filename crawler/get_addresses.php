<?php

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0) {
  die("Error: missing variable - either database,user or password");
}

// Make a MySQL Connection
$con = mysql_connect("localhost", $_GET[user], $_GET[password]);

if (!$con) {
  die('Error: could not connect. ' . mysql_error());
}

mysql_select_db($_GET[database], $con) or die(mysql_error());
   

$sql="SELECT id, raw_address FROM Addresses WHERE (longitude IS NULL) ".
  "OR (latitude IS NULL)";

$result = mysql_query($sql, $con);

if (!$result) {
  die('Error: ' . mysql_error());
}

$num=mysql_num_rows($result);
$i=0;
while ($i < $num) {
  $id = mysql_result($result, $i, "id");
  $raw_address = mysql_result($result, $i, "raw_address");
  echo "$id,$raw_address\n";
  $i++;
}

mysql_close($con)
?>