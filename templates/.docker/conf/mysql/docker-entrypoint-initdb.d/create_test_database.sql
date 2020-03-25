CREATE DATABASE IF NOT EXISTS `wp_db`;
GRANT ALL ON `wp_db`.* TO 'wp_db_user'@'%';

CREATE DATABASE IF NOT EXISTS `wp_db_unittest`;
GRANT ALL ON `wp_db_unittest`.* TO 'wp_db_user'@'%';