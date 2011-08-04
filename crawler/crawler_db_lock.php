<?php
// Used by crawler to obtain an exclusive lock for a given database.
// Crawler calling this php script should specify the following variables
// in a get command:
// - database
// - user
// - password
// - action (either: getlock or deletelock)
// - hostname (hostname of the machine on which the crawler is running)
// - pid (the process id of the crawler)
// getlock will return the hostname and pid of the process which
// has a lock on the database. If the hostnam and pid match that
// of the crawler calling the php script, the crawler knows it has
// a lock on the database that other crawlers will respect.

if (!isset($_GET[database]) || strlen($_GET[database]) == 0 ||
    !isset($_GET[user]) || strlen($_GET[user]) == 0 ||
    !isset($_GET[password]) || strlen($_GET[password]) == 0 ||
    !isset($_GET[action]) || strlen($_GET[action]) == 0 ||
    !isset($_GET[hostname]) || strlen($_GET[hostname]) == 0 ||
    !isset($_GET[pid]) || strlen($_GET[pid]) == 0) {
  die("Missing variable - either database,user,password,action,hostname or pid");
}

// Make a MySQL Connection
$con = mysql_connect("localhost", "$_GET[user]", "$_GET[password]");
if (!$con) {
  die("Error, could not connect: " . mysql_error());
}
mysql_select_db("$_GET[database]", $con) or die(mysql_error());

if ($_GET[action] == 'getlock') {
  $sql = "INSERT INTO CrawlerLock (id,hostname,pid) VALUES (1,'$_GET[hostname]',$_GET[pid]) ON DUPLICATE KEY UPDATE id=id";

  if (!mysql_query($sql, $con)) {
    die('Error: ' . mysql_error());
  }

  $sql2 = "SELECT hostname, pid FROM CrawlerLock WHERE id=1";
  $result = mysql_query($sql2, $con);
  if (!$result) {
    die('Error: ' . mysql_error());
  }
  $row = mysql_fetch_array($result);
  if (!$row) {
    die('Error: no row returned when attempting to obtain crawler lock');
  }
  echo "$row[hostname],$row[pid]";

} elseif ($_GET[action] == 'deletelock') {
  $sql3 = "SELECT hostname, pid FROM CrawlerLock WHERE id=1";
  $result = mysql_query($sql3, $con);
  if (!$result) {
    die('Error: ' . mysql_error());
  }
  $row = mysql_fetch_array($result);
  if (!$row) {
    die('Error: no row returned when attempting to delete crawler lock');
  }
  if ($row[hostname] == $_GET[hostname] &&
      $row[pid] == $_GET[pid]) {
    $sql4 = "DELETE from CrawlerLock WHERE id=1";
    $result = mysql_query($sql4, $con);
    if (!$result) {
      die("Error: unable to delete crawler lock");
    } else {
      echo "Successfully deleted crawler lock for process ".
	"$_GET[hostname],$_GET[pid]";
    }
  } else {
    die("Error: Cannot delete crawler lock, held by a different process");
  }
} else {
  echo "Error: Invalid action ($_GET[action]) specified";
}



mysql_close($con);
?>
