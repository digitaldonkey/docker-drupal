# Drupal Ethereum Docker

## Start Docker

```
  docker-machine start
  eval $(docker-machine env default)
```

## Build and run

```
docker-compose build
docker-compose up
```

## Log-in

Root Password is "root"

```
ssh root@dockerhost -p2222
```

Drupal system user has the Password "drupal"

```
ssh drupal@dockerhost -p2222
```

Drupal web password is is set via *.env* file. 
See default.env

```
DRUPAL_ACCOUNT_NAME=admin
DRUPAL_ACCOUNT_PASS=password
```
