PYTHON = python
TAG = datashaman/wifidog-auth-flask

tmuxp:
	tmuxp load .

serve:
	python serve.py

serve-production:
	gunicorn --reload -b '127.0.0.1:5000' 'app:create_app()'

db-reset:
	rm -rf data/local.db
	python manage.py bootstrap_instance

build-static:
	yarn
	gulp

docker-prepare: clean build-static db-reset

docker-build: docker-prepare
	docker build -t $(TAG) .

docker-push: db-reset
	docker push $(TAG)

docker-run:
	docker run --env-file .env -p 5000:5000 -i -t $(TAG)

docker-run-persistent:
	docker run --env-file .env -p 5000:5000 -v auth-data:/var/app/data -i -t $(TAG)

docker-prune-stopped:
	docker ps -a -q | xargs -r docker rm

docker-prune-untagged:
	docker images | grep '^<none>' | awk '{print $$3}' | xargs -r docker rmi

docker-prune: docker-prune-stopped docker-prune-untagged

browser-sync:
	browser-sync start --proxy http://127.0.0.1:5000 --files="app/**"

lint:
	pylint app

bootstrap-local: bootstrap-tests
	cp tests/tests.db data/local.db

bootstrap-tests:
	rm -rf tests/tests.db && touch tests/tests.db
	TESTING=true $(PYTHON) manage.py bootstrap_tests

watch:
	while inotifywait -e close_write -r ./app ./tests; do make test; done

test:
	TESTING=true $(PYTHON) -m unittest discover -s tests

coverage:
	TESTING=true coverage run --include='app/*' -m unittest discover -s tests
	coveralls

setup:
	sudo -H apt-get install python-pip virtualenvwrapper libjpeg-dev libpng-dev libffi-dev
	sudo -H yarn global add gulp yarn

development-install:
	pip install -r requirements.txt
	yarn
	gulp --dev

production-install:
	pip install -r requirements.txt
	yarn
	gulp

bootstrap:
	$(PYTHON) bootstrap.py

remove-db:
	rm -f local.db

reboot: remove-db bootstrap

clean:
	find . -name '*.pyc' -delete
	rm -rf app/static/*

graphs:
	$(PYTHON) app/graphs.py

dot:
	dot -Tpng -O app/graphs.dot && eog app/graphs.dot.png
