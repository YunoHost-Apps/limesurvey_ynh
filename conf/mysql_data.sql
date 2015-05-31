INSERT INTO `prefix_plugins` (`id`, `name`, `active`) VALUES (1, 'Authdb', 1);
INSERT INTO `prefix_plugins` (`id`, `name`, `active`) VALUES (3, 'AuthLDAP', 1);
INSERT INTO `prefix_plugins` (`id`, `name`, `active`) VALUES (7, 'Authwebserver', 0);

INSERT INTO `prefix_permissions` (`id`, `entity`, `entity_id`, `uid`, `permission`, `create_p`, `read_p`, `update_p`, `delete_p`, `import_p`, `export_p`) VALUES (1, 'global', 0, 1, 'superadmin', 0, 1, 0, 0, 0, 0);
INSERT INTO `prefix_users` (`uid`, `users_name`, `password`, `full_name`, `parent_id`, `lang`, `email`, `htmleditormode`, `templateeditormode`, `questionselectormode`, `one_time_pw`, `dateformat`, `created`, `modified`) VALUES (1, 'yunoadmin', 0x35653838343839386461323830343731353164306535366638646336323932373733363033643064366161626264643632613131656637323164313534326438, 'Administrator', 0, 'fr', '', 'default', 'default', 'default', NULL, 1, '2014-07-11 22:51:35', NULL);

INSERT INTO `prefix_plugin_settings` (`id`, `plugin_id`, `model`, `model_id`, `key`, `value`) VALUES
(1, 3, NULL, NULL, 'server', '"localhost"'),
(2, 3, NULL, NULL, 'ldapport', '"389"'),
(3, 3, NULL, NULL, 'ldapversion', '"3"'),
(4, 3, NULL, NULL, 'ldapoptreferrals', '"1"'),
(5, 3, NULL, NULL, 'ldaptls', '"0"'),
(6, 3, NULL, NULL, 'ldapmode', '"searchandbind"'),
(7, 3, NULL, NULL, 'userprefix', 'null'),
(8, 3, NULL, NULL, 'domainsuffix', 'null'),
(9, 3, NULL, NULL, 'searchuserattribute', '"uid"'),
(10, 3, NULL, NULL, 'usersearchbase', '"ou=users,dc=yunohost,dc=org"'),
(11, 3, NULL, NULL, 'extrauserfilter', '""'),
(12, 3, NULL, NULL, 'binddn', '""'),
(13, 3, NULL, NULL, 'bindpwd', '""'),
(14, 3, NULL, NULL, 'is_default', '1');

INSERT INTO `prefix_plugin_settings` (`id`, `plugin_id`, `model`, `model_id`, `key`, `value`) VALUES
(15, 7, NULL, NULL, 'strip_domain', 'null'),
(16, 7, NULL, NULL, 'serverkey', '"REMOTE_USER"');
