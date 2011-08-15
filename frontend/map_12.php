<!doctype html>



<html>

<head>

	<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?sensor=false"></script>
	<script type="text/javascript" src="util.js"></script>
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js" type="text/javascript"></script>


<script type="text/javascript">



markersArray = [];


// If categoriesToShow[x] == 1, then we SHOW deals with category x.
categoriesToShow = [1, 1, 1, 1, 1, 1, 1];

var swLat;
var swLng;
var neLat;
var neLng;

var map;

var selectedMarkerIndex = -1;

var categories = [];
var companies = [];
var showExpired = 0;
var showOnlyNew = 0;

categories[0] = "Uncategorized";
categories[1] = "Restaurants";
categories[2] = "Health & Beauty";
categories[3] = "Fitness";
categories[4] = "Retail & Services";
categories[5] = "Activities & Events";
categories[6] = "Vacations";

companies[0] = "No company at this index";
companies[1] = "Groupon";
companies[2] = "Living Social";
companies[3] = "BuyWithMe";
companies[4] = "Tippr";



function debug(string) {
	document.getElementById('debug-bar-output').innerHTML += string + "<br>";
}

function load() {

	geocoder = new google.maps.Geocoder();
	var latlng = new google.maps.LatLng(47.614495, -122.341861);
	var initialOptions = {
		zoom: 12,
		center: latlng,
		mapTypeId: google.maps.MapTypeId.ROADMAP,
		mapTypeControlOptions: {
			style: google.maps.MapTypeControlStyle.HORIZONTAL_BAR,
			position: google.maps.ControlPosition.TOP_LEFT
		},
		panControl: false,
		zoomControl: false,
		mapTypeControl: false,
		scaleControl: false,
		streetViewControl: false,
		overviewMapControl: false


	}

	map = new google.maps.Map(document.getElementById("map"), initialOptions);

	google.maps.event.addListener(map, 'idle', function () {
		reloadMarkers();
	});

	var f = function(mystring, j)
	  {
	    return function()
	    {
	      if ($(mystring).is(":checked")) {
			categoriesToShow[j] = 1;
			reloadMarkers();
	      } else {
		categoriesToShow[j] = 0;
		reloadMarkers();
	      }
	    }
	  }
	
	for (i = 1; i <= 6; i++) {
		$("#filter-" + i).prop("checked", true);
		$("#filter-" + i).click(f("#filter-" + i, i));
	}

	$("#filter-show-expired").click(function () {

		if ($("#filter-show-expired").is(":checked")) {
			showExpired = 1;
			reloadMarkers();
		} else {
			showExpired = 0;
			reloadMarkers();
		}
	});

	$("#filter-show-new").click(function () {

		if ($("#filter-show-new").is(":checked")) {
			showOnlyNew = 1;
			reloadMarkers();
		} else {
			showOnlyNew = 0;
			reloadMarkers();
		}
	});

}

var markerClick = function(marker) {
	
	return function() {

		getCount(mysqlTimeStampToDate(marker.deadline), 'deal-expires');

		$("#deal-maintitle").html(marker.maintitle);
		$("#deal-subtitle").html(marker.subTitle);
		$("#deal-name").html(marker.name);
		$("#deal-street1").html(marker.street1);
		$("#deal-city").html(marker.city);
		$("#deal-state").html(marker.state);
		$("#deal-zip").html(marker.zip);
		$("#deal-price").html("$" + marker.price);
		
		if (marker.numPurchased == "") {
			$("#purchased").hide();
		} else {
			$("#purchased").show();
			$("#deal-num_purchased").html(marker.numPurchased);
		}
				
		if (marker.age == 0) {
			$("#deal-discovered").html("today!");
		} else if (marker.age == 1) {
			$("#deal-discovered").html("yesterday");
		} else {
			$("#deal-discovered").html(marker.age + " days ago");
		}
		
		
		
		$("#deal-value").html(marker.value);
		$("#deal-discount").html(marker.discount);
		$("#deal-savings").html(marker.savings);
		$("#category").html(categories[marker.categoryID]);
		$("#company").html("<img src='company_" + marker.companyID + "_gray.png'>");
		
		document.getElementById('details-button').onclick = function () {
			window.open(marker.url);
		};


		// Don't show the Yelp section if there is no rating
		if (marker.yelpRating == "") {
			$("#rating").css("display", "none");
		} else {
			$("#rating").css("display", "block");
			var existingClass = $("#yelp-stars").attr("class");
			$("#yelp-stars").removeClass(existingClass);
			document.getElementById('yelp-stars').className += "clip yelp-" + marker.yelpRating.replace(".", "");
			document.getElementById('deal-yelp_url').innerHTML = "<a href='" + marker.yelpUrl + "'>Yelp</a>";
		}


		var existingClass = $("#category").attr("class");
		$("#category").removeClass(existingClass);
		document.getElementById('category').className += "category-" + marker.categoryID;

		// Call a function to populate the image section of the right panel
		showImage(marker.imageUrl);

		
		// Reset the previously selected marker's icon and update the newly selected marker's icon
		
		var expired_e;

		if (isExpired(mysqlTimeStampToDate(markersArray[selectedMarkerIndex].deadline)) == 1) {
			expired_e = "e";
		} else {
			expired_e = "";
		}
		markersArray[selectedMarkerIndex].setIcon(new google.maps.MarkerImage('marker_' + markersArray[selectedMarkerIndex].categoryID + expired_e + '.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11)));
		
		selectedMarkerIndex = marker.index;
		markersArray[selectedMarkerIndex].setIcon(new google.maps.MarkerImage('marker_' + markersArray[selectedMarkerIndex].categoryID + '_on.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11)));

	}
		
}







function reloadMarkers() {

	var bounds = map.getBounds();
	var swPoint = bounds.getSouthWest();
	var nePoint = bounds.getNorthEast();

	// Build a string beginning with "marker_xml.php" and adding the correct bounds of the currently displayed map. This will later be used to download the XML representing all visible pins.
	// As an example, load the following in a web browser: http://marker_xml.php?swLat=47.50920007060634&swLng=-122.58836673730468&neLat=47.719578332770105&neLng=-122.0953552626953
	var markerXML = "marker_xml.php?swLat=" + swPoint.lat() + "&swLng=" + swPoint.lng() + "&neLat=" + nePoint.lat() + "&neLng=" + nePoint.lng();

	debug(markerXML);

	// Download the XML corresponding to the visible markers
	downloadUrl(markerXML, function (data) {
		var markers = data.documentElement.getElementsByTagName("marker");

		// First, delete all markers that are already on the map.
		deleteOverlays();


		// e means expired. Expired icons are different
		
		var marker0 = new google.maps.MarkerImage('marker_0.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker0e = new google.maps.MarkerImage('marker_0e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));

		var marker1 = new google.maps.MarkerImage('marker_1.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker2 = new google.maps.MarkerImage('marker_2.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker3 = new google.maps.MarkerImage('marker_3.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker4 = new google.maps.MarkerImage('marker_4.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker5 = new google.maps.MarkerImage('marker_5.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker6 = new google.maps.MarkerImage('marker_6.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));

		var marker1e = new google.maps.MarkerImage('marker_1e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker2e = new google.maps.MarkerImage('marker_2e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker3e = new google.maps.MarkerImage('marker_3e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker4e = new google.maps.MarkerImage('marker_4e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker5e = new google.maps.MarkerImage('marker_5e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var marker6e = new google.maps.MarkerImage('marker_6e.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));


		var markerShadow = new google.maps.MarkerImage('marker_shadow.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));
		var markerShadowe = new google.maps.MarkerImage('marker_shadowe.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11));

		// Go through each XML marker
		
		// j keeps track of each displayed marker's index in the global markersArray array. i doesn't work for this purpose because i
		// iterates through all the markers in the XML, but not all the markers in the XML will be shown because the user may not want
		// to see all categories.
		var j = 0;
		
		for (var i = 0; i < markers.length; i++) {
			var latlng = new google.maps.LatLng(parseFloat(markers[i].getAttribute("latitude")), parseFloat(markers[i].getAttribute("longitude")));

			// If the marker doesn't have a category ID, set it to 0
			var category_id;
			if (markers[i].getAttribute("category_id") == "") {
				category_id = 0;
			} else {
				category_id = markers[i].getAttribute("category_id");
			}
			
			var expired_e;
			
			if (isExpired(mysqlTimeStampToDate(markers[i].getAttribute("deadline"))) == 1) {
				expired_e = "e";
			} else {
				expired_e = "";
			}
			
			if (categoriesToShow[category_id] == 0) {
				// don't show this marker
			} else if (showExpired == 0 && isExpired(mysqlTimeStampToDate(markers[i].getAttribute("deadline"))) == 1) {
				// don't show expired marker since the user doesn't want to see it
			} else if (showOnlyNew == 1 && getAge(mysqlTimeStampToDate(markers[i].getAttribute("discovered"))) > 0) {
				// don't show deals with age greater than 0 if the user wants to see only new deals
			} else {
				
				var marker = new google.maps.Marker({
					position: latlng,
					map: map,

					icon: eval("marker" + category_id + expired_e),
					shadow: eval("markerShadow" + expired_e),

					categoryID: category_id,

					index: j,

					maintitle: markers[i].getAttribute("title"),
					subTitle: markers[i].getAttribute("subtitle"),

					name: markers[i].getAttribute("name"),
					street1: markers[i].getAttribute("street1"),
					city: markers[i].getAttribute("city"),
					state: markers[i].getAttribute("state"),
					zip: markers[i].getAttribute("zip"),

					price: markers[i].getAttribute("price"),
					numPurchased: markers[i].getAttribute("num_purchased"),
					value: markers[i].getAttribute("value"),
					discount: Math.round(100 * (parseFloat(markers[i].getAttribute("value")) - parseFloat(markers[i].getAttribute("price"))) / parseFloat(markers[i].getAttribute("value"))),
					savings: parseFloat(markers[i].getAttribute("value")) - parseFloat(markers[i].getAttribute("price")),

					url: markers[i].getAttribute("deal_url"),
					deadline: markers[i].getAttribute("deadline"),
					discovered: markers[i].getAttribute("discovered"),
				
					yelpRating: markers[i].getAttribute("yelp_rating"),
					yelpUrl: markers[i].getAttribute("yelp_url"),
				
					imageUrl: markers[i].getAttribute("image_url"),
				
					isExpired: isExpired(mysqlTimeStampToDate(markers[i].getAttribute("deadline"))),
					age: getAge(mysqlTimeStampToDate(markers[i].getAttribute("discovered"))),
					
					title:  getAge(mysqlTimeStampToDate(markers[i].getAttribute("discovered"))).toString(),
					
					companyID: markers[i].getAttribute("company_id"),
					

				});


				markersArray.push(marker);
				google.maps.event.addListener(marker, 'click', markerClick(marker));
				
				j++;
			}




		}

		debug(markersArray.length + " markers on the map");

		// Just prior to reloading the markers, selectedMarkerIndex was set to 0 in deleteOverlays.
		highlightSelectedMarker();
		markerClick(marker, markers[0])();
		$("#right-bar").css("display", "block");
		

	});
}








function deleteOverlays() {
	selectedMarkerIndex = 0;
	if (markersArray) {
		for (i in markersArray) {
			markersArray[i].setMap(null);
		}
		markersArray.length = 0;
		
	}
}

function showImage(dealURL) {
	if (dealURL == "") {
		document.getElementById("deal-maintitle").innerHTML = "";
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

function mysqlTimeStampToDate(timestamp) {
	var regex = /^([0-9]{2,4})-([0-1][0-9])-([0-3][0-9]) (?:([0-2][0-9]):([0-5][0-9]):([0-5][0-9]))?$/;
	var parts = timestamp.replace(regex, "$1 $2 $3 $4 $5 $6").split(' ');
	return new Date(parts[0], parts[1] - 1, parts[2], parts[3], parts[4], parts[5]);
}

function isExpired(deadlineDate) {
	d = new Date();
	var timeUTC = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes(), d.getUTCSeconds(), d.getUTCMilliseconds());

	timeNow = new Date();
	differenceInMilliseconds = deadlineDate.getTime() - timeUTC.getTime();
	delete timeNow;

	// If time is already past...
	if (differenceInMilliseconds < 0) {
		return 1;
	} else {
		return 0;
	}
}

function getAge(discoveredDate) {
	d = new Date();
	var timeUTC = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes(), d.getUTCSeconds(), d.getUTCMilliseconds());

	timeNow = new Date();
	differenceInMilliseconds = timeUTC.getTime() - discoveredDate.getTime();
	delete timeNow;
	
	var ageInDays = Math.floor(differenceInMilliseconds / 86400000);
	return ageInDays;

}

// Takes in a deadline for a deal and a target div, then outputs to the target div the amount of time until the deadline. If the dealine has passed, writes "Expired" to the target div
function getCount(deadlineDate, targetDiv) {

	d = new Date();
	var timeUTC = new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes(), d.getUTCSeconds(), d.getUTCMilliseconds());

	timeNow = new Date();
	differenceInMilliseconds = deadlineDate.getTime() - timeUTC.getTime();
	delete timeNow;

	// If time is already past...
	if (differenceInMilliseconds < 0) {
		document.getElementById(targetDiv).innerHTML = "Expired";
	}
	// Else date is still good...
	else {
		days = 0;
		hours = 0;
		mins = 0;
		secs = 0;
	
		out = "Expires in <span class='expires-in'>";

		differenceInMilliseconds = Math.floor(differenceInMilliseconds / 1000);
		days = Math.floor(differenceInMilliseconds / 86400);
		differenceInMilliseconds = differenceInMilliseconds % 86400;

		hours = Math.floor(differenceInMilliseconds / 3600);
		differenceInMilliseconds = differenceInMilliseconds % 3600;

		mins = Math.floor(differenceInMilliseconds / 60);
		differenceInMilliseconds = differenceInMilliseconds % 60;

		secs = Math.floor(differenceInMilliseconds);
		if (days != 0) {
			out += days + " " + ((days == 1) ? "<span class='expires-in-units'>d</span>" : "<span class='expires-in-units'>d</span>") + " ";
		}
		if (hours != 0) {
			out += hours + " " + ((hours == 1) ? "<span class='expires-in-units'>hr</span>" : "<span class='expires-in-units'>hr</span>") + " ";
		}
		
		out += mins + " " + ((mins == 1) ? "<span class='expires-in-units'>min</span>" : "<span class='expires-in-units'>min</span></span>") + " ";
		// TODO vijay: figure out why it breaks when the seconds are shown as a countdown		
//out += secs +" "+((secs==1)?"sec":"secs")+", ";
		out = out.substr(0, out.length - 2);
		document.getElementById(targetDiv).innerHTML = out;

		//setTimeout(function(){getCount(deadlineDate,targetDiv)}, 1000);
	}
}



	

function highlightSelectedMarker() {
	markersArray[selectedMarkerIndex].setIcon(new google.maps.MarkerImage('marker_' + markersArray[selectedMarkerIndex].categoryID + '_on.png', new google.maps.Size(22, 22), new google.maps.Point(0, 0), new google.maps.Point(11, 11)));
}




</script>

<link href='http://fonts.googleapis.com/css?family=Lato:300,400,700,900,400italic&v2' rel='stylesheet' type='text/css'>

<!-- <link rel="stylesheet" type="text/css" href="style.css" /> -->

<title>Map</title>


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


div#debug-bar {
	bottom:0px;
	left:0px;
	width:200px;
	height:300px;
	position:absolute;
	background:#ffffff;
        display:none;
	overflow:scroll;
	font-size:10px;

}

div#right-bar {
	top:10px;
	right:10px;
	width:330px;
	position:absolute;
display:none;

	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	border-radius:3px;

	box-shadow:0px 2px 4px #666666, inset 0px 0px 1px #999999;
	
	
	background: #f9f9f9;
	background-image: url(bg.png); /* fallback */
	background-image: url(bg.png), -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc)); /* Saf4+, Chrome */
	background-image: url(bg.png), -webkit-linear-gradient(top, #ffffff, #cccccc); /* Chrome 10+, Saf5.1+ */
	background-image: url(bg.png), -moz-linear-gradient(top, #ffffff, #cccccc); /* FF3.6+ */
	background-image: url(bg.png), -ms-linear-gradient(top, #ffffff, #cccccc); /* IE10 */
	background-image: url(bg.png), -o-linear-gradient(top, #ffffff, #cccccc); /* Opera 11.10+ */
	background-image: url(bg.png), linear-gradient(top, #ffffff, #cccccc); /* W3C */

	
}

div#filters-bar {
	top:10px;
	left:10px;
	width:150px;
	position:absolute;

	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	border-radius:3px;

	box-shadow:0px 2px 3px #666666, inset 0px 0px 1px #bbbbbb;
	
	
	background: #f9f9f9;
	background-image: url(bg.png); /* fallback */
	background-image: url(bg.png), -webkit-gradient(linear, left top, left bottom, from(#ffffff), to(#cccccc)); /* Saf4+, Chrome */
	background-image: url(bg.png), -webkit-linear-gradient(top, #ffffff, #cccccc); /* Chrome 10+, Saf5.1+ */
	background-image: url(bg.png), -moz-linear-gradient(top, #ffffff, #cccccc); /* FF3.6+ */
	background-image: url(bg.png), -ms-linear-gradient(top, #ffffff, #cccccc); /* IE10 */
	background-image: url(bg.png), -o-linear-gradient(top, #ffffff, #cccccc); /* Opera 11.10+ */
	background-image: url(bg.png), linear-gradient(top, #ffffff, #cccccc); /* W3C */

	padding:15px 15px 15px 15px;
}


div#filters {
	margin:25px 0px 0px 0px;
	line-height:1.7;
}

div#filters span.small {
	font-size:12px;
}


div#deal-address1 {
	margin:5px 0 0 0;
}

div#left-image {
	background:#e57c00;
	width:330px;
	height:220px;
	overflow:hidden;

	-webkit-border-top-left-radius:3px;
	-moz-border-top-left-radius:3px;
	border-top-left-radius:3px;
}


div.deal-content {
	width:300px;
	padding:10px 15px 10px 15px;
	
	border-top: 1px solid #ffffff;
}

div#deal-maintitle, div#deal-subtitle {
	margin:0px;
	padding:0px;
	line-height:1.1;
	text-shadow: 0px 1px 0px #fff;
}

div#deal-maintitle {
	font-weight:400;
	font-size:26px;
	color:#000000;
}

div#deal-subtitle {
	font-weight:300;
	font-size:18px;
	color:#333333;
	margin:7px 0px 0px 0px;
}

div.coupon {
	width:300px;
	margin:10px 0px 0px 0px;
}

div.coupon-text {
	width:300px;
	margin:10px 0px 0px 0px;
}

span.expires-in {
	color:#000000;
	font-size: 16px;
	font-weight: 700;
}

span#deal-num_purchased {
	color:#000000;
	font-size: 16px;
	font-weight: 700;
}


span.expires-in-units {
	font-size:12px;
	vertical-align: super;
	font-weight:300;
}

div.price-and-button {
	width:300px;
	float:left;
	margin:10px 0 0 0;
}

div#deal-price {
	float:left;
	font-weight:900;
	font-size:36px;
	color:#e57c00;
	line-height:0.8em;
	width:120px;
	text-align:center;
	margin:0px 0px 0px 0px;
	text-shadow: 0px 1px 0px #eee;
}

span#deal-name {
}

.coupon-table {
	border:1px dotted #666666;
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
	color:#666666;

}

.coupon-table tfoot td {
	padding: 3px 0 3px 0;
	font-weight:300;
	color:#666666;
	border-top:1px dotted #cccccc;
}

.coupon-table tbody td {
	font-size:26px;
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

.yelp- {
    visibility:hidden;
}


.yelp-0 {
    clip: rect(0pt, 83px, 16px, 0pt);
}

.yelp-1 {
    clip: rect(19px, 83px, 36px, 0pt);
    top: -19px;
}

.yelp-15 {
    clip: rect(38px, 83px, 54px, 0pt);
    top: -38px;
}

.yelp-2 {
    clip: rect(57px, 83px, 73px, 0pt);
    top: -57px;
}

.yelp-25 {
    clip: rect(76px, 83px, 92px, 0pt);
    top: -76px;
}

.yelp-3 {
    clip: rect(95px, 83px, 111px, 0pt);
    top: -95px;
}

.yelp-35 {
    clip: rect(114px, 83px, 130px, 0pt);
    top: -114px;
}

.yelp-4 {
    clip: rect(133px, 83px, 149px, 0pt);
    top: -133px;
}

.yelp-45 {
    clip: rect(152px, 83px, 169px, 0pt);
    top: -152px;
}

.yelp-5 {
    clip: rect(171px, 83px, 187px, 0pt);
    top: -171px;
}


div#rating {
	margin:10px 0 0 0;
display:none;
}

span.category-0,
span.category-1,
span.category-2,
span.category-3,
span.category-4,
span.category-5,
span.category-6,
span.category-7,
span.category-8,
span.category-9,
span.category-10,
span.category-11,
span.category-12 {
	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	padding:0px 4px 0px 4px;
	color:#ffffff;
	font-weight:400;
	text-shadow: 0px -1px 0px rgba(0,0,0,0.3);
}

span.category-0 { background:#afafaf; }
span.category-1 { background:#a0282f; }
span.category-2 { background:#0060c9; }
span.category-3 { background:#a6238d; }
span.category-4 { background:#3d8c4c; }
span.category-5 { background:#c4ab00; }
span.category-6 { background:#38009b; }


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

	<div id="debug-bar">
		<input type="button" value="Clear log" onclick="document.getElementById('debug-bar-output').innerHTML = ''"></input>
		<div id="debug-bar-output"></div>
	</div>
	
	<div id="filters-bar">
		<img src="logo.png">

		<div id="filters">
			<input type="checkbox" id="filter-1"><span class="category-1">Restaurants</span></input><br>
			<input type="checkbox" id="filter-2"><span class="category-2">Health & Beauty</span></input><br>
			<input type="checkbox" id="filter-3"><span class="category-3">Fitness</span></input><br>
			<input type="checkbox" id="filter-4"><span class="category-4">Retail & Services</span></input><br>
			<input type="checkbox" id="filter-5"><span class="category-5">Activities & Events</span></input><br>
			<input type="checkbox" id="filter-6"><span class="category-6">Vacations</span></input><br><br>
			<input type="checkbox" id="filter-show-new"><span class="small">Posted today</span></input><br>
			<input type="checkbox" id="filter-show-expired"><span class="small">Recently expired deals</small></input>
			
		</div>
	</div> 

	<div id="right-bar">
	<div id="left-image"></div>
	<div class="deal-content">
		<div id="deal-maintitle"></div>
		<div id="deal-subtitle"></div>


		<div class="coupon-text">
			<span id="category">TEXT</span><br>

			<div id="rating">
				<div class="clipwrapper">
				   <img id="yelp-stars" src="stars_map.png" alt="arrow" class="clip">
				</div>
				&nbsp;-&nbsp;<span id="deal-yelp_url"></span>
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
						<td colspan=3><span id="purchased"><span id="deal-num_purchased"></span> purchased&nbsp;&nbsp;-&nbsp;&nbsp;</span>Posted <span id="deal-discovered"></span></td>
					</tr>
					<tr>
						<td colspan=3><span id="deal-expires"></span></td>
					</tr>
				</tfoot>
			</table>
		</div>

		<div class="price-and-button">
			<div id="deal-price"></div>
			<div class="button"><button class="cupid-green" id="details-button">Details</button></div>
		</div>


		<div id="company" style="color:#666666; font-weight:700; text-align:center; float:right; margin:10px 0px 10px 0px; text-shadow: 0px 1px 0px #eeeeee;"></div>


	</div>
	</div>

	<!--
	<div id="left-bar">
	Search filters go here
	</div>
	-->

</body>
</html>
