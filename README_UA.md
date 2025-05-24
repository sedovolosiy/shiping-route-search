# Сервіс пошуку маршрутів та тарифів доставки

## Огляд

Цей сервіс дозволяє знаходити маршрути доставки між портами за різними критеріями (найдешевший, найшвидший, лише прямий тощо), з урахуванням конвертації валют та розрахунку вартості маршруту.

## Як запустити

### 1. Встановлення залежностей

```bash
bundle install
```

### 2. Підготовка вхідних даних

Файл `data.json` повинен містити такі ключі:
- `sailings` — масив рейсів
- `rates` — масив тарифів
- `exchange_rates` — курси валют за датами

Дивіться приклад структури нижче.

### 3. Запуск програми

Програму можна запустити двома способами:

```bash
ruby application/main.rb
```
або
```bash
bin/route_finder
```

### 4. Введення параметрів

За замовчуванням програма очікує введення з клавіатури (stdin):
1. Код порту відправлення (наприклад, CNSHA)
2. Код порту призначення (наприклад, NLRTM)
3. Критерій пошуку (`cheapest`, `cheapest-direct`, `fastest`)

Приклад:
```
CNSHA
NLRTM
cheapest
```

### 5. Запуск тестів

```bash
rake test
rake coverage
```

Звіт про покриття буде згенеровано у директорії `coverage/` та відкриється у браузері при використанні команди `rake coverage`.

### 6. Запуск через Docker

```bash
docker build -t route-finder .
docker run -it --rm -v "$PWD/data.json:/app/data.json" route-finder
```

#### Запуск тестів у Docker

```bash
docker run --rm -it route-finder bundle exec rake test
```

#### Запуск з параметрами через Docker

```bash
echo -e "CNSHA\nNLRTM\ncheapest" | docker run -i --rm -v "$PWD/data.json:/app/data.json" route-finder
```

---

## Змінні оточення

У проєкті використовуються такі змінні оточення для керування поведінкою програми:

- `RETURN_MULTIPLE_ROUTES` — якщо `true`, програма виводить всі маршрути, що відповідають критерію пошуку (наприклад, всі найдешевші або найшвидші маршрути). Якщо `false`, буде виведено лише один оптимальний маршрут.
- `OUTPUT_FORMAT` — формат виводу результату. Зараз підтримується лише `json`, але змінна передбачена для розширення функціоналу.
- `COVERAGE` — якщо `true`, при запуску тестів вмикається збір покриття коду через simplecov.
- `INPUT_TYPE` — спосіб введення параметрів пошуку. За замовчуванням `stdin` (введення з клавіатури), але змінна передбачена для розширення.
- `MAX_LEGS` — максимальна кількість сегментів (legs) у непрямому маршруті. Обмежує глибину пошуку для складних маршрутів.
- `DATA_FILE` — ім'я файлу з даними для пошуку маршрутів і тарифів (за замовчуванням `data.json`).

Приклад використання змінних оточення:

```bash
RETURN_MULTIPLE_ROUTES=true OUTPUT_FORMAT=json MAX_LEGS=4 DATA_FILE=data.json ruby application/main.rb
```

Або через Docker:

```bash
docker run -e RETURN_MULTIPLE_ROUTES=true -e OUTPUT_FORMAT=json -e MAX_LEGS=4 -e DATA_FILE=data.json -it --rm -v "$PWD/data.json:/app/data.json" route-finder
```

---

## Особливості виводу

- Формат виводу контролюється змінною `OUTPUT_FORMAT` (за замовчуванням — JSON).
- Якщо знайдено декілька маршрутів, що повністю відповідають критерію (наприклад, декілька найдешевших або найшвидших), і змінна `RETURN_MULTIPLE_ROUTES=true`, у відповіді буде масив маршрутів.
- Кожен маршрут (або сегмент маршруту) представлений окремим об'єктом з детальною інформацією.

### Приклад структури `data.json`

```json
{
  "sailings": [
    {
      "sailing_code": "ERXQ",
      "origin_port": "CNSHA",
      "destination_port": "ESBCN",
      "departure_date": "2022-01-29",
      "arrival_date": "2022-02-06"
    },
    {
      "sailing_code": "ETRG",
      "origin_port": "ESBCN",
      "destination_port": "NLRTM",
      "departure_date": "2022-02-16",
      "arrival_date": "2022-02-20"
    }
    // ... інші рейси ...
  ],
  "rates": [
    {
      "sailing_code": "ERXQ",
      "amount": "261.96",
      "currency": "EUR"
    },
    {
      "sailing_code": "ETRG",
      "amount": "69.96",
      "currency": "USD"
    }
    // ... інші тарифи ...
  ],
  "exchange_rates": [
    {
      "date": "2022-01-29",
      "usd": 1.1138,
      "eur": 1.0
    },
    {
      "date": "2022-02-16",
      "usd": 1.1350,
      "eur": 1.0
    }
    // ... інші курси ...
  ]
}
```

### Приклад відповіді програми

Для пошуку найдешевшого маршруту (наприклад, з пересадкою):

```json
[
  {
    "origin_port": "CNSHA",
    "destination_port": "ESBCN",
    "departure_date": "2022-01-29",
    "arrival_date": "2022-02-06",
    "sailing_code": "ERXQ",
    "rate": "261.96",
    "rate_currency": "EUR"
  },
  {
    "origin_port": "ESBCN",
    "destination_port": "NLRTM",
    "departure_date": "2022-02-16",
    "arrival_date": "2022-02-20",
    "sailing_code": "ETRG",
    "rate": "69.96",
    "rate_currency": "USD"
  }
]
```

Для прямого маршруту відповідь міститиме лише один об'єкт.

### Приклад відповіді при RETURN_MULTIPLE_ROUTES=true

Якщо змінна оточення `RETURN_MULTIPLE_ROUTES` встановлена у `true`, програма може повернути декілька маршрутів, кожен з яких відповідає обраному критерію. У цьому випадку відповідь — масив маршрутів, де кожен маршрут — це масив сегментів (legs):

```
RETURN_MULTIPLE_ROUTES=true OUTPUT_FORMAT=json MAX_LEGS=4 DATA_FILE=data.json ruby application/main.rb
CNSHA
NLRTM
cheapest
[
  [
    {
      "origin_port": "CNSHA",
      "destination_port": "ESBCN",
      "departure_date": "2022-01-29",
      "arrival_date": "2022-02-12",
      "sailing_code": "ERXQ",
      "rate": "261.96",
      "rate_currency": "EUR"
    },
    {
      "origin_port": "ESBCN",
      "destination_port": "NLRTM",
      "departure_date": "2022-02-16",
      "arrival_date": "2022-02-20",
      "sailing_code": "ETRG",
      "rate": "69.96",
      "rate_currency": "USD"
    }
  ]
]
```

Кожен вкладений масив — це окремий маршрут, що складається з одного або декількох сегментів.

---

## Критерії пошуку

- `cheapest-direct` — Найдешевший прямий рейс
- `cheapest` — Найдешевший маршрут (може бути з пересадками)
- `fastest` — Найшвидший маршрут (за загальним часом у дорозі)

---

## Ключові компоненти

- **JsonRepository** — завантаження рейсів, тарифів і курсів валют з JSON
- **RouteSearchStrategyFactory** — вибір стратегії пошуку за критерієм
- **RouteFinder** — пошук маршрутів за обраною стратегією
- **UniversalConverter** — конвертація валют за датою
- **OutputHandler** — форматування та вивід результату

## Контакти
Питання та пропозиції: sedovolosiy@gmail.com
