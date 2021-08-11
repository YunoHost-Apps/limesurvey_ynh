INSERT INTO `lime_plugins` (`id`, `name`, `active`) VALUES 
(2,'AuditLog',0),
(3,'oldUrlCompat',0),
(4,'ExportR',0),
(5,'Authwebserver',1),
(6,'extendedStartPage',0),
(7,'ExportSTATAxml',0),
(8,'QuickMenu',0),
(9,'AuthLDAP',0);

INSERT INTO `lime_permissions` (`id`, `entity`, `entity_id`, `uid`, `permission`, `create_p`, `read_p`, `update_p`, `delete_p`, `import_p`, `export_p`) VALUES 
(2,'global',0,2,'auth_ldap',0,1,0,0,0,0),
(3,'global',0,2,'surveys',1,0,0,0,0,0);


INSERT INTO `lime_plugin_settings` (`id`, `plugin_id`, `model`, `model_id`, `key`, `value`) VALUES 
(1,9,NULL,NULL,'server','\"ldap:\\/\\/localhost\"'),
(2,9,NULL,NULL,'ldapport','\"\"'),
(3,9,NULL,NULL,'ldapversion','\"3\"'),
(4,9,NULL,NULL,'ldapoptreferrals','\"1\"'),
(5,9,NULL,NULL,'ldaptls','\"0\"'),
(6,9,NULL,NULL,'ldapmode','\"searchandbind\"'),
(7,9,NULL,NULL,'userprefix','null'),
(8,9,NULL,NULL,'domainsuffix','null'),
(9,9,NULL,NULL,'searchuserattribute','\"uid\"'),
(10,9,NULL,NULL,'usersearchbase','\"ou=users,dc=yunohost,dc=org\"'),
(11,9,NULL,NULL,'extrauserfilter','\"(objectClass=inetOrgPerson)\"'),
(12,9,NULL,NULL,'binddn','\"\"'),
(13,9,NULL,NULL,'bindpwd','\"\"'),
(14,9,NULL,NULL,'mailattribute','\"mail\"'),
(15,9,NULL,NULL,'fullnameattribute','\"displayName\"'),
(16,9,NULL,NULL,'is_default','\"0\"'),
(17,9,NULL,NULL,'autocreate','\"1\"'),
(18,9,NULL,NULL,'automaticsurveycreation','\"1\"');

INSERT INTO `lime_plugin_settings` (`id`, `plugin_id`, `model`, `model_id`, `key`, `value`) VALUES
(19, 5, NULL, NULL, 'strip_domain', 'null'),
(20, 5, NULL, NULL, 'serverkey', '"REMOTE_USER"'),
(21, 5,NULL,NULL,'is_default','\"1\"');

INSERT INTO `lime_settings_global` VALUES ('defaultlang','__LANGUAGE__'),('AssetsVersion','2620');

{% if __IS_PUBLIC__ == "1" %}
UPDATE `lime_plugin_settings` SET value='\"0\"' WHERE `id`=21;
{% endif %} 
