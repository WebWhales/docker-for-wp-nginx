# Updating the docker-for-wp-nginx images

## Building the "latest" tag

* Check out the `master` branch
* Run: `docker build --no-cache -t webwhales/for-wp-nginx:latest .`
* Run: `docker push webwhales/for-wp-nginx:latest`

## Building a specific tag

*Replace [tag] with an actual tag, like `php8.1-fpm`*

* Check out the branch corresponding with the tag, like `php8.1-fpm` 
* Run: `docker build --no-cache -t webwhales/for-wp-nginx:[tag] .`
* Run: `docker push webwhales/for-wp-nginx:[tag]`
