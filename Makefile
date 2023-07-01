.PHONY: act

act:
	act --secret-file github.secrets --env-file .env

.PHONY: build

build: 
	docker build -f php/Dockerfile -t smirik/smirik-php:8.2 .

build-dev: 
	docker build -f php/Dockerfile --target core_php_dev -t smirik/smirik-php-dev:8.2 .
