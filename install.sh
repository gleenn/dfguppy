#!/bin/bash

set -xe

if [ $# -ge 1 ] && [ "$1" == "--skip-deps" ] ; then
    echo "Skipping dependencies"
    shift
else
    echo "Installing dependencies"
    sudo apt-get install -y build-essential git make zip curl python-setuptools nginx
    sudo easy_install pip
    sudo pip install virtualenv
fi

echo "Setting up deployment credentials"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

cp keys/dfdeployment_rsa ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

cp keys/dfdeployment_rsa.pub ~/.ssh/id_rsa.pub

git config --global user.name "DiscoFish Deployment"
git config --global user.email "<>"

cd ~
if [ ! -d dfaprs ] ; then
    echo "Downloading dfaprs from gitlab"
    echo "Making sure SSH does not ask confirmation when first connecting to gitlab" 
    ssh -t -o "StrictHostKeyChecking no" git@gitlab.com || true
    git clone git@gitlab.com:discofish/dfaprs.git
else
    echo "dfaprs already cloned, pulling"
    cd dfaprs
    git pull
fi

if [ $# -ge 1 ] && [ "$1" == "--skip-make" ] ; then
    echo "Skipping dfaprs make"
else
    echo "Installing dfaprs"
    cd dfaprs
    make all 
    sudo make install
    sudo mkdir -p /var/opt/dfaprs
    sudo chmod -R 777 /var/opt/dfaprs 
fi

if which initctl > /dev/null ; then

echo 'description "APRS TNC for DiscoFish WTF"

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
' | sudo tee /etc/init/dfaprs.conf > /dev/null
sudo initctl reload-configuration
sudo service dfaprs start || echo "WARNING: Could't start the service. If it happens in Docker test, this is normal, otherwise you want to investigate"

elif which systemctl > /dev/null ; then

echo '[Unit]
Description=APRS TNC for DiscoFish WTF
After=network.target

[Service]
WorkingDirectory=/root
Environment="HOME=/root"
ExecStart=/usr/local/bin/dfaprs --source=serial:///dev/ttyUSB* -t file:///var/opt/dfaprs/beacons.json
Type=simple
PIDFile=/var/run/dfaprs.pid
Restart=on-failure
RestartSec=5
ExecStartPre=echo Starting dfaprs
ExecStopPost=echo Stopped dfaprs

[Install]
WantedBy=multi-user.target
' | sudo tee /etc/systemd/system/dfaprs.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable dfaprs.service

if ! ls /dev/ttyUSB* > /dev/null 2>&1 ; then
    echo "Could not find any files at /dev/ttyUSB*, is the radio plugged in?"
    exit 1
fi

sudo systemctl restart dfaprs.service &

else

echo "Unsupported system without initctl and systemctl"
exit 1

fi

echo "Setting up Guppy wtf"
sudo mkdir -p /opt/dfwtf/www
sudo cp ~/dfguppy/wtf/* /opt/dfwtf/www/
sudo chmod -R a+r /opt/dfwtf/www 
echo 'server {
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
' | sudo tee /etc/nginx/sites-enabled/guppywtf > /dev/null


if which initctl > /dev/null ; then
    sudo service nginx start
elif which systemctl > /dev/null ; then
    sudo systemctl enable nginx.service
    sudo systemctl restart nginx.service
fi

echo "Done"

