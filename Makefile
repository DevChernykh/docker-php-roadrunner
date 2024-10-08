include .env

.DEFAULT_GOAL:=help
COMPOSE_FILE := ${DOCKER_COMPOSE_FILE}
COMPOSE_PREFIX_CMD := DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1
COMMAND ?= /bin/sh

.PHONY: build build-no-chache up down ps logs logs-1000 logs-follow \
	shell shell-root restart start stop rm images command command-root \
	network-create

build:					## Собрать приложение
	@echo -e "► \033[0;32mНачало сборки приложения\033[0;32m"
	@docker build -t ${BASE_PHP_IMAGE_TAG} -f ./docker/app/base.php.Dockerfile .
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} build --no-cache
	@echo -e "► \033[0;32mСборка приложения завершена\033[0;32m"

build-no-cache:			## Собрать приложение без кэша
	@echo -e "► \033[0;32mНачало сборки приложения (без кэша)\033[0;32m"
	@docker build -t ${BASE_PHP_IMAGE_TAG} -f ./docker/app/base.php.Dockerfile --no-cache .
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} build --no-cache
	@echo -e "► \033[0;32mСборка приложения завершена\033[0;32m"

up:						## Создать и запустить контейнеры
	@echo "► Создание и запуск контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} up -d
	@echo "► Контейнеры созданы и запущены"

down:					## Остановить и удалить контейнеры
	@echo "► Остановка и удаление контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} down
	@echo "► Контейнеры остановлены и удалены"

ps:						## Показать запущенные контейнеры
	@echo "► Список запущенных контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} ps

logs:					## Показать последние 100 записей логов
	@echo "Последние 100 записей логов"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} logs --tail 100

logs-1000:				## Показать последние 1000 записей логов
	@echo "► Последние 1000 записей логов"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} logs --tail 1000

logs-follow:			## Просмотр логов в реальном времени
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} logs --follow

shell:					## Подключиться к PHP контейнеру
	@echo "► Подключение к PHP контейнеру"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} exec app /bin/sh

shell-root:				## Подключиться к PHP контейнеру как root
	@echo -e "► Подключение к PHP контейнеру как root"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} exec -u root app /bin/sh

restart:				## Перезапустить контейнеры
	@echo "► Перезапуск контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} restart
	@echo "► Контейнеры перезапущены"

start:					## Запустить созданные контейнеры
	@echo "► Запуск контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} start
	@echo "► Контейнеры запущены"

stop:					## Остановить запущенные контейнеры
	@echo "► Остановка контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} stop
	@echo "► Контейнеры остановлены"

images:					## Список образов
	@echo "► Список образов"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} images

command:				## Выполнить команду в PHP контейнере (make command COMMAND=<команда>)
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} run --rm app ${COMMAND}

command-root:			## Выполнить контейнер в PHP контейнере как root
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} run --rm -u root app ${COMMAND}

rm:						## Удалить остановленные контейнеры
	@echo "► Удаление остановленных контейнеров"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} rm -f
	@echo "► Контейнеры удалены"

cache-clear:			## Сбросить кэш приложения
	@echo "► Очистка кэша"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} run --rm app ./bin/console cache:clear
	@echo "► Кэш сброшен"

network-create:			## Создать сеть (make network-create NETWORK_NAME=<название>)
	@echo "► Создание сети ${NETWORK_NAME}"
	@docker network create ${NETWORK_NAME}
	@echo "► Сеть ${NETWORK_NAME} создана"

test:
	@echo "► Запуск тестов"
	@${COMPOSE_PREFIX_CMD} docker compose -f ${COMPOSE_FILE} run --rm app ./vendor/bin/phpunit

help:					## Получить справку
	@echo -e "\nКоманды для упрощённой работы с Docker контейнерами"
	@echo -e "Для корректной работы необходим \033[0;32mDocker >= v27.3\033[0m"
	@awk 'BEGIN {FS = ":.*##"; printf "\nИспользование:\n  make \033[36m<команда>\033[0m ENV=<prod|dev> (default: dev)\n\nДоступные команды:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)