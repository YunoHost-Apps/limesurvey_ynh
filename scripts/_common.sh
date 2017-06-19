#!/bin/bash

# App package root directory should be the parent folder
PKG_DIR=$(cd ../; pwd)

ynh_check_var () {
    test -n "$1" || ynh_die "$2"
}

ynh_exit_properly () {
    exit_code=$?
    if [ "$exit_code" -eq 0 ]; then
            exit 0
    fi
    trap '' EXIT
    set +eu
    echo -e "\e[91m \e[1m"
    err "$app script has encountered an error."

    if type -t CLEAN_SETUP > /dev/null; then
        CLEAN_SETUP
    fi

    ynh_die
}

# Activate signal capture
# Exit if a command fail, and if a variable is used unset.
# Capturing exit signals on shell script
#
# example: CLEAN_SETUP () {
#             # Clean residual file un remove by remove script
#          }
#          ynh_trap_on
ynh_trap_on () {
    set -eu
    trap ynh_exit_properly EXIT # Capturing exit signals on shell script
}

ynh_export () {
    local ynh_arg=""
    for var in $@;
    do
        ynh_arg=$(echo $var | awk '{print toupper($0)}')
        ynh_arg="YNH_APP_ARG_$ynh_arg"
        export $var=${!ynh_arg}
    done
}

# Check availability of a web path
#
# example: ynh_path_validity $domain$path
#
# usage: ynh_path_validity $domain_and_path
# | arg: domain_and_path - complete path to check
ynh_path_validity () {
    sudo yunohost app checkurl $1 -a $app
}

# Normalize the url path syntax
# Handle the slash at the beginning of path and its absence at ending
# Return a normalized url path
#
# example: url_path=$(ynh_normalize_url_path $url_path)
#          ynh_normalize_url_path example -> /example
#          ynh_normalize_url_path /example -> /example
#          ynh_normalize_url_path /example/ -> /example
#
# usage: ynh_normalize_url_path path_to_normalize
# | arg: url_path_to_normalize - URL path to normalize before using it
ynh_normalize_url_path () {
    path=$1
    test -n "$path" || ynh_die "ynh_normalize_url_path expect a URL path as first argument and received nothing."
    if [ "${path:0:1}" != "/" ]; then    # If the first character is not a /
        path="/$path"    # Add / at begin of path variable
    fi
    if [ "${path:${#path}-1}" == "/" ] && [ ${#path} -gt 1 ]; then    # If the last character is a / and that not the only character.
        path="${path:0:${#path}-1}" # Delete the last character
    fi
    echo $path
}

# Check the path doesn't exist
# usage: ynh_local_path_available PATH
ynh_local_path_available () {
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
        ynh_app_setting_set $app $var ${!var}
    done
}

# Create a database, an user and its password. Then store the password in the app's config
#
# User of database will be store in db_user's variable.
# Name of database will be store in db_name's variable.
# And password in db_pwd's variable.
#
# usage: ynh_mysql_generate_db user name
# | arg: user - Proprietary of the database
# | arg: name - Name of the database
ynh_mysql_generate_db () {
    export db_user=${1//[-.]/_}    # Mariadb doesn't support - and . in the name of databases. It will be replace by _
    export db_name=${2//[-.]/_}

    export db_pwd=$(ynh_string_random) # Generate a random password
    ynh_check_var "$db_pwd" "db_pwd empty"

    ynh_mysql_create_db "$db_name" "$db_user" "$db_pwd" # Create the database

    ynh_app_setting_set $app mysqlpwd $db_pwd   # Store the password in the app's config
}

# Execute a command as another user
# usage: ynh_exec_as USER COMMAND [ARG ...]
ynh_exec_as() {
  local USER=$1
  shift 1

  if [[ $USER = $(whoami) ]]; then
    eval "$@"
  else
    # use sudo twice to be root and be allowed to use another user
    sudo sudo -u "$USER" "$@"
  fi
}

# Get sources, setup it into dest directory and deploy patches
# Try to find locally the sources and download it if missing.
# Check the integrity with an hash program (default: sha256sum)
# Source hash and location are get from a "SOURCE_ID.src" file,
# by default the SOURCE_ID is "app".
# Patches should be located in a "patches" dir, they should be
# named like "SOURCE_ID-*.patch".
#
# example: ynh_setup_source "/var/www/limesurvey/" "limesurvey"
#
# usage: ynh_setup_source DEST_DIR [USER [SOURCE_ID]]

ynh_setup_source () {
    local DEST=$1
    local AS_USER=${2:-admin}
    local SOURCE_ID=${3:-app}
    local SOURCE_FILE="$YNH_APP_ID.tar.gz"
    local SUM_PRG="sha256sum"
    source ../$SOURCE_ID.src
    local LOCAL_SOURCE="/opt/yunohost-apps-src/$YNH_APP_ID/$SOURCE_FILE"

    if test -e $LOCAL_SOURCE; then
        cp $LOCAL_SOURCE $SOURCE_FILE
    else
        wget -nv $SOURCE_URL -O $SOURCE_FILE
    fi
    echo "$SOURCE_SUM $SOURCE_FILE" |$SUM_PRG -c --status \
        || ynh_die "Corrupt source"

    sudo mkdir -p "$DEST"
    sudo chown $AS_USER: "$DEST"
    if [ "$(echo ${SOURCE_FILE##*.})" == "gz" ]; then
        ynh_exec_as "$AS_USER" tar xf $SOURCE_FILE -C "$DEST" --strip-components 1
    elif [ "$(echo ${SOURCE_FILE##*.})" == "bz2" ]; then
        ynh_exec_as "$AS_USER" tar xjf $SOURCE_FILE -C "$DEST" --strip-components 1
    elif [ "$(echo ${SOURCE_FILE##*.})" == "zip" ]; then
        mkdir -p "/tmp/$SOURCE_FILE"
        ynh_exec_as "$AS_USER" unzip -q $SOURCE_FILE -d "/tmp/$SOURCE_FILE"
        ynh_exec_as "$AS_USER" mv "/tmp/$SOURCE_FILE"/./. "$DEST"
        rmdir "$/tmp/$SOURCE_FILE"
    else
        false
    fi

    # Apply patches
    if [ $(find ${PKG_DIR}/patches/ -type f -name "$SOURCE_ID-*.patch"  | wc -l) ]; then
        (cd "$DEST" \
        && for p in ${PKG_DIR}/patches/$SOURCE_ID-*.patch; do \
            ynh_exec_as "$AS_USER" patch -p1 < $p; done) \
            || ynh_die "Unable to apply patches"

    fi

    # Apply persistent modules (upgrade only)
    ynh_restore_persistent modules

    # Apply persistent data (upgrade only)
    ynh_restore_persistent data

}

# TODO support SOURCE_ID
ynh_save_persistent () {
    local TYPE=$1
    local DIR=/tmp/ynh-persistent/$TYPE/$app/app
    sudo mkdir -p $DIR
    sudo touch $DIR/dir_names
    shift
    i=1
    for PERSISTENT_DIR in $@;
    do
        if [ -e $local_path/$PERSISTENT_DIR  ]; then
            sudo mv $local_path/$PERSISTENT_DIR $DIR/$i
            sudo su -c "echo -n '$PERSISTENT_DIR ' >> $DIR/dir_names"
            ((i++))
        fi
    done
}

# TODO support SOURCE_ID
ynh_restore_persistent () {
    local TYPE=$1
    local DIR=/tmp/ynh-persistent/$TYPE/$app/app
    shift
    if [ -d $DIR  ]; then
        i=1
        for PERSISTENT_DIR in $(cat $DIR/dir_names);
        do
            if [ "$TYPE" = "modules" ]; then
                for updated_subdir in $(ls $local_path/$PERSISTENT_DIR);
                do
                    sudo rm -Rf $DIR/$i/$updated_subdir
                done
            fi
            if [ -d $DIR/$i ]; then
                sudo mv $DIR/$i/* $local_path/$PERSISTENT_DIR/ 2> /dev/null || true
            else
                sudo mv $DIR/$i $local_path/$PERSISTENT_DIR 2> /dev/null || true
            fi
            ((i++))
        done
        sudo rm -Rf $DIR
    fi

}
ynh_mv_to_home () {
    local APP_PATH="/home/yunohost.app/$app/"
    local DATA_PATH="$1"
    sudo mkdir -p "$APP_PATH"
    sudo chown $app: "$APP_PATH"
    ynh_exec_as "$app" mv "$DATA_PATH" "$APP_PATH"
    ynh_exec_as "$app" ln -s "$APP_PATH$DATA_PATH" "$DATA_PATH"

}

ynh_set_default_perm () {
    local DIRECTORY=$1
    # Set permissions
    sudo chown -R $app:$app $DIRECTORY
    sudo chmod -R 664 $DIRECTORY
    sudo find $DIRECTORY -type d -print0 | xargs -0 sudo chmod 775 \
	    || echo "No file to modify"

}
ynh_sso_access () {
    ynh_app_setting_set $app unprotected_uris "/"

    if [[ $is_public -eq 0 ]]; then
        ynh_app_setting_set $app protected_uris "$1"
    fi
    sudo yunohost app ssowatconf
}

ynh_exit_if_up_to_date () {
    if [ "${version}" = "${last_version}" ]; then
        info "Up-to-date, nothing to do"
        exit 0
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

ynh_read_manifest () {
    if [ -f '../manifest.json' ] ; then
        ynh_read_json '../manifest.json' "$1"
    else
        ynh_read_json '../settings/manifest.json' "$1"
    fi
}

ynh_app_dependencies  (){
    export dependencies=$1
    export project_url=$(ynh_read_manifest 'url')
    export version=$(ynh_read_manifest 'version')
    export dep_app=${app/__/-}
    mkdir -p ../conf
    cat > ../conf/app-ynh-deps.control.j2 << EOF
Section: misc
Priority: optional
Homepage: {{ project_url }}
Standards-Version: 3.9.2

Package: {{ dep_app }}-ynh-deps
Version: {{ version }}
Depends: {{ dependencies }}
Architecture: all
Description: meta package for {{ app }} (YunoHost app) dependencies
 This meta-package is only responsible of installing its dependencies.
EOF

    ynh_configure app-ynh-deps.control ./$dep_app-ynh-deps.control
    ynh_package_install_from_equivs ./$dep_app-ynh-deps.control \
        || ynh_die "Unable to install dependencies"
}




# Create a system user
#
# usage: ynh_system_user_create user_name [home_dir]
# | arg: user_name - Name of the system user that will be create
# | arg: home_dir - Path of the home dir for the user. Usually the final path of the app. If this argument is omitted, the user will be created without home
ynh_system_user_create () {
    if ! ynh_system_user_exists "$1"    # Check if the user exists on the system
    then    # If the user doesn't exist
        if [ $# -ge 2 ]; then   # If a home dir is mentioned
            user_home_dir="-d $2"
        else
            user_home_dir="--no-create-home"
        fi
        sudo useradd $user_home_dir --system --user-group $1 --shell /usr/sbin/nologin || ynh_die "Unable to create $1 system account"
    fi
}

# Delete a system user
#
# usage: ynh_system_user_delete user_name
# | arg: user_name - Name of the system user that will be create
ynh_system_user_delete () {
    if ynh_system_user_exists "$1"  # Check if the user exists on the system
    then
        sudo userdel $1
    else
        echo "The user $1 was not found" >&2
    fi
}


ynh_configure () {
    local TEMPLATE=$1
    local DEST=$2
    type j2 2>/dev/null || sudo pip install j2cli
    j2 "${PKG_DIR}/conf/$TEMPLATE.j2" > "${PKG_DIR}/conf/$TEMPLATE"
    sudo cp "${PKG_DIR}/conf/$TEMPLATE" "$DEST"
}

ynh_configure_nginx () {
    ynh_configure nginx.conf /etc/nginx/conf.d/$domain.d/$app.conf
    sudo service nginx reload
}

ynh_configure_php_fpm () {
    finalphpconf=/etc/php5/fpm/pool.d/$app.conf
    ynh_configure php-fpm.conf /etc/php5/fpm/pool.d/$app.conf
    sudo chown root: $finalphpconf

    finalphpini=/etc/php5/fpm/conf.d/20-$app.ini
    sudo cp ../conf/php-fpm.ini $finalphpini
    sudo chown root: $finalphpini

    sudo service php5-fpm reload
}

# Find a free port and return it
#
# example: port=$(ynh_find_port 8080)
#
# usage: ynh_find_port begin_port
# | arg: begin_port - port to start to search
ynh_find_port () {
    port=$1
    test -n "$port" || ynh_die "The argument of ynh_find_port must be a valid port."
    while netcat -z 127.0.0.1 $port       # Check if the port is free
    do
        port=$((port+1))    # Else, pass to next port
    done
    echo $port
}


### REMOVE SCRIPT

# Remove a database if it exist and the associated user
#
# usage: ynh_mysql_remove_db user name
# | arg: user - Proprietary of the database
# | arg: name - Name of the database
ynh_mysql_remove_db () {
    if mysqlshow -u root -p$(sudo cat $MYSQL_ROOT_PWD_FILE) | grep -q "^| $2"; then # Check if the database exist
        ynh_mysql_drop_db $2    # Remove the database
        ynh_mysql_drop_user $1  # Remove the associated user to database
    else
        echo "Database $2 not found" >&2
    fi
}

ynh_rm_nginx_conf () {
    if [ -e "/etc/nginx/conf.d/$domain.d/$app.conf" ]; then
        sudo rm "/etc/nginx/conf.d/$domain.d/$app.conf"
        sudo service nginx reload
    fi
}

ynh_rm_php_fpm_conf () {
    if [ -e "/etc/php5/fpm/pool.d/$app.conf" ]; then
        sudo rm "/etc/php5/fpm/pool.d/$app.conf"
    fi
    if [ -e "/etc/php5/fpm/conf.d/20-$app.ini" ]; then
        sudo rm "/etc/php5/fpm/conf.d/20-$app.ini"
    fi
    sudo service php5-fpm reload
}

REMOVE_LOGROTATE_CONF () {
    if [ -e "/etc/logrotate.d/$app" ]; then
        sudo rm "/etc/logrotate.d/$app"
    fi
}

ynh_secure_rm () {
    [[ "/var/www /opt /home/yunohost.app" =~ $1 ]] \
        || (test -n "$1" && sudo rm -Rf $1 )
}


