#/bin/bash

# This fixes a bug
# See https://github.com/drush-ops/drush/issues/3456
rm -rf  /var/www/drupal/drush

# Install Drupal

# echo "Environment variables"
# env

echo "## Drupal site install ##"

echo "/var/www/drupal/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url=\"mysql://root:${MYSQL_ROOT_PASSWORD}@${MYSQL_HOSTNAME}:${MYSQL_PORT}/${MYSQL_DATABASE}\" --account-name=\"${DRUPAL_ACCOUNT_NAME}\" --account-pass=\"${DRUPAL_ACCOUNT_PASS}\" --site-name=\"${DRUPAL_SITE_NAME}\" --account-mail=\"${DRUPAL_ACCOUNT_MAIL}\" --site-mail=\"${DRUPAL_SITE_MAIL}\" --notify=\"global\""
su drupal -c '/var/www/drupal/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url="mysql://root:${MYSQL_ROOT_PASSWORD}@${MYSQL_HOSTNAME}:${MYSQL_PORT}/${MYSQL_DATABASE}" --account-name="${DRUPAL_ACCOUNT_NAME}" --account-pass="${DRUPAL_ACCOUNT_PASS}" --site-name="${DRUPAL_SITE_NAME}" --account-mail="${DRUPAL_ACCOUNT_MAIL}" --site-mail="${DRUPAL_SITE_MAIL}" --notify="global"'

cd /var/www/drupal/web && /var/www/drupal/vendor/bin/drush cr


# Load default_config into sync folder & reset config.
if test "$(ls -A /var/www/drupal/default_config)"; then
    echo "## Found config in /var/www/drupal/default_config ##"
     cp /var/www/drupal/default_config/*.yml /var/www/drupal/config/sync/
     chown -R drupal:www-data /var/www/drupal/config
    # Import config
    cd /var/www/drupal/
    su drupal -c '/var/www/drupal/vendor/bin/drupal \
     --no-interaction \
     --root=/var/www/drupal/web config:import \
     --directory=/var/www/drupal/config/sync'
fi

# Fix sync permissions.
chown -R drupal:www-data /var/www/drupal/config/sync/
chmod 775 /var/www/drupal/config/sync/

exec "$@"
