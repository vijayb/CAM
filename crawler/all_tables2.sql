-- phpMyAdmin SQL Dump
-- version 3.3.10.3
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Aug 09, 2011 at 07:25 PM
-- Server version: 5.1.58
-- PHP Version: 5.2.9

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `mobdeali_production_deals`
--

-- --------------------------------------------------------

--
-- Table structure for table `Categories`
--

CREATE TABLE IF NOT EXISTS `Categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=52 ;

--
-- Dumping data for table `Categories`
--

INSERT INTO `Categories` (`id`, `name`) VALUES
(1, 'Restaurants'),
(2, 'Bar & Club'),
(3, 'Massage'),
(4, 'Facial'),
(5, 'Manicure & Pedicure'),
(6, 'Tanning'),
(7, 'Hair Salon'),
(8, 'Hair Removal'),
(9, 'Spa'),
(10, 'Teeth Whitening'),
(11, 'Eye & Vision'),
(12, 'Makeup'),
(13, 'Dental'),
(14, 'Chiropractic'),
(15, 'Dermatology'),
(16, 'Pilates'),
(17, 'Yoga'),
(18, 'Gym'),
(19, 'Boot Camp'),
(20, 'Martial Arts'),
(21, 'Fitness Classes'),
(22, 'Personal Training'),
(23, 'Men''s Clothing'),
(24, 'Women''s Clothing'),
(25, 'Food&Grocery'),
(26, 'Treats'),
(27, 'Home Cleaning'),
(28, 'Photography services'),
(29, 'Automotive Services'),
(30, 'Museums'),
(31, 'Wine Tasting'),
(32, 'City Tours'),
(33, 'Comedy Clubs'),
(34, 'Theater'),
(35, 'Concerts'),
(36, 'Life Skills Classes'),
(37, 'Golf'),
(38, 'Bowling'),
(39, 'Sporting Events'),
(40, 'Skydiving'),
(41, 'Skiing'),
(42, 'Dance Classes'),
(43, 'Outdoor Adventures'),
(44, 'Baby'),
(45, 'Kids'),
(46, 'College'),
(47, 'Bridal'),
(48, 'Pets'),
(49, 'Travel'),
(50, 'Gay'),
(51, 'Jewish');

-- --------------------------------------------------------

--
-- Table structure for table `Cities`
--

CREATE TABLE IF NOT EXISTS `Cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `latitude` float NOT NULL,
  `longitude` float NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=9 ;

--
-- Dumping data for table `Cities`
--

INSERT INTO `Cities` (`id`, `name`, `latitude`, `longitude`) VALUES
(1, 'National', 0, 0),
(2, 'Seattle', 47.3928, -122.607),
(3, 'Portland', 45.5235, -122.676),
(4, 'San Francisco', 37.775, -122.418),
(5, 'San Jose', 37.3394, -121.894),
(6, 'San Diego', 32.7153, -117.156),
(7, 'Silicon Valley', 37.4378, -122.178),
(8, 'Los Angeles', 34.0522, -118.243);

-- --------------------------------------------------------

--
-- Table structure for table `Companies`
--

CREATE TABLE IF NOT EXISTS `Companies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(60) NOT NULL,
  `url` varchar(40) NOT NULL,
  `address` varchar(200) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=5 ;

--
-- Dumping data for table `Companies`
--

INSERT INTO `Companies` (`id`, `name`, `url`, `address`, `phone`) VALUES
(1, 'Groupon', 'http://www.groupon.com/', 'Groupon Inc.  600 W Chicago Ave.  Suite 620  Chicago, IL 60654', '1 (877) 788-7858'),
(2, 'Living Social', 'http://www.livingsocial.com', '1445 New York Ave NW Suite 200 Washington, DC, 20005', '888.808.6676'),
(3, 'BuyWithMe', 'http://www.buywithme.com/', '345 Hudson Street, 13th floor New York, NY 10014', NULL),
(4, 'Tippr', 'http://tippr.com/', '517 Aloha St. Seattle, WA 98109', '866-347-0752');

-- --------------------------------------------------------

--
-- Table structure for table `HubCities`
--

CREATE TABLE IF NOT EXISTS `HubCities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hub_url` varchar(255) NOT NULL,
  `city_id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=34 ;

--
-- Dumping data for table `HubCities`
--

INSERT INTO `HubCities` (`id`, `hub_url`, `city_id`) VALUES
(1, 'http://www.buywithme.com/seattle/deals', 2),
(2, 'http://www.groupon.com/seattle/all', 2),
(3, 'http://tippr.com/seattle/', 2),
(4, 'http://www.groupon.com/portland/all', 3),
(5, 'http://tippr.com/portland/', 3),
(6, 'http://livingsocial.com/cities/27-seattle', 2),
(7, 'http://livingsocial.com/cities/31-portland', 3),
(9, 'http://livingsocial.com/cities/san-francisco', 4),
(10, 'http://livingsocial.com/cities/san-francisco-family-edition', 4),
(11, 'http://www.groupon.com/san-francisco/all', 4),
(12, 'http://www.buywithme.com/sanfrancisco/deals', 4),
(13, 'http://tippr.com/san-francisco/', 4),
(14, 'http://livingsocial.com/cities/seattle-family-edition', 2),
(15, 'http://livingsocial.com/cities/san-jose', 5),
(16, 'http://livingsocial.com/cities/san-jose-family-edition', 5),
(17, 'http://www.groupon.com/san-jose/all', 5),
(18, 'http://tippr.com/san-diego/', 6),
(19, 'http://www.buywithme.com/sandiego/deals', 6),
(20, 'http://www.groupon.com/san-diego/all', 6),
(21, 'http://livingsocial.com/cities/san-diego', 6),
(22, 'http://livingsocial.com/cities/san-diego-family-edition', 6),
(23, 'http://livingsocial.com/cities/san-diego-noco', 6),
(24, 'http://livingsocial.com/cities/san-diego-north-county-family-edition', 6),
(25, 'http://livingsocial.com/cities/sf-peninsula', 7),
(26, 'http://livingsocial.com/cities/sfpeninsula-families', 7),
(27, 'http://www.groupon.com/los-angeles/all', 8),
(28, 'http://livingsocial.com/cities/los-angeles', 8),
(29, 'http://livingsocial.com/cities/los-angeles-family-edition', 8),
(30, 'http://www.buywithme.com/la/deals', 8),
(31, 'http://tippr.com/los-angeles/', 8),
(32, 'http://livingsocial.com/cities/portland-family-edition', 3),
(33, 'http://livingsocial.com/cities/portland-eastside-vancouver-wa', 3);

-- --------------------------------------------------------

--
-- Table structure for table `Hubs`
--

CREATE TABLE IF NOT EXISTS `Hubs` (
  `url` varchar(255) NOT NULL,
  `company_id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `use_cookie` tinyint(1) NOT NULL DEFAULT '0',
  `recrawl_deal_urls` tinyint(1) NOT NULL DEFAULT '0',
  `hub_contains_deal` int(11) DEFAULT '0',
  PRIMARY KEY (`url`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `Hubs`
--

INSERT INTO `Hubs` (`url`, `company_id`, `category_id`, `use_cookie`, `recrawl_deal_urls`, `hub_contains_deal`) VALUES
('http://www.buywithme.com/seattle/deals', 3, 0, 0, 0, 0),
('http://www.groupon.com/seattle/all', 1, 0, 0, 1, 0),
('http://tippr.com/seattle/', 4, 0, 0, 1, 0),
('http://www.groupon.com/portland/all', 1, 0, 0, 1, 0),
('http://tippr.com/portland/', 4, 0, 0, 1, 0),
('http://livingsocial.com/cities/27-seattle', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/31-portland', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-francisco', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-francisco-family-edition', 2, 0, 1, 1, 1),
('http://www.groupon.com/san-francisco/all', 1, 0, 0, 1, 0),
('http://www.buywithme.com/sanfrancisco/deals', 3, 0, 0, 0, 0),
('http://tippr.com/san-francisco/', 4, 0, 0, 1, 0),
('http://livingsocial.com/cities/seattle-family-edition', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-jose', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-jose-family-edition', 2, 0, 1, 1, 1),
('http://www.groupon.com/san-jose/all', 1, 0, 0, 1, 0),
('http://tippr.com/san-diego/', 4, 0, 0, 1, 0),
('http://www.buywithme.com/sandiego/deals', 3, 0, 0, 0, 0),
('http://www.groupon.com/san-diego/all', 1, 0, 0, 1, 0),
('http://livingsocial.com/cities/san-diego', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-diego-family-edition', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-diego-noco', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/san-diego-north-county-family-edition', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/sf-peninsula', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/sfpeninsula-families', 2, 0, 1, 1, 1),
('http://www.groupon.com/los-angeles/all', 1, 0, 0, 1, 0),
('http://livingsocial.com/cities/los-angeles', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/los-angeles-family-edition', 2, 0, 1, 1, 1),
('http://www.buywithme.com/la/deals', 3, 0, 0, 0, 0),
('http://tippr.com/los-angeles/', 4, 0, 0, 1, 0),
('http://livingsocial.com/cities/portland-family-edition', 2, 0, 1, 1, 1),
('http://livingsocial.com/cities/portland-eastside-vancouver-wa', 2, 0, 1, 1, 1);
