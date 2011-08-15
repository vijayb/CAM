<?php
// Inserts deal record into database

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0) {
  die("Error: missing variable - either database, user or password");
}

// Make a MySQL Connection
$con = mysql_connect("localhost", "$_GET[user]", "$_GET[password]");
if (!$con) {
  die("Error: could not connect: " . mysql_error());
}
mysql_select_db("$_GET[database]", $con) or die(mysql_error());

$insert_addresses=0;
$sql="SELECT address1_id FROM Deals where url='$_POST[url]'";
$result = mysql_query($sql, $con);
if (!result) {
  die('Error: unable to query database ' . mysql_error());
}

if (mysql_num_rows($result) == 0 || 
    is_null(mysql_result($result,0,"address1_id"))) {
  $insert_addresses=1;
}

if (!isset($_POST[url]) || strlen($_POST[url]) < 10 ||
    strlen($_POST[ur]) > 255) {
  die("Error: invalid url: [$_POST[url]]\n");
}

$fields = "url,last_inserted,discovered";
$values = "'$_POST[url]',UTC_TIMESTAMP(),UTC_TIMESTAMP()";

if (isset($_POST[recrawl]) &&
    ($_POST[recrawl] == "0" || $_POST[recrawl] == "1")) {
  $fields = $fields.",recrawl";
  $values = $values.",'$_POST[recrawl]'";
}

if (isset($_POST[use_cookie]) &&
    ($_POST[use_cookie] == "0" || $_POST[use_cookie] == "1")) {
  $fields = $fields.",use_cookie";
  $values = $values.",'$_POST[use_cookie]'";
}

if (isset($_POST[company_id]) &&
    preg_match("/^[0-9]+$/", $_POST[company_id])) {
  $fields = $fields.",company_id";
  $values = $values.",'$_POST[company_id]'";
}

if (isset($_POST[category_id]) &&
    preg_match("/^[0-9]+$/", $_POST[category_id])) {
  $fields = $fields.",category_id";
  $values = $values.",'$_POST[category_id]'";
}

if (isset($_POST[title])) {
  $fields = $fields.",title";
  $values = $values.",'$_POST[title]'";
}

if (isset($_POST[subtitle])) {
  $fields = $fields.",subtitle";
  $values = $values.",'$_POST[subtitle]'";
}

if (isset($_POST[text])) {
  $fields = $fields.",text";
  $values = $values.",'$_POST[text]'";
}

if (isset($_POST[fine_print])) {
  $fields = $fields.",fine_print";
  $values = $values.",'$_POST[fine_print]'";
}

if (isset($_POST[price])) {
  $fields = $fields.",price";
  $values = $values.",'$_POST[price]'";
}

if (isset($_POST[value])) {
  $fields = $fields.",value";
  $values = $values.",'$_POST[value]'";
}

$sql_addendum="";
if (isset($_POST[num_purchased]) &&
    preg_match("/^[0-9]+$/", $_POST[num_purchased])) {
  $fields = $fields.",num_purchased";
  $values = $values.",'$_POST[num_purchased]'";
  $sql_addendum=$sql_addendum.", num_purchased='$_POST[num_purchased]'";
}

if (isset($_POST[expired]) &&
    preg_match("/^[01]$/", $_POST[expired])) {
  $fields = $fields.",expired";
  $values = $values.",'$_POST[expired]'";
  $sql_addendum=$sql_addendum.", expired='$_POST[expired]'";
}

if (isset($_POST[deadline]) &&
    preg_match("/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/",
	       $_POST[deadline])) {
  $fields = $fields.",deadline";
  $values = $values.",'$_POST[deadline]'";
  $sql_addendum=$sql_addendum.", deadline='$_POST[deadline]'";
}

if (isset($_POST[expires]) &&
    preg_match("/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/",
	       $_POST[expires])) {
  $fields = $fields.",expires";
  $values = $values.",'$_POST[expires]'";
}

if (isset($_POST[image_url])) {
  $fields = $fields.",image_url";
  $values = $values.",'$_POST[image_url]'";
}

if (isset($_POST[name])) {
  $fields = $fields.",name";
  $values = $values.",'$_POST[name]'";
  $sql_addendum=$sql_addendum.", name='$_POST[name]'";
}

if (isset($_POST[website])) {
  $fields = $fields.",website";
  $values = $values.",'$_POST[website]'";
  $sql_addendum=$sql_addendum.", website='$_POST[website]'";
}

if (isset($_POST[phone])) {
  $fields = $fields.",phone";
  $values = $values.",'$_POST[phone]'";
}

if ($insert_addresses) {
  $i=1;
  foreach ($_POST as $key => $address) {
    if (preg_match("/^address[0-9]+$/", $key)) {
      $sql = "INSERT INTO Addresses (deal_url, raw_address) VALUES ".
	"('$_POST[url]','$address')";

      $result = mysql_query($sql, $con);
      if (!result) {
	die('Error: unable insert into Addresses table ' . mysql_error());
      }

      $address_id = mysql_insert_id();
      $fields = $fields.",address".$i."_id";
      $values = $values.",".$address_id;
      $sql_addendum=$sql_addendum.", address".$i."_id='$address_id'";
      $i++;
    }
  }
}


$sql = "INSERT INTO Deals (".$fields.") VALUES (".$values.") ".
  "ON DUPLICATE KEY UPDATE last_inserted=UTC_TIMESTAMP()".
  $sql_addendum;


if (!mysql_query($sql, $con)) { die('Error: ' . mysql_error()); }

echo "Successfully insert deal into database.\n";
mysql_close($con);
?>


