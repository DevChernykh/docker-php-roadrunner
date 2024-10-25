<a id="readme-top"></a>

<div align="center">
    <h1>Docker шаблон для PHP с RoadRunner</h1>

<p>С использованием и наличием:</p>

[![Docker][Docker.com]][Docker-url]
[![PHP][PHP.net]][PHP-url]
[![Symfony][Symfony.com]][Symfony-url]
[![RoadRunner][RoadRunner.com]][RoadRunner-url]
[![Xdebug][Xdebug.org]][Xdebug-url]
[![PostgreSQL][PostgreSQL.org]][PostgreSQL-url]
</div>

## О шаблоне

Этот шаблон предназначен для быстрого развёртывания простого PHP приложения с базой данных.
По умолчанию, шаблон настроен для работы с фреймворком Symfony.

При необходимости, можно доработать конфигурации под свои потребности:

1. добавить PHP расширения;
2. установить различные компоненты в контейнер;
3. добавить новые контейнеры или изменить существующие;
4. и другое, что только пожелаете.

Дополнительно, в PHP приложении уже установлены и настроены:
1. **php-cs-fixer** - для введения общего кодстайла
2. **phpstan** - проверка качества кода
3. **phpunit** - тестирование

<p align="right">(<a href="#readme-top">Полетели на верх!</a>)</p>

## Начало работы

### Для работы необходимы

* Git
* Docker (версия >= 27)
* CMake

### Установка

1. Клонировать проект
    ```bash
   git clone https://github.com/DevChernykh/docker-php-roadrunner <название каталога>
    ```
2. Перейти в каталог с проектом и создать .env на основе .env.example
    ```bash
   cd <название каталога> && cp .env.example .env
    ```
3. В .env заменить по необходимости следующие значения
   ```makefile
   PROJECT_CODE=             # код проекта (слитно, на английском языке)
   MODE=                     # dev или prod, для способа развёртывания
   INFRA_APP_PORT=           # порт, по которому нужно обращаться к приложению
   INFRA_DATABASE_PORT=      # порт, по которому обращаться к базе данных
   
   APP_DATABASE_NAME=        # название БД
   APP_DATABASE_USER=        # имя пользователя БД
   APP_DATABASE_SECRET=      # пароль для пользователя БД
   ```
4. Собрать приложение и запустить его
   ```bash
   make build && make up
   ```
5. Установить зависимости (для dev режима при первом запуске)
   ```bash
   make shell
   composer install
   ```
6. Пользоваться запущенным приложением

### Настройка подключения к БД из приложения

По умолчанию, никаких дополнительных изменений в .env приложения не нужны (app/.env).

Настройки подключения собираются автоматически из переменных окружения системы, которые передаются в compose.*.yaml
файлах.

По этому изменять значение DATABASE_URL не нужно.

Пример:

```makefile
DATABASE_URL="postgresql://$APP_DATABASE_USER:$APP_DATABASE_SECRET@database:5432/$APP_DATABASE_NAME?serverVersion=16&charset=utf8"
```

<p align="right">(<a href="#readme-top">Полетели на верх!</a>)</p>

## Использование

Для упрощённого управления контейнерами добавлен Makefile.
В нём описаны частые полезные команды. Для подробностей в терминале:
```bash
make help
```

<p align="right">(<a href="#readme-top">Полетели на верх!</a>)</p>

## Структура шаблона

* `app/` Расположение PHP приложение, изолированного от Docker`a.
* `docker/` Здесь находятся необходимые Dockerfile и файлы конфигурации/entrypoint для сборки
* `compose.*.yaml` Файлы развёртывания контейнеров
* `Makefile` Файл для упрощённой работы с контейнерами
* `.env.example` Пример настройки переменных Docker окружения (не касается PHP приложения)

### Подробнее о PHP образе

Для PHP сделано 2 Dockerfile

#### docker/app/base.php.Dockerfile

В нём описывается общая структура для всех PHP образов.
Как правило, изменения в этом файле крайне редки.

Там может устанавливаться:

1. PHP расширения
2. Утилиты
3. Доп. приложения

Эта часть занимает самое больше время при сборке, хотя не часто изменяется.

Вынесение в отдельный Dockerfile позволит настроить CI/CD таким образом, чтобы при сборках (особенно для тестов) не
занимало много времени, а также ускорило процесс деплоя.

#### docker/app/Dockerfile

Здесь описана сборка PHP образов под конкретные решения (dev или prod).

<p align="right">(<a href="#readme-top">Полетели на верх!</a>)</p>

## Модификация

* #### Добавление утилит или PHP расширений в PHP приложение

Описываем установку и настройку необходимого в docker/app/base.php.Dockerfile.
Желательно это сделать в инструкции `RUN apk add --no-cache --virtual .build-deps ...` до комментария `Cleanup`

* #### Дополнительная настройка PHP только для разработки

При необходимости добавить новый/вспомогательный функционал, который будет использоваться только в разработке,
то модернизируем файл docker/app/Dockerfile в блоке **DEVELOP PHP**

* #### Дополнительная настройка PHP только для продакшена

При необходимости добавить новый/вспомогательный функционал, который будет использоваться только в продакшене,
то модернизируем файл docker/app/Dockerfile в блоке **PRODUCTION PHP**

* #### Добавление новых сервисов

Чтобы добавить новый сервис, нужно описать его в нужном compose.*.yaml файле (или в обоих).
Для детальной настройки сервиса (если нужно описать Dockerfile) можно в каталоге docker добавить соответствующий
новому сервису подкаталог и в нём уже описать Dockerfile и расположить файлы конфигурации.

<p align="right">(<a href="#readme-top">Полетели на верх!</a>)</p>

## Roadmap

- [x] Добавить сервис PHP
- [x] Добавить сервис PostgreSQL
- [ ] Добавить описание настройки и работы с Xdebug
- [ ] Тестирование
  - [ ] Добавить запуск авто-тестов в GitHub
  - [ ] Добавить запуск авто-тестов в GitLab
  - [ ] Разобраться с проверкой покрытия тестами

## License

Distributed under the MIT License. See <a href="./LECENSE.md">LICENSE.md</a> for more information.

<p align="right">(<a href="#readme-top">Полетели на верх!</a>)</p>

[Docker.com]: https://img.shields.io/badge/docker-086dd7?style=for-the-badge&logo=docker&logoColor=white

[Docker-url]: https://docker.com

[PHP.net]: https://img.shields.io/badge/php-7A86B8?style=for-the-badge&logo=php&logoColor=white

[PHP-url]: https://php.net

[PostgreSQL.org]: https://img.shields.io/badge/postgresql-336791?style=for-the-badge&logo=postgresql&logoColor=white

[PostgreSQL-url]: https://www.postgresql.org/

[Symfony.com]: https://img.shields.io/badge/symfony-ffffff?style=for-the-badge&logo=symfony&logoColor=black

[Symfony-url]: https://www.symfony.com/

[RoadRunner.com]: https://img.shields.io/badge/Roadrunner-f2f2f7?style=for-the-badge

[RoadRunner-url]: https://roadrunner.dev/

[Xdebug.org]: https://img.shields.io/badge/xdebug-f2f2f7?style=for-the-badge

[Xdebug-url]: https://roadrunner.dev/
