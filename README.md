# LibreSurvey for YunoHost

[![Integration level](https://dash.yunohost.org/integration/libresurvey.svg)](https://ci-apps.yunohost.org/jenkins/job/libresurvey%20%28Community%29/lastBuild/consoleFull)  
[![Install LibreSurvey with YunoHost](https://install-app.yunohost.org/install-with-yunohost.png)](https://install-app.yunohost.org/?app=libresurvey)

> *This package allow you to install LibreSurvey quickly and simply on a YunoHost server.  
If you don't have YunoHost, please see [here](https://yunohost.org/#/install) to know how to install and enjoy it.*

## Overview
LibreSurvey is used to create advanced poll.

**Shipped version:** 2.62.5

**Categories:** Productivity, Poll

## Screenshots

![](https://www.limesurvey.org/images/news/LimeSurvey3Beta/generalsettings.PNG)

## Configuration

Before to run the install YunoHost ask you an admin user, you can use it to connecte you on https://your_libresurvey_url/admin/

## Documentation

* YunoHost documentation: There no other documentations, feel free to contribute.

## YunoHost specific features


* In private mode, only authorized YunoHost members can create poll, with the public mode, it's possible to create account to people with no YunoHost account. 
* SSO and LDAP are configured.
* Login secured by fail2ban

#### Multi-users support

Not supported.

#### Supported architectures

* x86-64b - [![Build Status](https://ci-apps.yunohost.org/jenkins/job/leed%20(Community)/badge/icon)](https://ci-apps.yunohost.org/jenkins/job/libresurvey%20(Community)/)
* ARMv8-A - [![Build Status](https://ci-apps.yunohost.org/jenkins/job/leed%20(Community)%20(%7EARM%7E)/badge/icon)](https://ci-apps.yunohost.org/jenkins/job/libresurvey%20(Community)%20(%7EARM%7E)/)

## Limitations

## Additionnal informations

## Links

 * Report a bug: https://github.com/YunoHost-Apps/libresurvey_ynh/issues
 * LibreSurvey is a fork of LimeSurvey https://www.limesurvey.org
 * YunoHost website: https://yunohost.org/

---

Developers infos
----------------

**Package by:** ljf

**Patches author:** Shnoulle

Please do your pull request to the [testing branch](https://github.com/YunoHost-Apps/libresurvey_ynh/tree/testing).

To try the testing branch, please proceed like that.
```
sudo yunohost app install https://github.com/YunoHost-Apps/libresurvey_ynh/tree/testing --verbose
or
sudo yunohost app upgrade leed -u https://github.com/YunoHost-Apps/libresurvey_ynh/tree/testing --verbose
```

