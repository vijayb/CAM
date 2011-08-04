<?php
// Make a MySQL Connection



$con = mysql_connect("localhost", "mobdeali_sgm", "cheapass");

if (!$con)
   {
   die('Could not connect: ' . mysql_error());
   }

mysql_select_db("mobdeali_production_deals", $con) or die(mysql_error());

?>


<!doctype html>



<html>

<head>

	<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?sensor=false"></script>
	<script type="text/javascript" src="util.js"></script>

<script type="text/javascript">



markersArray = [];

var swLat;
var swLng;
var neLat;
var neLng;

var map;

function load() {

	geocoder = new google.maps.Geocoder();
	var latlng = new google.maps.LatLng(47.614495, -122.341861);
	var initialOptions = {
		zoom: 12,
		center: latlng,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	}

	map = new google.maps.Map(document.getElementById("map"), initialOptions);


	google.maps.event.addListener(map, 'idle', function () {
		reloadMarkers();
	});

}

function reloadMarkers() {

	var bounds = map.getBounds();
	var swPoint = bounds.getSouthWest();
	var nePoint = bounds.getNorthEast();

	swLat = swPoint.lat();
	swLng = swPoint.lng();
	neLat = nePoint.lat();
	neLng = nePoint.lng();

	var markerXML = "marker_xml_4.php?swLat=" + swLat + "&swLng=" + swLng + "&neLat=" + neLat + "&neLng=" + neLng;

	

	downloadUrl(markerXML, function (data) {
		var markers = data.documentElement.getElementsByTagName("marker");

		deleteOverlays();
	
		for (var i = 0; i < markers.length; i++) {
			var latlng = new google.maps.LatLng(parseFloat(markers[i].getAttribute("latitude")), parseFloat(markers[i].getAttribute("longitude")));
			var marker = new google.maps.Marker({
				position: latlng,
				map: map,
			});

			var index = markers[i].getAttribute("id")
			markersArray.push(marker);

			showMarkerInfo(marker, markers[i]);
		}
	});
}




function deleteOverlays() {
	if (markersArray) {
		for (i in markersArray) {
			markersArray[i].setMap(null);
		}
		markersArray.length = 0;
	}
}

function showImage(dealURL) {
	if (dealURL == "") {
		document.getElementById("deal-title").innerHTML = "";
		return;
	}
	if (window.XMLHttpRequest) { // code for IE7+, Firefox, Chrome, Opera, Safari
		xmlhttp = new XMLHttpRequest();
	} else { // code for IE6, IE5
		xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
	}

	xmlhttp.onreadystatechange = function () {
		if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
			document.getElementById("left-image").innerHTML = '<img src="data:image/jpeg; base64,' + xmlhttp.responseText + '" />';
		}
	}
	xmlhttp.open("GET", "return_image.php?q=" + dealURL, true);
	xmlhttp.send();
}


function showMarkerInfo(marker, info) {

	google.maps.event.addListener(marker, 'click', function () {
		document.getElementById('deal-title').innerHTML = info.getAttribute("title");
		document.getElementById('deal-subtitle').innerHTML = info.getAttribute("subtitle");
		document.getElementById('deal-name').innerHTML = info.getAttribute("name");
		document.getElementById('deal-street1').innerHTML = info.getAttribute("street1");
		document.getElementById('deal-city').innerHTML = info.getAttribute("city");
		document.getElementById('deal-state').innerHTML = info.getAttribute("state");
		document.getElementById('deal-zip').innerHTML = info.getAttribute("zip");
		document.getElementById('deal-price').innerHTML = "$" + info.getAttribute("price");
		document.getElementById('deal-num_purchased').innerHTML = info.getAttribute("num_purchased");
		document.getElementById('deal-value').innerHTML = info.getAttribute("value");
		document.getElementById('deal-discount').innerHTML = Math.round(100 * (parseFloat(info.getAttribute("value")) - parseFloat(info.getAttribute("price"))) / parseFloat(info.getAttribute("value")));
		document.getElementById('deal-savings').innerHTML = parseFloat(info.getAttribute("value")) - parseFloat(info.getAttribute("price"));
		document.getElementById('details-button').onclick = function () {
			window.open(info.getAttribute("deal_url"));
		};
		
		showImage(info.getAttribute("image_url"));

	});
}


</script>

<link href='http://fonts.googleapis.com/css?family=Lato:300,400,700,900,400italic&v2' rel='stylesheet' type='text/css'>

<!-- <link rel="stylesheet" type="text/css" href="style.css" /> -->

<title>Deals!</title>


<style>

header, footer, aside, nav, article {
    display: block;
}

html {
	height:100%;
}

body {
	height:100%;
	margin: 0;
	padding: 0;
	background:#ffffff;
	font-family: 'Lato', sans-serif;
	font-weight:400;
	font-size:90%;
	color:#000000;
	margin:auto;
}


div#map {
	width:100%;
	height:100%;
}

div#right-bar {
	top:0px;
	right:0px;
	width:330px;
	position:absolute;
	background:#f4f4f4;
}

div#left-bar {
	top:0px;
	left:0px;
	width:200px;
	height:100%;
	position:absolute;
	background:#ffffff;
}

div#deal-address1 {
	margin:5px 0 0 0;
}

div#left-image {
	background:#e57c00;
	width:330px;
	height:220px;
	overflow:hidden;
	margin-left: auto;
	margin-right: auto;
}


div.deal-content {
	width:300px;
	padding:10px 15px 10px 15px;
}

div#deal-title, div#deal-subtitle {
	margin:0px;
	padding:0px;
	line-height:1.1;
}

div#deal-title {
	font-weight:700;
	font-size:18px;
}

div#deal-subtitle {
	font-weight:300;
	font-size:15px;
	color:#444444;
	margin:5px 0px 0px 0px;
}

div.coupon {
	width:300px;
	margin:10px 0px 0px 0px;
}

div.coupon-text {
	width:300px;
	margin:10px 0px 0px 0px;
}

div.price-and-button {
	width:300px;
	float:left;
	margin:10px 0 0 0;
}

div#deal-price {
	float:left;
	font-weight:900;
	font-size:30px;
	color:#e57c00;
	line-height:0.8em;
	width:120px;
	text-align:center;
	margin:6px 0 0 0;
}

span#deal-name {
	font-weight:700;
}

.coupon-table {
	border:1px dotted #aaaaaa;
	width:100%;
	padding:4px;
	border-spacing: 0;
	background: #ffffff;
}

.coupon-table td {
	padding: 0px 0px 1px 0px;
	white-space: nowrap;
	text-align: center;
}

.coupon-table thead td {
	font-family: 'Lato', sans-serif;
	font-weight:400;
	font-size:80%;
}

.coupon-table tfoot td {
	padding: 3px 0 3px 0;
	font-weight:300;
	color:#666666;
	border-top:1px dotted #dddddd;
}

.coupon-table tbody td {
	font-size:130%;
	font-weight:900;
}

div.coupon-text {
	width:300px;
}
.clipwrapper {
	position:relative;
	width:85px;
	height:16px;
	float:left;
}

.clip {
	position:absolute;
	top:0;
	left:0;
}

.yelp-00 {
    clip: rect(0pt, 83px, 16px, 0pt);
}

.yelp-10 {
    clip: rect(19px, 83px, 36px, 0pt);
    top: -19px;
}

.yelp-14 {
    clip: rect(38px, 83px, 54px, 0pt);
    top: -38px;
}

.yelp-20 {
    clip: rect(57px, 83px, 73px, 0pt);
    top: -57px;
}

.yelp-25 {
    clip: rect(76px, 83px, 92px, 0pt);
    top: -76px;
}

.yelp-30 {
    clip: rect(95px, 83px, 111px, 0pt);
    top: -95px;
}

.yelp-35 {
    clip: rect(114px, 83px, 130px, 0pt);
    top: -114px;
}

.yelp-40 {
    clip: rect(133px, 83px, 149px, 0pt);
    top: -133px;
}

.yelp-45 {
    clip: rect(152px, 83px, 169px, 0pt);
    top: -152px;
}

.yelp-50 {
    clip: rect(171px, 83px, 187px, 0pt);
    top: -171px;
}


div.rating {
	margin:10px 0 0 0;
	width:100%;
}

span.category-dn {
	background:#3d8c4c;
	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	padding:0px 4px 0px 4px;
	color:#ffffff;
	font-weight:700;
}

button.cupid-green {
	-moz-border-bottom-colors: none;
	-moz-border-image: none;
	-moz-border-left-colors: none;
	-moz-border-right-colors: none;
	-moz-border-top-colors: none;
	background-color: #e57c00;
	background-image: -webkit-gradient(linear, left top, left bottom, from(#e57c00), to(#ce6800));
	background-image: -webkit-linear-gradient(top, #e57c00, #ce6800);
	background-image: -moz-linear-gradient(top, #e57c00, #ce6800);
	background-image: -ms-linear-gradient(top, #e57c00, #ce6800);
	background-image: -o-linear-gradient(top, #e57c00, #ce6800);
	background-image: linear-gradient(top, #e57c00, #ce6800);
	border-color: #d07000 #a05000 #a05000 #a05000;
	border-radius: 3px 3px 3px 3px;
	border-style: solid;
	border-width: 1px;
	box-shadow: 0 1px 0 0 #ec942c inset;
	color: #FFFFFF;
	padding: 5px 0 5px 0;
	text-align: center;
	text-shadow: 0 -1px 0 #ca6600;
	width: 180px;
	font-family: 'Lato', sans-serif;
	font-size:120%;
	font-weight:900;
}

button.cupid-green:hover {
	background-color: #a05000;
	background-image: -webkit-gradient(linear, left top, left bottom, from(#f0870c), to(#e07100));
	background-image: -webkit-linear-gradient(top, #f0870c, #e07100);
	background-image: -moz-linear-gradient(top, #f0870c, #e07100);
	background-image: -ms-linear-gradient(top, #f0870c, #e07100);
	background-image: -o-linear-gradient(top, #f0870c, #e07100);
	background-image: linear-gradient(top, #f0870c, #e07100);
	cursor: pointer;
}

button.cupid-green:active {
	border: 1px solid #a05000;
	background-image: -webkit-gradient(linear, left top, left bottom, from(#e07100), to(#f0870c));
	background-image: -webkit-linear-gradient(top, #e07100, #f0870c);
	background-image: -moz-linear-gradient(top, #e07100, #f0870c);
	background-image: -ms-linear-gradient(top, #e07100, #f0870c);
	background-image: -o-linear-gradient(top, #e07100, #f0870c);
	background-image: linear-gradient(top, #e07100, #f0870c);

	-webkit-box-shadow: inset 0 1px 1px 0 #c36600, 0 1px 0 0 #eeeeee;
	-moz-box-shadow: inset 0 1px 1px 0 #c36600, 0 1px 0 0 #eeeeee;
	-ms-box-shadow: inset 0 1px 1px 0 #c36600, 0 1px 0 0 #eeeeee;
	-o-box-shadow: inset 0 1px 1px 0 #c36600, 0 1px 0 0 #eeeeee;
	box-shadow: inset 0 1px 1px 0 #c36600, 0 1px 0 0 #eeeeee;
}

</style>

</head>

<body onload="load()">


	<div id="map"></div>


	<div id="right-bar">
	<div id="left-image"></div>
	<div class="deal-content">
		<div id="deal-title"></div>
		<div id="deal-subtitle"></div>


		<div class="coupon-text">
			<span class="category-dn">Dining & Nightlife</span><br>

			<div class="rating">
				<div class="clipwrapper">
				   <!-- <img src="stars_map.png" alt="arrow" class="clip yelp-<?php echo($row["yelp_rating"]); ?>" /> -->
				   <img src="stars_map.png" alt="arrow" class="clip yelp-45" />
				</div>
				&nbsp;-&nbsp;<a href="#">Yelp</a>
			</div>

			<div id="deal-address1">
				<span id="deal-name"></span>
				<br>
				<span id="deal-street1"></span>
				<br>
				<span id="deal-city"></span>,&nbsp;<span id="deal-state"></span><span id="deal-zip"></span>
			</div>
		</div>

		<div class="coupon">
			<table class="coupon-table">
				<thead>
					<tr>
					<td>worth</td><td>discount</td><td>savings</td>
					</tr>
				</thead>

				<tbody>
					<tr>
						<td>$<span id="deal-value"></span></td><td><span id="deal-discount"></span>%</td><td>$<span id="deal-savings"></span></span></td>
					</tr>
				</tbody>

				<tfoot>
					<tr>
						<td colspan=3><span id="deal-num_purchased"></span> purchased</td>
					</tr>
					<tr>
						<td colspan=3>Expires 2011-09-12</td>
					</tr>
				</tfoot>
			</table>
		</div>

		<div class="price-and-button">
			<div id="deal-price"></div>
			<div class="button"><button class="cupid-green" id="details-button">Details</button></div>
		</div>


		<span style="color:#666666; text-align:center; float:right; margin:5px 0px 10px 0px;">from Groupon</span>


	</div>
	</div>

	<!--
	<div id="left-bar">
	Search filters go here
	</div>
	-->

</body>
</html>
