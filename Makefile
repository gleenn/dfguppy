.PHONY: all install test

all:

install: 
	./install.sh

test:
	docker-compose build --force-rm

run:
	docker-compose up --build
