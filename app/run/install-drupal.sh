#/bin/bash

# This fixes a bug
# See https://github.com/drush-ops/drush/issues/3456
rm -rf  /var/www/drupal/drush

# Install Drupal
/var/www/.composer/vendor/bin/drush site-install standard -y --root=/var/www/drupal/web --db-url='mysql://root:root@db:3306/drupal' --account-name='admin' --account-pass='password' --site-name='drupal-ethereum' --account-mail='email@donkeymedia.eu' --site-mail='email@donkeymedia.eu' --notify='global'
cd /var/www/drupal/web && /var/www/.composer/vendor/bin/drush cr
exec "$@"
