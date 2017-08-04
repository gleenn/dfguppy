#!/bin/bash

# Install dependencies
sudo apt-get install -y build-essential git zip curl python-setuptools nginx
sudo easy_install pip
sudo pip install virtualenv

# Set up deployment credentials
mkdir -p ~/.ssh
cp keys/dfdeployment_rsa ~/.ssh/id_rsa
cp keys/dfdeployment_rsa.pub ~/.ssh/id_rsa.pub
git config --global user.name "DiscoFish Deployment"
git config --global user.email "<>"

# Make sure SSH does not ask confirmation when first connecting
# to gitlab 
ssh -t -o "StrictHostKeyChecking no" git@gitlab.com

# Install dfaprs
cd ~
git clone git@gitlab.com:discofish/dfaprs.git
cd dfaprs
make all 
sudo make install
sudo mkdir -p /var/opt/dfaprs
sudo chmod -R a+r /var/opt/dfaprs 
sudo echo 'description "APRS TNC for DiscoFish WTF"

	start on runlevel [2345]
	stop on runlevel [!2345]

	expect fork

	respawn
	respawn limit 5 5

	script
	    export HOME=/root
	    chdir $HOME
	    exec /usr/local/bin/dfaprs --source="serial:///dev/ttyUSB*" -t file:///var/opt/dfaprs/beacons.json 2>&1 | logger -t dfaprs &
	    echo $$ > /var/run/dfaprs.pid
	end script

	post-start script
	end script

	pre-start script
	        echo Starting dfaprs
	end script

	pre-stop script
	        echo Stopping dfaprs
	end script
' > /etc/init/dfaprs.conf
sudo initctl reload-configuration
sudo service dfaprs start || echo "WARNING: Could't start the service. If it happens in Docker test, this is normal, otherwise you want to investigate"

# Set up Guppy wtf
sudo mkdir -p /opt/dfwtf/www
sudo cp ~/dfguppy/wtf/* /opt/dfwtf/www/
sudo chmod -R a+r /opt/dfwtf/www 
sudo echo 'server {
    listen       8091;
    server_name  localhost 128.0.0.1;

    location / {
        alias /opt/dfwtf/www/;
    }

    location /mapdata/ {
        alias /var/opt/dfaprs/;
        index beacons.json;
        add_header Access-Control-Allow-Origin  *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    }
}
' > /etc/nginx/sites-enabled/guppywtf
sudo service nginx start



