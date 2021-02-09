# Docker Leantime
[![Docker Image Version (latest by date)](https://img.shields.io/docker/v/nicholaswilde/leantime)](https://hub.docker.com/r/nicholaswilde/leantime)
[![Docker Pulls](https://img.shields.io/docker/pulls/nicholaswilde/leantime)](https://hub.docker.com/r/nicholaswilde/leantime)
[![GitHub](https://img.shields.io/github/license/nicholaswilde/docker-leantime)](./LICENSE)
[![ci](https://github.com/nicholaswilde/docker-leantime/workflows/ci/badge.svg)](https://github.com/nicholaswilde/docker-leantime/actions?query=workflow%3Aci)
[![lint](https://github.com/nicholaswilde/docker-leantime/workflows/lint/badge.svg?branch=main)](https://github.com/nicholaswilde/docker-leantime/actions?query=workflow%3Alint)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

A multi-architecture image of [Leantime](https://leantime.io/)

## Dependencies

* mysql

## Usage

### docker-compose

```yaml
---
version: '3.3'
services:
  db:
    image: mysql:5.7
    container_name: mysql_leantime
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: '321.qwerty'
      MYSQL_DATABASE: 'leantime'
      MYSQL_USER: 'admin'
      MYSQL_PASSWORD: '321.qwerty'
    ports:
      - "3306:3306"
    command: --character-set-server=utf8 --collation-server=utf8_unicode_ci
  web:
    image: nicholaswilde/leantime:2.1.5-ls1
    container_name: leantime
    environment:
      TZ: 'America/Chicago'
      LEAN_DB_HOST: 'mysql_leantime'
      LEAN_DB_USER: 'admin'
      LEAN_DB_PASSWORD: '321.qwerty'
      LEAN_DB_DATABASE: 'leantime'
    ports:
      - "9000:9000"
      - "80:80"
    depends_on:
      - db
volumes:
  db_data: {}
```

### docker cli

```bash
$ docker run -d \
  --name=leantime \
  -e TZ=America/Los_Angeles `# optional` \
  -e LEAN_DB_HOST='mysql_leantime' \
  -e LEAN_DB_USER='admin' \
  -e LEAN_DB_PASSWORD='321.qwerty' \
  -e LEAN_DB_DATABASE='leantime' \
  -p 3000:3000 \
  --restart unless-stopped \
  nicholaswilde/leantime
```

### docker-compose

See [docker-compose.yaml](./docker-compose.yaml).

## Development

See [Wiki](https://github.com/nicholaswilde/docker-template/wiki/Development).

## Troubleshooting

See [Wiki](https://github.com/nicholaswilde/docker-template/wiki/Troubleshooting).

## Pre-commit hook

If you want to automatically generate `README.md` files with a pre-commit hook, make sure you
[install the pre-commit binary](https://pre-commit.com/#install), and add a [.pre-commit-config.yaml file](./.pre-commit-config.yaml)
to your project. Then run:

```bash
pre-commit install
pre-commit install-hooks
```
Currently, this only works on `amd64` systems.

## License

[Apache 2.0 License](./LICENSE)

## Author
This project was started in 2020 by [Nicholas Wilde](https://github.com/nicholaswilde/).
