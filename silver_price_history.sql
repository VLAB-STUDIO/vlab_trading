CREATE TABLE IF NOT EXISTS `silver_price_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `timestamp` datetime DEFAULT current_timestamp(),
  `price` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=893 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;