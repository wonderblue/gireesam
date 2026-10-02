CREATE TABLE IF NOT EXISTS `game_profiles` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `display_name` varchar(96) NOT NULL DEFAULT '',
  `highest_stage` smallint unsigned NOT NULL DEFAULT 0,
  `total_coins` int unsigned NOT NULL DEFAULT 0,
  `reputation` smallint NOT NULL DEFAULT 52,
  `best_score` int unsigned NOT NULL DEFAULT 0,
  `best_duration_ms` int unsigned DEFAULT NULL,
  `tutorial_version` int unsigned NOT NULL DEFAULT 0,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `game_profiles_user_id_unique` (`user_id`),
  KEY `game_profiles_updated_at_idx` (`updated_at`)
);

CREATE TABLE IF NOT EXISTS `game_run_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `run_id` varchar(100) NOT NULL,
  `stage` varchar(80) NOT NULL,
  `outcome` varchar(16) NOT NULL,
  `score` int unsigned NOT NULL DEFAULT 0,
  `duration_ms` int unsigned NOT NULL DEFAULT 0,
  `recorded_at` bigint unsigned NOT NULL DEFAULT 0,
  `eligible` boolean NOT NULL DEFAULT false,
  `configuration` varchar(128) NOT NULL DEFAULT '',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `game_run_records_owner_run_unique` (`user_id`, `run_id`),
  KEY `game_run_records_owner_created_idx` (`user_id`, `created_at`, `id`)
);
