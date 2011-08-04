CREATE TABLE IF NOT EXISTS `Cities` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `latitude` FLOAT NOT NULL,
  `longitude` FLOAT NOT NULL,
  PRIMARY KEY (`id`)
)