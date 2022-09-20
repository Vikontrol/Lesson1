#! /bin/bash

### Install
apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx-full mc
echo "<h2>Nixys</h2>" > /var/www/html/index.html
sudo service nginx start