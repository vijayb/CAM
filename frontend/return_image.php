<?php
// Make a MySQL Connection


$con = mysql_connect("localhost", "mobdeali_sgm", "cheapass");

if (!$con)
   {
   die('Could not connect: ' . mysql_error());
   }

mysql_select_db("mobdeali_production_deals", $con) or die(mysql_error());



$q=$_GET["q"];



$sql="SELECT image FROM Images WHERE url = '".$q."'";


$result = mysql_query($sql);



echo base64_encode(mysql_result($result, 0));

?>