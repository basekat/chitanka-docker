# Какво е Chitanka Docker?

`Chitanka Docker` е проект за контейнеризиране на софтуера задвижващ [Моята Библиотека](https://https://github.com/chitanka) и възможността за използването му в micro-services среда. При създаването му е следвана логиката и последователността на инсталиране описана в [Автоматичния инсталатор](https://github.com/chitanka/chitanka-installer).
С помощта на Docker може да бъде използван под Linux, Windows или Mac на собствен сървър или локален компютър - [Docker Desktop](https://www.docker.com/products/docker-desktop/).

# Как да използваме?

```console
$ git clone https://github.com/basecat/chitanka-docker chitanka
$ cd chitanka
... създайте docker-compose.yml
docker-compose up -d
```

Уверете се, че всички контейнери са стартирани:
```
# docker-compose ps
     Name                    Command               State            Ports
----------------------------------------------------------------------------------
chitanka_app_1    /entrypoint.sh php-fpm           Up      9000/tcp
chitanka_cron_1   /cron.sh                         Up      9000/tcp
chitanka_db_1     docker-entrypoint.sh mysqld      Up      3306/tcp
chitanka_web_1    /docker-entrypoint.sh ngin ...   Up      80->80/tcp
```

При първоначалното стартиране на `chitanka_app` контейнера, ще бъде изтеглена актуалната версия на базата от данни на [Моята Библиотека](https://https://github.com/chitanka)
Съдържанието (архива) на [Моята Библиотека](https://https://github.com/chitanka) може да бъде обновен като стартирате cron скрипта за периодично обновяване:
```console
# docker-compose exec --user www-data app bash
www-data@277af26280d7:~/html$ cd /var/www/chitanka/
www-data@277af26280d7:~/chitanka$ ./bin/update
21:47:43: Update started on 2022-06-10.
21:47:43: Pause for 30 seconds.
21:48:13: Executing source update...
21:48:15: Executing content update...
21:48:28: Executing database update...
21:48:28: Done.
```

```
version: '3'

services:
  db:
    image: mariadb:10.5
    restart: always
    command: --collation-server=utf8mb4_unicode_ci --character-set-server=utf8mb4 --skip-character-set-client-handshake
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=chitankamysqlrootpassword
      - MYSQL_DATABASE=chitanka
      - MYSQL_USER=chitanka
      - MYSQL_PASSWORD=chitanka

  app:
    image: basekat/chitanka
    restart: always
    volumes:
      - config:/var/www/chitanka/app/config
      - app:/var/www/chitanka
      - content:/var/www/chitanka/web/content
    environment:
      - MYSQL_HOST=db
      - MYSQL_DATABASE=chitanka
      - MYSQL_USER=chitanka
      - MYSQL_PASSWORD=chitanka
    extra_hosts:
      - "chitanka.local:127.0.0.1"
    depends_on:
      - db

  web:
    image: nginx
    restart: always
    environment:
      - VIRTUAL_HOST=chitanka.local
    extra_hosts:
      - "chitanka.local:127.0.0.1"
    ports:
      - 80:80
    depends_on:
      - app
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./nginx_chitanka_conf.template:/etc/nginx/templates/default.conf.template
    volumes_from:
      - app

  cron:
    image: basekat/chitanka
    restart: always
    environment:
      - TZ=Europe/Sofia
      - CHITANKA_CRON=57 01 * * *
    extra_hosts:
      - "chitanka.local:127.0.0.1"
    entrypoint: /cron.sh
    depends_on:
      - db
      - app
    volumes_from:
      - app

volumes:
    db:
    config:
    content:
    app:
```


# Информация за отделните услуги

## `db`

`db` контейнерът използва стандартен MariaDB 10.5 docker image - текущата версия на MariaDB в `Debian GNU/Linux bullseye`. Настройте `MYSQL_` параметрите или използвайте тези по подразбиране.
```
  db:
    image: mariadb:10.5
    restart: always
    command: --collation-server=utf8mb4_unicode_ci --character-set-server=utf8mb4 --skip-character-set-client-handshake
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=chitankamysqlrootpassword
      - MYSQL_DATABASE=chitanka
      - MYSQL_USER=chitanka
      - MYSQL_PASSWORD=chitanka
```

## `app`

`app` контейнерът съдържа изходния код на [Моята Библиотека](https://https://github.com/chitanka). Скриптовете за генерирането му можете да намерите в текущото хранилище.
```
  app:
    image: basekat/chitanka
    restart: always
    volumes:
      - config:/var/www/chitanka/app/config
      - app:/var/www/chitanka
      - content:/var/www/chitanka/web/content
    environment:
      - MYSQL_HOST=db
      - MYSQL_DATABASE=chitanka
      - MYSQL_USER=chitanka
      - MYSQL_PASSWORD=chitanka
    extra_hosts:
      - "chitanka.local:127.0.0.1"
    depends_on:
      - db
```

Следните параметри трябва да имат същите стойности както при `db` контейнера.
```
      - MYSQL_DATABASE=chitanka
      - MYSQL_USER=chitanka
      - MYSQL_PASSWORD=chitanka
```

Следните volumes са дефинирани:
- `config:/var/www/chitanka/app/config` - Различни конфигурационни файлов
- `app:/var/www/chitanka` - Изходен код
- `content:/var/www/chitanka/web/content` - Съдържанието на Моята библиотека. Към момента големината на архива е около 17 GB.


## `web`

`web` контейнерът използва стандартен Docker nginx image.
```
  web:
    image: nginx
    restart: always
    environment:
      - VIRTUAL_HOST=chitanka.local
    extra_hosts:
      - "chitanka.local:127.0.0.1"
    ports:
      - 80:80
    depends_on:
      - app
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./nginx_chitanka_conf.template:/etc/nginx/templates/default.conf.template
    volumes_from:
      - app
```

- `VIRTUAL_HOST` - В случай, че имате свой домейн, можете да го конфигурирате в този параметър. Също така го променете в секцията extra_hosts на *всички* услуги.

Ако искате уеб сървъра да слуша на друг порт (например 8080), можете да го смените в секцията `ports`:
```
ports:
  - 8080:80
```

Тъй като стандартният `nginx image` пуска `nginx` процеса с UID/GID nginx:nginx(101:101) (вместо www-data:www-data 33:33) се налага монтирането на `nginx.conf`:
```
     - ./nginx.conf:/etc/nginx/nginx.conf
```
и промяна на следния параметър:
```user  www-data;```

- `nginx_chitanka_conf.template`  е шаблон, който бива използван за динамично генериране на конфигурацията за виртуалния хост. Използван е [ngix.conf](https://github.com/chitanka/chitanka-installer/blob/master/nginx-vhost.conf) от [Автоматичния инсталатор](https://github.com/chitanka/chitanka-installer)
```
      - ./nginx_chitanka_conf.template:/etc/nginx/templates/default.conf.template
```

## `cron`

`cron` контейнерът се използва за автоматичното обновяване на съдържанието.

`- TZ=Europe/Sofia` - часова зона
`- CHITANKA_CRON=57 01 * * *` - часът в cron формат, в който да се извърши обновяването (в случая 01:57)

# Обновяване

За да извършите обновяване на версията на всички docker image-и:
```console
docker-compose down
docker-compose pull
docker-compose up -d
```

# Създаване на собствен chitanka image

Ако искате да генерирате собствен image за `app` контейнера:
```console
cd chitanka
docker build -t chitanka-local
```

Променете в docker-compose.yml, заменете:
```image: basekat/chitanka```

с това:
```image: chitanka-local```

# Докладване на проблеми

Ако искате да докладвате проблем или имате идея - [Issues](https://github.com/basekat/chitanka-docker/issues)
