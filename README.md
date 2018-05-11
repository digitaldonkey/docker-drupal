# Drupal Ethereum Docker

## Manual

Start Docker

```
  docker-machine start
  eval $(docker-machine env default)
```

# Build image

```
docker build -t drupal_ethereum .
```

# Start DB

```
docker run --name drupal_ethereum_db -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -d mariadb
```

# Run Image
```
docker run --rm \
   --name drupal_ethereum_zesty \
   -p 80:80 -p 2222:22 \
   -v `pwd`/app/modules:/var/www/drupal/web/modules/custom \
   -v `pwd`/app/themes:/var/www/drupal/web/themes/custom \
   -v `pwd`/app/profiles:/var/www/drupal/web/profiles/custom \
   -v `pwd`/app/config:/var/www/drupal/config \
   --link drupal_ethereum_db:mysql \
   -t drupal_ethereum_zesty
```

# Log-in

```
ssh root@dockerhost -p2222
ssh drupal@dockerhost -p2222
```
