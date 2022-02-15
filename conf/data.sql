
UPDATE lime_plugins SET active=1 WHERE name="AuthLDAP";

INSERT INTO `lime_permissions` (`id`, `entity`, `entity_id`, `uid`, `permission`, `create_p`, `read_p`, `update_p`, `delete_p`, `import_p`, `export_p`) VALUES 
(2,'global',0,2,'auth_ldap',0,1,0,0,0,0),
(3,'global',0,2,'surveys',1,0,0,0,0,0);


INSERT INTO `lime_plugin_settings` (`id`, `plugin_id`, `model`, `model_id`, `key`, `value`) VALUES
(2, 5, NULL, NULL, 'server', '\"ldap:\\/\\/localhost\"'),
(3, 5, NULL, NULL, 'ldapport', '\"\"'),
(4, 5, NULL, NULL, 'ldapversion', '\"3\"'),
(5, 5, NULL, NULL, 'ldapoptreferrals', '\"1\"'),
(6, 5, NULL, NULL, 'ldaptls', '\"0\"'),
(7, 5, NULL, NULL, 'ldapmode', '\"searchandbind\"'),
(8, 5, NULL, NULL, 'userprefix', 'null'),
(9, 5, NULL, NULL, 'domainsuffix', 'null'),
(10, 5, NULL, NULL, 'searchuserattribute', '\"uid\"'),
(11, 5, NULL, NULL, 'usersearchbase', '\"ou=users,dc=yunohost,dc=org\"'),
(12, 5, NULL, NULL, 'extrauserfilter', '\"(&(objectClass=inetOrgPerson)(permission=cn=__APP__.admin,ou=permission,dc=yunohost,dc=org))\"'),
(13, 5, NULL, NULL, 'binddn', '\"\"'),
(14, 5, NULL, NULL, 'bindpwd', '\"\"'),
(15, 5, NULL, NULL, 'mailattribute', '\"mail\"'),
(16, 5, NULL, NULL, 'fullnameattribute', '\"displayName\"'),
(17, 5, NULL, NULL, 'is_default', '\"\"'),
(18, 5, NULL, NULL, 'autocreate', '\"1\"'),
(19, 5, NULL, NULL, 'automaticsurveycreation', '\"1\"'),
(20, 5, NULL, NULL, 'groupsearchbase', '\"\"'),
(21, 5, NULL, NULL, 'groupsearchfilter', '\"\"'),
(22, 5, NULL, NULL, 'allowInitialUser', '\"1\"');


#INSERT INTO `lime_plugin_settings` (`id`, `plugin_id`, `model`, `model_id`, `key`, `value`) VALUES
#(23, 7, NULL, NULL, 'strip_domain', 'null'),
#(24, 7, NULL, NULL, 'serverkey', '"REMOTE_USER"'),
#(25, 7,NULL,NULL,'is_default','\"1\"');

INSERT INTO `lime_settings_global` VALUES
('defaultlang','__LANGUAGE__'),
('AssetsVersion','30214');
