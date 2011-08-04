<?php
// Insert record into database
$MAX_IMAGE_SIZE = 1000000; // 1 megabyte

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0) {
  die("Error: missing variable - either database, user or password");
}

$con = mysql_connect("localhost", "$_GET[user]", "$_GET[password]");
if (!$con) {
  die("Error: could not connect: " . mysql_error());
}
mysql_select_db("$_GET[database]", $con) or die('Error: '.mysql_error());

if (isset($_POST[image_url]) && isset($_FILES['image_data']) &&
    $_FILES['image_data']['size'] > 0 &&
    $_FILES['image_data']['size'] < $MAX_IMAGE_SIZE) { 
      // Temporary file name stored on the server
      $tmpName  = $_FILES['image_data']['tmp_name'];  
       
      // Read the file 
      $fp   = fopen($tmpName, 'r');
      $data = fread($fp, filesize($tmpName));
      $data = addslashes($data);
      fclose($fp);

      // Create the query and insert into database.
      $sql = "INSERT INTO Images (url, image) ".
	"VALUES ('".$_POST[image_url]."', '$data') ".
	"ON DUPLICATE KEY UPDATE url=url";

      if (!mysql_query($sql, $con)) {
	die('Error: '.mysql_error());
      } else {
	echo "Image successfully inserted.";
      }
} else {
   echo  "Error: Invalid (or no) image provided.";
}

// Close our MySQL Con
mysql_close($con);
?>  
