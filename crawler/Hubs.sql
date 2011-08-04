CREATE TABLE IF NOT EXISTS `Hubs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) NOT NULL,
  `company_id` int(11) NOT NULL,
  `city_id` int(11) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `use_cookie` tinyint(1) NOT NULL DEFAULT '0',
  `recrawl_deal_urls` tinyint(1) NOT NULL DEFAULT '0',
  `hub_contains_deal` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=14 ;

--
-- Dumping data for table `Hubs`
--

INSERT INTO `Hubs` (`id`, `url`, `company_id`, `city_id`, `category_id`, `use_cookie`, `recrawl_deal_urls`, `hub_contains_deal`) VALUES
(6, 'http://www.buywithme.com/seattle/deals', 3, 1, 0, 0, 0, 0),
(5, 'http://www.groupon.com/seattle/all', 1, 1, 0, 0, 1, 0),
(7, 'http://tippr.com/seattle/', 4, 1, 0, 0, 0, 0),
(8, 'http://www.groupon.com/portland/all', 1, 2, 0, 0, 1, 0),
(9, 'http://tippr.com/portland/', 4, 2, 0, 0, 0, 0),
(10, 'http://livingsocial.com/cities/27-seattle', 2, 1, 0, 1, 1, 1),
(11, 'http://livingsocial.com/cities/31-portland', 2, 2, 0, 1, 1, 1);
