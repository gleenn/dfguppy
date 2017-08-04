FROM ubuntu:14.04

# Install the same packages as we do in install.sh so that they get cached by Docker
RUN apt-get update 
RUN apt-get install -y build-essential git zip curl python-setuptools nginx
RUN easy_install pip
RUN pip install virtualenv

WORKDIR /root
ADD . dfguppy
RUN cd dfguppy && ./install.sh
RUN sed -i -E 's/server \{/server \{\n   access_log \/dev\/stderr;\n/' /etc/nginx/sites-enabled/guppywtf
CMD /bin/bash
