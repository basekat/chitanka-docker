# Какво е Chitanka Docker?

```Chitanka Docker``` е проект за контейнеризиране на софтуера задвижващ [[Моята Библиотека|https://https://github.com/chitanka]] и възможността за използването му в micro-services среда. При създаването му е следвана логиката и последователността на инсталиране описана в [[Автоматичния инсталатор|https://github.com/chitanka/chitanka-installer]].
С помощта на Docker може да бъде използван под Linux, Windows или Mac на собствен сървър или на лаптоп - [[Docker Desktop|https://www.docker.com/products/docker-desktop/]].


# Как да използваме?

```console
git clone https://github.com/basecat/chitanka-docker chitanka
cd chitanka
... създайте docker-compose.yml
docker-compose up -d
```

Ето примерен docker-compose.yml:

```version: '3'

services:
  db:
    image: mariadb:10.5
    restart: always
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


# Информация за конфигурацията на различните услуги

## `db`

`db` контейнерът използва стандартен MariaDB 10.5 docker image, текущата версия в `Debian GNU/Linux bullseye`. Настройте `MYSQL_` параметрите или използвайте тези по подразбиране.  
```db:
    image: mariadb:10.5
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=chitankamysqlrootpassword
      - MYSQL_DATABASE=chitanka
      - MYSQL_USER=chitanka
      - MYSQL_PASSWORD=chitanka
```

## `app`

`app` контейнерът съдържа изходния код на [[Моята Библиотека|https://https://github.com/chitanka]]. Скриптовете за генерирането му можете да намерите в текущото хранилище.
```app:
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
`- config:/var/www/chitanka/app/config` - Различни конфигурационни файлов
      - app:/var/www/chitanka - Изходен код
      - content:/var/www/chitanka/web/content - Съдържанието на Моята библиотека. Към момента на писане големината е 17 GB. 

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

```nginx_chitanka_conf.template```  е шаблон, който бива използван за динамично генериране на конфигурацията за виртуалния хост. Използван е [[ngix.conf|https://github.com/chitanka/chitanka-installer/blob/master/nginx-vhost.conf]] от [[Автоматичния инсталатор|https://github.com/chitanka/chitanka-installer]]
```
      - ./nginx_chitanka_conf.template:/etc/nginx/templates/default.conf.template
```

## `cron`

`cron` контейнерът се използва за автоматичното обновяване на съдържанието.

`- TZ=Europe/Sofia` - часова зона
`- CHITANKA_CRON=57 01 * * *` - часът в cron формат, в който да се извърши обновяването (в случая 01:57)