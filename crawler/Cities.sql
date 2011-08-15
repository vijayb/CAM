-- phpMyAdmin SQL Dump
-- version 3.3.10.3
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Aug 11, 2011 at 01:32 PM
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
-- Table structure for table `Cities`
--

CREATE TABLE IF NOT EXISTS `Cities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `latitude` float NOT NULL,
  `longitude` float NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=10 ;

--
-- Dumping data for table `Cities`
--

INSERT INTO `Cities` (`id`, `name`, `latitude`, `longitude`) VALUES
(1, 'Unknown', 0, 0),
(2, 'National', 0, 0),
(3, 'Seattle', 47.3928, -122.607),
(4, 'Portland', 45.5235, -122.676),
(5, 'San Francisco', 37.775, -122.418),
(6, 'San Jose', 37.3394, -121.894),
(7, 'San Diego', 32.7153, -117.156),
(8, 'Silicon Valley', 37.4378, -122.178),
(9, 'Los Angeles', 34.0522, -118.243),
(10, 'Tacoma', 47.2531, -122.443);
