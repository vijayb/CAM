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
   

$sql="SELECT * FROM Hubs";

$result = mysql_query($sql, $con);

if (!$result) {
  die('Error: ' . mysql_error());
}

$num=mysql_num_rows($result);
$i=0;
while ($i < $num) {
  $url = mysql_result($result, $i, "url");
  $company_id = mysql_result($result, $i, "company_id");
  $city_id = mysql_result($result, $i, "city_id");
  $category_id = mysql_result($result, $i, "category_id");
  $use_cookie = mysql_result($result, $i, "use_cookie");
  $recrawl_deal_urls = mysql_result($result, $i, "recrawl_deal_urls");
  $hub_contains_deal = mysql_result($result, $i, "hub_contains_deal");
  echo "$url,$company_id,$city_id,$category_id,$use_cookie,$recrawl_deal_urls,$hub_contains_deal\n";
  $i++;
}

mysql_close($con)
?>