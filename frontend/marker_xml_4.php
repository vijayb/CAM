<?php

$username="mobdeali_sgm";
$password="cheapass";
$database="mobdeali_production_deals";

// Start XML file, create parent node

$dom = new DOMDocument("1.0");
$node = $dom->createElement("markers");
$parnode = $dom->appendChild($node);

// Opens a connection to a MySQL server

$connection=mysql_connect (localhost, $username, $password);
if (!$connection) {  die('Not connected : ' . mysql_error());}

// Set the active MySQL database

$db_selected = mysql_select_db($database, $connection);
if (!$db_selected) {
  die ('Can\'t use db : ' . mysql_error());
}

// Select all the rows in the markers table


$swLat = $_GET["swLat"];
$swLng = $_GET["swLng"];
$neLat = $_GET["neLat"];
$neLng = $_GET["neLng"];

if ($swLat != "") {
$query = "SELECT * FROM Addresses JOIN Deals ON Deals.url = Addresses.deal_url WHERE latitude > '" . $swLat . "' AND latitude < '" . $neLat . "' AND longitude > '" . $swLng . "' AND longitude < '" . $neLng . "'";
//$query = "SELECT * FROM Addresses WHERE latitude > '" . $swLat . "' AND latitude < '" . $neLat . "' AND longitude > '" . $swLng . "' AND longitude < '" . $neLng . "'";
} else {
$query = "SELECT * FROM Addresses JOIN Deals ON Deals.url = Addresses.deal_url JOIN Images ON Images.url = Deals.image_url WHERE 1";
//$query = "SELECT * FROM Addresses WHERE 1";
}


$result = mysql_query($query);
if (!$result) {
  die('Invalid query: ' . mysql_error());
}

header("Content-type: text/xml");

// Iterate through the rows, adding XML nodes for each

while ($row = @mysql_fetch_assoc($result)){
	// ADD TO XML DOCUMENT NODE
	$node = $dom->createElement("marker");
	$newnode = $parnode->appendChild($node);


        // FIELDS FROM THE ADDRESSES TABLE

	$newnode->setAttribute("id", $row['id']);

	$newnode->setAttribute("deal_url", $row['deal_url']);

	$newnode->setAttribute("street1", $row['street1']);
	$newnode->setAttribute("city", $row['city']);
	$newnode->setAttribute("state", $row['state']);
	$newnode->setAttribute("zipcode", $row['zipcode']);

	$newnode->setAttribute("latitude", $row['latitude']);
	$newnode->setAttribute("longitude", $row['longitude']);

        // FIELDS FROM THE DEALS TABLE


	$newnode->setAttribute("discovered", $row['discovered']);
	$newnode->setAttribute("last_inserted", $row['last_inserted']);
	$newnode->setAttribute("company_id", $row['company_id']);
	$newnode->setAttribute("category_id", $row['category_id']);
	$newnode->setAttribute("title", $row['title']);
	$newnode->setAttribute("subtitle", $row['subtitle']);
	$newnode->setAttribute("price", $row['price']);
	$newnode->setAttribute("value", $row['value']);
	$newnode->setAttribute("num_purchased", $row['num_purchased']);
	$newnode->setAttribute("text", $row['text']);
	$newnode->setAttribute("fine_print", $row['fine_print']);
	$newnode->setAttribute("expired", $row['expired']);
	$newnode->setAttribute("deadline", $row['deadline']);
	$newnode->setAttribute("expires", $row['expires']);
	$newnode->setAttribute("image_url", $row['image_url']);
	$newnode->setAttribute("name", $row['name']);
	$newnode->setAttribute("website", $row['website']);
	$newnode->setAttribute("phone", $row['phone']);
	$newnode->setAttribute("address1_id", $row['address1_id']);
	$newnode->setAttribute("address2_id", $row['address2_id']);
	$newnode->setAttribute("address3_id", $row['address3_id']);
	$newnode->setAttribute("address4_id", $row['address4_id']);
	$newnode->setAttribute("address5_id", $row['address5_id']);
	$newnode->setAttribute("address6_id", $row['address6_id']);
	$newnode->setAttribute("address7_id", $row['address7_id']);
	$newnode->setAttribute("address8_id", $row['address8_id']);
	$newnode->setAttribute("address9_id", $row['address9_id']);
	$newnode->setAttribute("address10_id", $row['address10_id']);
	$newnode->setAttribute("yelp_rating", $row['yelp_rating']);
	$newnode->setAttribute("yelp_url", $row['yelp_url']);


}


echo $dom->saveXML();


?>