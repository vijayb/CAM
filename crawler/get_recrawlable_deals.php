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
  die('Could not connect: ' . mysql_error());
}

mysql_select_db($_GET[database], $con) or die(mysql_error());
   

$sql="SELECT url,company_id,use_cookie,discovered from Deals WHERE (recrawl <=> 1) AND !(expired <=> 1) AND (TIME_TO_SEC(TIMEDIFF(UTC_TIMESTAMP(), discovered)) < $_GET[max_days]*24*60*60) AND (TIME_TO_SEC(TIMEDIFF(deadline, UTC_TIMESTAMP())) > -86400)";
// 86400 is the number of seconds in a day. We grab deals up to a day past
// their deadline because the deadline was extracted and possibly could
// be incorrect (we hope by not too much)


$result = mysql_query($sql, $con);

if (!$result) {
  die('Error: ' . mysql_error());
}

$num=mysql_num_rows($result);
$i=0;
while ($i < $num) {
  $url = mysql_result($result, $i, "url");
  $company_id = mysql_result($result, $i, "company_id");
  $use_cookie = mysql_result($result, $i, "use_cookie");
  $discovered = mysql_result($result, $i, "discovered");
  echo "$url,$company_id,$use_cookie,$discovered\n";
  $i++;
}

mysql_close($con)
?>