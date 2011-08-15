-- phpMyAdmin SQL Dump
-- version 3.3.10.3
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Aug 09, 2011 at 07:19 PM
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
-- Table structure for table `Addresses`
--

CREATE TABLE IF NOT EXISTS `Addresses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `deal_url` varchar(255) NOT NULL,
  `raw_address` varchar(255) NOT NULL,
  `street1` varchar(100) DEFAULT NULL,
  `street2` varchar(100) DEFAULT NULL,
  `suburb` varchar(50) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  `zipcode` varchar(20) DEFAULT NULL,
  `country` varchar(30) DEFAULT NULL,
  `latitude` float DEFAULT NULL,
  `longitude` float DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=439 ;

-- --------------------------------------------------------

--
-- Table structure for table `Categories`
--

CREATE TABLE IF NOT EXISTS `Categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=52 ;

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

-- --------------------------------------------------------

--
-- Table structure for table `CrawlerLock`
--

CREATE TABLE IF NOT EXISTS `CrawlerLock` (
  `id` int(11) NOT NULL,
  `hostname` varchar(100) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `DealCities`
--

CREATE TABLE IF NOT EXISTS `DealCities` (
  `deal_url` varchar(255) NOT NULL,
  `city_id` int(11) NOT NULL,
  `discovered` datetime NOT NULL,
  PRIMARY KEY (`deal_url`,`city_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `Deals`
--

CREATE TABLE IF NOT EXISTS `Deals` (
  `url` varchar(255) NOT NULL,
  `recrawl` tinyint(1) DEFAULT NULL,
  `use_cookie` tinyint(1) DEFAULT NULL,
  `discovered` datetime DEFAULT NULL,
  `last_inserted` datetime DEFAULT NULL,
  `company_id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `subtitle` varchar(255) DEFAULT NULL,
  `price` float DEFAULT NULL,
  `value` float DEFAULT NULL,
  `num_purchased` int(11) DEFAULT NULL,
  `text` text,
  `fine_print` text,
  `expired` tinyint(1) DEFAULT NULL,
  `deadline` datetime DEFAULT NULL,
  `expires` datetime DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address1_id` int(11) DEFAULT NULL,
  `address2_id` int(11) DEFAULT NULL,
  `address3_id` int(11) DEFAULT NULL,
  `address4_id` int(11) DEFAULT NULL,
  `address5_id` int(11) DEFAULT NULL,
  `address6_id` int(11) DEFAULT NULL,
  `address7_id` int(11) DEFAULT NULL,
  `address8_id` int(11) DEFAULT NULL,
  `address9_id` int(11) DEFAULT NULL,
  `address10_id` int(11) DEFAULT NULL,
  `yelp_rating` float DEFAULT NULL,
  `yelp_url` varchar(255) DEFAULT NULL,
  `verified` tinyint(1) NOT NULL DEFAULT '0',
  `yelp_categories` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`url`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

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

-- --------------------------------------------------------

--
-- Table structure for table `Images`
--

CREATE TABLE IF NOT EXISTS `Images` (
  `url` varchar(255) NOT NULL,
  `image` blob NOT NULL,
  PRIMARY KEY (`url`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
