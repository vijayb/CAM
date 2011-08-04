<?php
// Make a MySQL Connection



$con = mysql_connect("localhost", "mobdeali_sgm", "cheapass");

if (!$con)
   {
   die('Could not connect: ' . mysql_error());
   }

mysql_select_db("mobdeali_test_sanjay", $con) or die(mysql_error());

?>


<!doctype html>

<head>

<link href='http://fonts.googleapis.com/css?family=Lato:300,400,700,900,400italic&v2' rel='stylesheet' type='text/css'>

<!-- <link rel="stylesheet" type="text/css" href="style.css" /> -->

<title>Deals</title>


<style>

header, footer, aside, nav, article {
    display: block;
}

body {
	background:#ffffff;
	font-family: 'Lato', sans-serif;
	font-weight:400;
	font-size:90%;
	color:#000000;
	margin:auto;
	width:965px;
}

article {
	clear:both;
}

header {
	width:965px;
	margin:5px 0 10px 0;
}


aside {
	float:left;
	width:200px;
	background:#eeeeee;
	height:500px;
}

section {
	float:right;
	width:750px;
}

div.left-image {
	background:#e57c00;
	width:200px;
	height:220px;
	float:left;
	margin:0px 0px 15px 0px;
	overflow:hidden;
}

div.deal-content {
	background:#f4f4f4;
	width:520px;
	float:left;
	padding:10px 15px 10px 15px;
	margin:0px 0px 15px 0px;
	min-height:200px;
	height:auto !important;
   	height:200px;
}

div.coupon {
	margin: 10px 0 0 0;
	float:right;
	width:216px;
}

div.coupon-text {
	margin: 10px 0 0 0;
	float:left;
	width:300px;
}

div.price-and-button {
	float:right;
	width:216px;
	margin:5px 0 0 0;
}

div.price {
	float:left;
	font-weight:900;
	font-size:30px;
	color:#e57c00;
	line-height:0.8em;
	width:95px;
	text-align:center;
	margin:6px 0 0 0;
}

div.button {
	float:right;
}

h1, h2 {
	margin:0px;
	padding:0px;
	line-height:1.1;
}

h1 {
	font-weight:700;
	font-size:26px;
}

h2 {
	font-weight:300;
	font-size:20px;
	color:#666666;
}

span.category-dn {
	background:#3d8c4c;
	-webkit-border-radius:3px;
	-moz-border-radius:3px;
	padding:0px 4px 0px 4px;
	color:#ffffff;
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
	width: 120px;
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

</style>

</head>

<body>
    <header>
        <img src="logo.png">
    </header>

    <section>


<?php

$sql = "SELECT * FROM Deals";

$result = mysql_query($sql, $con);

if (!$result) {
	die('Error: ' . mysql_error());
}

$num = mysql_num_rows($result);



while ($row = mysql_fetch_assoc($result)) {

?>


		<article>
			<div class="left-image"><img src="<?php echo($row["image"]); ?>"></div>

			<div class="deal-content">

				<h1><?php echo($row["title"]); ?></h1>
				<h2><?php echo($row["subtitle"]); ?></h2>

				<div class="coupon-text">
					<span class="category-dn">Dining & Nightlife</span> - Indian restaurants<br>

					<div class="rating">
						<div style="float:left">
							<div class="clipwrapper">
							   <!-- <img src="stars_map.png" alt="arrow" class="clip yelp-<?php echo($row["yelp_rating"]); ?>" /> -->
							   <img src="stars_map.png" alt="arrow" class="clip yelp-45" />
							</div>
							&nbsp;-&nbsp;<a href="#">Yelp</a>
						</div>
					</div>

					<div style="float:left; clear:both; margin:5px 0 0 0;">
					Queen Anne<br>
					123 Main St - <a href="#">Google map</a><br>
					Seattle, WA 98109<br><br>
					<span style="color:#666666">from Groupon</span>
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
								<td><?php print("$" . $row["value"]); ?></td><td><?php echo($row["savings"] . "%"); ?></td><td><?php echo("$" . $row["price"]); ?></td>
							</tr>
						</tbody>

						<tfoot>
							<tr>
								<td colspan=3><?php echo($row["num_purchased"]); ?> purchased</td>
							</tr>
							<tr>
								<td colspan=3>Expires <?php echo($row["expiry_time"]); ?></td>
							</tr>
						</tfoot>
					</table>
				</div>

				<div class="price-and-button">
					<div class="price"><?php echo("$" . $row["price"]); ?></div>
					<div class="button"><button class="cupid-green">Details</button></div>
				</div>
			</div>
		</article>
<?php

}

?>

    </section>

    <aside>
    </aside>

    <footer>
        <!-- Footer -->
    </footer>

</body>
</html>
