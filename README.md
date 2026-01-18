# Домашнее задание: Балансировка нагрузки с HAProxy
**Студент:** Владислав Пак  
**Курс:** Отказоустойчивость (SFLT)

---

## Задание 1: Round-robin балансировка на 4 уровне (L4)

### Описание
Настроена балансировка Round-robin на прикладном уровне (L7/HTTP) для двух Python HTTP серверов.

### Конфигурация серверов
- **Server 1:** localhost:8001 → HTML: "Server 1 - Port 8001"
- **Server 2:** localhost:8002 → HTML: "Server 2 - Port 8002"
- **HAProxy Frontend:** localhost:8888 (изменён с 8080 из-за конфликта портов)

### Конфигурационный файл HAProxy

Файл: `task1/config/haproxy.cfg`
```haproxy
global
    log /dev/log local0
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend http_front
    bind *:8888
    default_backend http_back

backend http_back
    balance roundrobin
    server server1 127.0.0.1:8001 check
    server server2 127.0.0.1:8002 check
```

### Результаты тестирования

При последовательных запросах к HAProxy на порту 8888 наблюдается строгое **чередование** ответов от Server 1 и Server 2 в алгоритме Round-robin:
```
Request 1: Server 1 - Port 8001
Request 2: Server 2 - Port 8002
Request 3: Server 1 - Port 8001
Request 4: Server 2 - Port 8002
...
```

**Вывод:** Балансировка Round-robin работает корректно. Каждый сервер получает равное количество запросов.

**Скриншоты:**
- См. директорию `task1/screenshots/`

---

## Задание 2: Weighted Round Robin на 7 уровне (L7/HTTP)

### Описание
Настроена балансировка Weighted Round Robin на прикладном уровне (L7/HTTP) для трёх Python HTTP серверов с весами **2:3:4**. Балансировка работает **только** для домена `example.local`.

### Конфигурация серверов
- **Server 1:** localhost:8003 (вес 2)
- **Server 2:** localhost:8004 (вес 3)
- **Server 3:** localhost:8005 (вес 4)
- **HAProxy Frontend:** localhost:8888

### Конфигурационный файл HAProxy

Файл: `task2/config/haproxy.cfg`
```haproxy
global
    log /dev/log local0
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend http_front
    bind *:8888
    # ACL для проверки заголовка Host
    acl is_example_local hdr(host) -i example.local
    # Используем backend только если домен совпадает
    use_backend weighted_back if is_example_local
    # Иначе возвращаем 403
    default_backend no_match

# Backend с Weighted Round Robin
backend weighted_back
    balance roundrobin
    server server1 127.0.0.1:8003 weight 2 check
    server server2 127.0.0.1:8004 weight 3 check
    server server3 127.0.0.1:8005 weight 4 check

# Backend для отказа в доступе
backend no_match
    http-request deny deny_status 403
```

### Принцип работы весов

При весах **2:3:4** из 9 запросов распределение:
- Server 1 (вес 2) получает **2 запроса** (22.2%)
- Server 2 (вес 3) получает **3 запроса** (33.3%)
- Server 3 (вес 4) получает **4 запроса** (44.4%)

### Настройка /etc/hosts

Для работы ACL фильтрации добавлена запись:
```bash
127.0.0.1 example.local
```

### Результаты тестирования

**С доменом example.local:**

Из 9 тестовых запросов:
- Server 1: 2 запроса ✅
- Server 2: 3 запроса ✅
- Server 3: 4 запроса ✅

**Weighted Round Robin работает идеально с соотношением 2:3:4!**

**Без домена example.local:**

HAProxy возвращает `HTTP/1.1 403 Forbidden` ✅

ACL фильтрация по заголовку Host работает корректно!

**Скриншоты:**
- См. директорию `task2/screenshots/`

---

## Выводы

1. ✅ Успешно настроена балансировка **Round-robin** на L7 (HTTP уровень)
2. ✅ Настроена **Weighted Round Robin** на L7 с точным соблюдением весов 2:3:4
3. ✅ Реализована **ACL фильтрация** по заголовку Host для домена example.local
4. ✅ Изучены различия между балансировкой на разных уровнях OSI
5. ✅ Практически применены веса серверов для управления распределением нагрузки

## Технические детали

- **Операционная система:** Ubuntu 24.04
- **HAProxy версия:** 2.8.16
- **Python версия:** 3.12
- **Используемые порты:** 8001-8005, 8888

## Запуск тестов
```bash
# Задание 1
cd ~/netology/haproxy-hw/task1
./test_balancing.sh

# Задание 2
cd ~/netology/haproxy-hw/task2
./test_weighted_balancing.sh
```

---

**Репозиторий:** https://github.com/vpakspace/haproxy-hw
