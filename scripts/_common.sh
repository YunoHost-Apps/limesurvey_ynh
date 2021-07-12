#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================
# App package root directory should be the parent folder
PKG_DIR=$(cd ../; pwd)

YNH_PHP_VERSION="7.3"

pkg_dependencies="php${YNH_PHP_VERSION}-cli php${YNH_PHP_VERSION}-imap python-pip php${YNH_PHP_VERSION}-gd php${YNH_PHP_VERSION}-ldap php${YNH_PHP_VERSION}-zip"

#=================================================
# SPECIFIC HELPERS
#=================================================
set_permissions () {

    ynh_set_default_perm $final_path
    find $final_path -type f -name "*.php" -print0 | xargs -0 chmod 400 \
	    || echo "No file to modify"
    #chown root: $final_path/application/config/config.php
    chmod -R u+w $final_path/tmp
    chmod -R u+w $final_path/upload
    chmod -R u+w $final_path/application/config/
}

#=================================================
# COMMON HELPERS
#=================================================

ynh_set_default_perm () {
    local DIRECTORY=$1
    # Set permissions
    chown -R $app:www-data $DIRECTORY
    chmod -R 440 $DIRECTORY
    find $DIRECTORY -type d -print0 | xargs -0 chmod 550 \
	    || echo "No file to modify"

}
ynh_check_var () {
    test -n "$1" || ynh_die "$2"
}

ynh_export () {
    local ynh_arg=""
    for var in $@;
    do
        ynh_arg=$(echo $var | awk '{print toupper($0)}')
        if [ "$var" == "path_url" ]; then
            ynh_arg="PATH"
        fi
        ynh_arg="YNH_APP_ARG_$ynh_arg"
        export $var=${!ynh_arg}
    done
}

# Check the path doesn't exist
# usage: ynh_final_path_available PATH
ynh_final_path_available () {
    if [ -e "$1" ]
    then
        ynh_die "This path '$1' already contains a folder"
    fi
}

# Save listed var in YunoHost app settings 
# usage: ynh_save_args VARNAME1 [VARNAME2 [...]]
ynh_save_args () {
    for var in $@;
    do
        local setting_var="$var"
        if [ "$var" == "path_url" ]; then
            setting_var="path"
        fi
        ynh_app_setting_set $app $setting_var ${!var}
    done
}



# usage: ynh_save_persistent MODE RELATIVE_PATH 
ynh_save_persistent () {
    local TYPE=$1
    local DIR=/tmp/ynh-persistent/$app
    set +u
    i=${#YNH_PERSISTENT_DIR[@]}
    i=${i:-0}
    set -u
    [ "$i" -eq "0" ] && ynh_secure_remove $DIR && mkdir -p $DIR
    if [ -e $final_path/$2  ]; then
        mv $final_path/$2 $DIR/$i
        YNH_PERSISTENT_MODE[$i]=$1
        YNH_PERSISTENT_DIR[$i]=$2
    fi
}

ynh_keep_if_no_upgrade () {
    for elt in $@;
    do
        ynh_save_persistent KEEP_IF_NO_UPGRADE $elt
    done
}
ynh_keep () {
    for elt in $@;
    do
        ynh_save_persistent KEEP $elt
    done
}
# usage: ynh_restore_persistent
ynh_restore_persistent () {
    local DIR=/tmp/ynh-persistent/$app
    if [ -d $DIR ]; then
        i=0
        for PERSISTENT_DIR in "${YNH_PERSISTENT_DIR[@]}";
        do
            if [ "${YNH_PERSISTENT_MODE[$i]}" = "KEEP_IF_NO_UPGRADE" ]; then
                if [ ! -e $final_path/$PERSISTENT_DIR ]; then
                    mv $DIR/$i $final_path/$PERSISTENT_DIR
                fi
            else
                if [ -e $final_path/$PERSISTENT_DIR ]; then
                    ynh_secure_remove $final_path/$PERSISTENT_DIR
                fi
                mv $DIR/$i $final_path/$PERSISTENT_DIR
            fi
            ((i+=1))
        done
        ynh_secure_remove $DIR
    fi

}
ynh_mv_to_home () {
    local APP_PATH="/home/yunohost.app/$app/"
    local DATA_PATH="$1"
    mkdir -p "$APP_PATH"
    chown $app: "$APP_PATH"
    ynh_exec_as "$app" mv "$DATA_PATH" "$APP_PATH"
    ynh_exec_as "$app" ln -s "$APP_PATH$DATA_PATH" "$DATA_PATH"

}

ynh_sso_access () {
    ynh_app_setting_set $app unprotected_uris "/"

    if [[ $is_public -eq 0 ]]; then
        ynh_app_setting_set $app protected_uris "$1"
    fi
    yunohost app ssowatconf
}

ynh_exit_if_up_to_date () {
    if [ "${version}" = "${last_version}" ]; then
        info "Up-to-date, nothing to do"
        ynh_die "Up-to-date, nothing to do" 0
    fi
}

log() {
  echo "${1}"
}

info() {
  log "[INFO] ${1}"
}

warn() {
  log "[WARN] ${1}"
}

err() {
  log "[ERR] ${1}"
}

to_logs() {

  # When yunohost --verbose or bash -x
  if $_ISVERBOSE; then
    cat
  else
    cat > /dev/null
  fi
}

ynh_read_json () {
    sudo python3 -c "import sys, json;print(json.load(open('$1'))['$2'])"
}



ynh_configure () {
    local TEMPLATE=$1
    local DEST=$2
    type j2 2>/dev/null || sudo pip install j2cli
    j2 "${PKG_DIR}/conf/$TEMPLATE.j2" > "${PKG_DIR}/conf/$TEMPLATE"
    sudo cp "${PKG_DIR}/conf/$TEMPLATE" "$DEST"
}


# Send an email to inform the administrator
#
# usage: ynh_send_readme_to_admin app_message [recipients]
# | arg: app_message - The message to send to the administrator.
# | arg: recipients - The recipients of this email. Use spaces to separate multiples recipients. - default: root
#	example: "root admin@domain"
#	If you give the name of a YunoHost user, ynh_send_readme_to_admin will find its email adress for you
#	example: "root admin@domain user1 user2"
ynh_send_readme_to_admin() {
	local app_message="${1:-...No specific information...}"
	local recipients="${2:-root}"

	# Retrieve the email of users
	find_mails () {
		local list_mails="$1"
		local mail
		local recipients=" "
		# Read each mail in argument
		for mail in $list_mails
		do
			# Keep root or a real email address as it is
			if [ "$mail" = "root" ] || echo "$mail" | grep --quiet "@"
			then
				recipients="$recipients $mail"
			else
				# But replace an user name without a domain after by its email
				if mail=$(ynh_user_get_info "$mail" "mail" 2> /dev/null)
				then
					recipients="$recipients $mail"
				fi
			fi
		done
		echo "$recipients"
	}
	recipients=$(find_mails "$recipients")

	local mail_subject="☁️🆈🅽🅷☁️: \`$app\` was just installed!"

	local mail_message="This is an automated message from your beloved YunoHost server.

Specific information for the application $app.

$app_message

---
Automatic diagnosis data from YunoHost

$(yunohost tools diagnosis | grep -B 100 "services:" | sed '/services:/d')"

	# Define binary to use for mail command
	if [ -e /usr/bin/bsd-mailx ]
	then
		local mail_bin=/usr/bin/bsd-mailx
	else
		local mail_bin=/usr/bin/mail.mailutils
	fi

	# Send the email to the recipients
	echo "$mail_message" | $mail_bin -a "Content-Type: text/plain; charset=UTF-8" -s "$mail_subject" "$recipients"
}
