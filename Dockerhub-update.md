**Tag/update the Docker image**

```bash
export DOCKER_ID_USER="digitaldonkey"
docker login
docker tag php-with-composer $DOCKER_ID_USER/docker-drupal-ethereum
docker push $DOCKER_ID_USER/docker-drupal-ethereum
```
