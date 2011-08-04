CREATE TABLE IF NOT EXISTS DealCities (
  deal_url varchar(255) NOT NULL,
  city_id INT NOT NULL,
  discovered DATETIME NOT NULL,
  PRIMARY KEY (deal_url, city_id)
)