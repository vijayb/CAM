<html>
<body>

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


if (isset($_POST[url]) && isset($_POST[category_id])) {
  $sql = "UPDATE Deals SET category_id=$_POST[category_id] WHERE url='$_POST[url]'";
  $result = mysql_query($sql, $con);
  
  if (!$result) {
    die('Error: ' . mysql_error());
  } else {
    echo "Successfully inserted category [$_POST[category_id]] for ".
      "Deal with url [".htmlentities($_POST[url])."]\n<BR>".
      "[".htmlentities($sql)."]<p>\n";
  }
}



$sql="SELECT url,title,subtitle,text,yelp_categories FROM Deals WHERE category_id IS NULL OR category_id=0";

$result = mysql_query($sql, $con);

if (!$result) {
  die('Error: ' . mysql_error());
}

$num=mysql_num_rows($result);
$i=0;
echo "<b>$num deals don't have categories assigned to them</b><p>\n";
if ($num > 0) {
  $url = mysql_result($result, 0, "url");
  $title = mysql_result($result, 0, "title");
  $subtitle = mysql_result($result, 0, "subtitle");
  $text = mysql_result($result, 0, "text");
  $yelp_categories = mysql_result($result, 0, "yelp_categories");

  echo "<table><tr>\n";
  echo "<td width='50%'>\n";
  echo "<b>URL: </b> <a href='$url' target=blank>".htmlentities($url)."</a><BR>\n";
  echo "<b>Title: </b> $title<BR>\n";
  echo "<b>Subtitle: </b> $subtitle<BR>\n";
  echo "<b>Yelp categories: </b> $yelp_categories<BR>\n";
  echo "<b>Text: </b><BR>$text\n";
  echo "</td>\n";
  echo "<td width='10%'></td>\n";
  
  echo "<td>\n";

  echo "<form name=\"myform\" action=\"https://mobdealio.com/classifier_tool.php?database=mobdeali_production_deals&user=mobdeali_vij&password=daewoo\" method=\"POST\">
<div align=\"left\"><br>
<input type=hidden name=url value='".htmlentities($url)."'>
<input type=\"radio\" name=\"category_id\" value=\"1\">Food<br>
<input type=\"radio\" name=\"category_id\" value=\"2\">Health & Beauty<br>
<input type=\"radio\" name=\"category_id\" value=\"3\">Fitness<br>
<input type=\"radio\" name=\"category_id\" value=\"4\">Retail & Services<br>
<input type=\"radio\" name=\"category_id\" value=\"5\">Activities & Events<br>
<input type=\"radio\" name=\"category_id\" value=\"6\">Vacations<br>
<input type=\"submit\" value=\"Submit\">
</div>
</form>\n";
  echo "</td>\n";
  echo "</tr></table>\n";
}

mysql_close($con)
?>


</body>
</html>