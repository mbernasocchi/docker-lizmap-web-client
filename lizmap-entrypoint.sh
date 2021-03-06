#!/bin/sh

set -e
set -x

LIZMAP_USER=${LIZMAP_USER:-9001}

#function failenv () {
#    echo "Required variable $1 not defined"
#    exit 1
#}

# Check required configuration variables

# lizmapConfig.ini.php.dist

# Copy config files to mount point
cp -aR lizmap/var/config.dist/* lizmap/var/config
[ ! -f lizmap/var/config/lizmapConfig.ini.php ] && cp lizmap/var/config/lizmapConfig.ini.php.dist lizmap/var/config/lizmapConfig.ini.php
[ ! -f lizmap/var/config/localconfig.ini.php  ] && cp lizmap/var/config/localconfig.ini.php.dist  lizmap/var/config/localconfig.ini.php
[ ! -f lizmap/var/config/profiles.ini.php     ] && cp lizmap/var/config/profiles.ini.php.dist     lizmap/var/config/profiles.ini.php


# Copy static files
# Note: static files needs to be resolved by external web server
# We have to copy them on the host
if [ -e lizmap/www ]; then
    cp -aR lizmap/www.dist/* lizmap/www/
    chown -R $LIZMAP_USER:$LIZMAP_USER lizmap/www
else
    mv lizmap/www.dist lizmap/www
fi

# Set configuration variables

sed -i '/^hideSensitiveServicesProperties=/c\hideSensitiveServicesProperties=1' lizmap/var/config/lizmapConfig.ini.php
sed -i '/^rootRepositories=/c\rootRepositories="/srv/projects"'                 lizmap/var/config/lizmapConfig.ini.php

sed -i "/^wmsServerURL=/c\wmsServerURL=${LIZMAP_WMSSERVERURL}"       lizmap/var/config/lizmapConfig.ini.php
sed -i "/^cacheRedisHost=/c\cacheRedisHost=${LIZMAP_CACHEREDISHOST}" lizmap/var/config/lizmapConfig.ini.php

[ ! -z "$LIZMAP_CACHEREDISPORT" ]      && sed -i "/^cacheRedisPort=/c\cacheRedisPort=${LIZMAP_CACHEREDISPORT}"       lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHEEXPIRATION" ]     && sed -i "/^cacheExpiration=/c\cacheExpiration=${LIZMAP_CACHEEXPIRATION}"    lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_DEBUGMODE" ]           && sed -i "/^debugMode=/c\debugMode=${LIZMAP_DEBUGMODE}"                      lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHESTORAGETYPE" ]    && sed -i "/^cacheStorageType=/c\cacheStorageType=${LIZMAP_CACHESTORAGETYPE}" lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHEREDISDB" ]        && sed -i "/^cacheRedisDb=/c\cacheRedisDb=${LIZMAP_CACHEREDISDB}"             lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHEREDISKEYPREFIX" ] && sed -i "/^cacheRedisKeyPrefix=/c\cacheRedisKeyPrefix=${LIZMAP_CACHEREDISKEYPREFIX}"  lizmap/var/config/lizmapConfig.ini.php

# Update localconfig
update-config.php

# Set up Configuration  
php lizmap/install/installer.php

# Set owner/and group
sh lizmap/install/set_rights.sh $LIZMAP_USER $LIZMAP_USER

# Clean cache files in case we are 
# Restarting the container
sh lizmap/install/clean_vartmp.sh

# Create link to lizmap prefix
mkdir -p $(dirname $LIZMAP_HOME)
ln -sf /www/lizmap $LIZMAP_HOME

# Configure php-fpm
sed -i "/^user =/c\user = ${LIZMAP_USER}"   /usr/local/etc/php-fpm.d/www.conf
sed -i "/^group =/c\group = ${LIZMAP_USER}" /usr/local/etc/php-fpm.d/www.conf

exec docker-php-entrypoint $@

