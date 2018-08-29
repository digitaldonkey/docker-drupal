#/bin/bash

BUILD_ENVIRONMENT=$(cat /var/www/drupal/.build-env)
echo "### USING BUILD_ENVIRONMENT:  ${BUILD_ENVIRONMENT}"


# This fixes a bug
# See https://github.com/drush-ops/drush/issues/3456
rm -rf  /var/www/drupal/drush

# Install Drupal

# echo "Environment variables"
# env

# Wait for DB to be ready.
while ! mysqladmin ping -h"${MYSQL_HOSTNAME}" --silent; do
    sleep 1
done


echo "## Drupal site install ##"

echo "/var/www/drupal/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url=\"mysql://root:${MYSQL_ROOT_PASSWORD}@${MYSQL_HOSTNAME}:${MYSQL_PORT}/${MYSQL_DATABASE}\" --account-name=\"${DRUPAL_ACCOUNT_NAME}\" --account-pass=\"${DRUPAL_ACCOUNT_PASS}\" --site-name=\"${DRUPAL_SITE_NAME}\" --account-mail=\"${DRUPAL_ACCOUNT_MAIL}\" --site-mail=\"${DRUPAL_SITE_MAIL}\" --notify=\"global\""
su drupal -c '/var/www/drupal/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url="mysql://root:${MYSQL_ROOT_PASSWORD}@${MYSQL_HOSTNAME}:${MYSQL_PORT}/${MYSQL_DATABASE}" --account-name="${DRUPAL_ACCOUNT_NAME}" --account-pass="${DRUPAL_ACCOUNT_PASS}" --site-name="${DRUPAL_SITE_NAME}" --account-mail="${DRUPAL_ACCOUNT_MAIL}" --site-mail="${DRUPAL_SITE_MAIL}" --notify="global"'

cd /var/www/drupal/web && /var/www/drupal/vendor/bin/drush cr


# Load default_config into sync folder & reset config.
SYNC_DIR="/var/www/drupal/config/${BUILD_ENVIRONMENT}/default_config"
IMPORT_FILES=`ls -1 ${SYNC_DIR}/*.yml 2>/dev/null | wc -l`
if [ $IMPORT_FILES != 0 ]
then
    echo "### Found config in ${SYNC_DIR}"
    # Import config
    cd /var/www/drupal/
    su drupal -c "/var/www/drupal/vendor/bin/drupal \
     --no-interaction \
     --root=/var/www/drupal/web config:import \
     --directory=${SYNC_DIR}"
fi

# Fix sync permissions.
chown -R drupal:www-data /var/www/drupal/config
chmod 775 /var/www/drupal/config

su drupal -c 'cd /var/www/drupal/web && /var/www/drupal/vendor/bin/drush cr'

exec "$@"
