#/bin/bash

# This fixes a bug
# See https://github.com/drush-ops/drush/issues/3456
rm -rf  /var/www/drupal/drush

# Install Drupal

echo "Drupal site install with Drush"
echo "/var/www/.composer/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url='mysql://root:${MYSQL_ROOT_PASSWORD}@${MYSQL_HOSTNAME}:${MYSQL_PORT}/drupal' --account-name='${DRUPAL_ACCOUNT_NAME}' --account-pass='${DRUPAL_ACCOUNT_PASS}' --site-name='${DRUPAL_SITE_NAME}' --account-mail='${DRUPAL_ACCOUNT_MAIL}' --site-mail='${DRUPAL_SITE_MAIL}' --notify='global'"
/var/www/.composer/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url="mysql://root:${MYSQL_ROOT_PASSWORD}@${MYSQL_HOSTNAME}:${MYSQL_PORT}/drupal" --account-name="${DRUPAL_ACCOUNT_NAME}" --account-pass="${DRUPAL_ACCOUNT_PASS}" --site-name="${DRUPAL_SITE_NAME}" --account-mail="${DRUPAL_ACCOUNT_MAIL}" --site-mail="${DRUPAL_SITE_MAIL}" --notify="global"

cd /var/www/drupal/web && /var/www/.composer/vendor/bin/drush cr

# /var/www/.composer/vendor/bin/drush config-import --root=/var/www/drupal/web --partial -y
exec "$@"
