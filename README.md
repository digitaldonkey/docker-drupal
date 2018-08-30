# Drupal Ethereum Docker

You can run three flavors by changing `BUILD_ENVIRONMENT`

* dev    - latest dev version from Guthub
* stable - branch 8.x from drupal.org
* example - latest dev version from Guthub with some Drupal config


## Start Docker

```
  docker-machine start
  eval $(docker-machine env default)
```

## Build and run

The single source of variables is the *.env* file.
Copy default.env and change your settings there.

```
cp default.env .env
```


Start up containers

```
docker-compose build
docker-compose up
```

After Drupal install finished visit [http://dockerhost:8888](http://dockerhost:8888) or [https://dockerhost:8889](https://dockerhost:8889).

**Note:** If you change `MYSQL_ROOT_PASSWORD` after first `docker-composer up` run you may need to recreate the Database server (`docker-compose rm -v`).

https://staxmanade.com/2016/05/how-to-get-environment-variables-passed-through-docker-compose-to-the-containers/

## Log-in

All passwords are set via *.env* file.

System accounts have no passwords. You need to change **app/ssh/authorized_keys** in order to log in.

```
ssh root@dockerhost -p2222
```

```
ssh drupal@dockerhost -p2222
```


## Troubleshoot

You may run into a *disk is full* error on `/usr/bin/composer install`, if a container doesn't shut down properly


```
The disk hosting /var/www/.composer is full, this may be the cause of the following exception
```

You can fix it with `docker images prune` and then rebuild images.

