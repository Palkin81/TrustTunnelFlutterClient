# TrustTunnel Flutter Client — QWEN.md

## Project Overview

**TrustTunnel Flutter Client** — это мобильное VPN-приложение для Android и iOS, разработанное на Flutter. Приложение предоставляет пользовательский интерфейс для подключения к самодостаточным VPN-серверам TrustTunnel.

### Ключевые характеристики:
- **Кроссплатформенность**: Android и iOS
- **Архитектура**: Клиент-серверная модель с явным разделением ответственности
- **Стек**: Flutter 3.38.3, Dart 3.10.1
- **Версия**: 1.2.0+6671

### Архитектура проекта:
```
tt_client/
├── lib/                    # Основной код приложения
│   ├── common/            # Общие утилиты, модели, локализация
│   ├── data/              # Слой данных (API, репозитории)
│   ├── di/                # Dependency Injection
│   ├── feature/           # Фичи (app, vpn, server, routing, settings)
│   ├── widgets/           # Переиспользуемые виджеты
│   └── main.dart          # Точка входа
├── plugins/vpn_plugin/    # Flutter плагин для VPN-функциональности
│   ├── android/           # Native Android implementation
│   ├── ios/               # Native iOS implementation
│   ├── lib/               # Dart API плагина
│   └── pigeons/           # Pigeon API definitions
├── assets/                # Ресурсы (изображения, шрифты)
├── bamboo-specs/          # CI/CD конфигурация (Bamboo)
└── test/                  # Тесты
```

## Building and Running

### Prerequisites

- **Flutter SDK**: 3.38.3 или новее
- **Dart SDK**: 3.10.1
- **make**: утилита для автоматизации сборки
- **Android/iOS tooling**: для целевой платформы

### Environment Setup

#### GitHub Packages Access
Проект использует зависимости из GitHub Packages. Требуется персональный токен:

```bash
# Создать токен с правами: read:packages, public_repo
# https://github.com/settings/tokens

export GPR_KEY=<your_personal_access_token>
```

### Основные команды (Makefile)

| Команда | Описание |
|---------|----------|
| `make init` | Инициализация проекта (clean, pub get, build_runner, localization) |
| `make gen` | Генерация кода (build_runner + VPN plugin) |
| `make ln` | Генерация локализации |
| `make release-android` | Сборка Android AAB (release) |
| `make aux-setup-android-signing` | Настройка подписи Android (keystore) |

### Flutter команды

```bash
# Запуск приложения
flutter run

# Сборка
flutter build apk      # Android APK
flutter build appbundle # Android AAB
flutter build ios       # iOS

# Тесты
flutter test

# Линтинг
flutter analyze
```

### Настройка платформ

#### Android
```bash
# Настройка подписи (интерактивно)
make aux-setup-android-signing
```

#### iOS
```bash
cd ios
pod install --repo-update

# В Xcode:
# - Открыть ios/Runner.xcworkspace
# - Выбрать Runner target
# - Signing & Capabilities → Team + Auto manage signing
```

## Development Conventions

### Структура кода

Проект использует **Feature-first архитектуру** с разделением на слои:

```
lib/
├── feature/
│   ├── app/           # Глобальное состояние приложения
│   ├── vpn/           # VPN соединение, логи, статусы
│   ├── server/        # Управление серверами
│   ├── routing/       # Маршрутизация трафика, профили
│   ├── settings/      # Настройки (excluded routes и др.)
│   ├── navigation/    # Навигация
│   └── deep_link/     # Deep links обработка
├── common/
│   ├── models/        # Базовые модели данных
│   ├── controller/    # Базовые классы для BLoC/Cubit
│   ├── localization/  # i18n (arb файлы + сгенерированный код)
│   ├── theme/         # Темы оформления
│   └── utils/         # Утилиты
├── data/
│   ├── api/           # API клиенты (включая Swagger)
│   └── repositories/  # Репозитории
├── di/                # Dependency Injection
└── widgets/           # Переиспользуемые UI компоненты
```

### Код-стайл (analysis_options.yaml)

- **Ширина строки**: 120 символов
- **Трейл-запятые**: preserve (сохранять)
- **Строгие типы**: `strict-raw-types: true`, `strict-casts: true`
- **Предпочтения**:
  - `prefer_single_quotes: true`
  - `prefer_const_constructors: true`
  - `avoid_print: true` (использовать `log` из `dart:developer`)
  - `use_super_parameters: true`

### Метрики и правила (dart_code_metrics)

Проект использует dart_code_metrics со следующими правилами:
- **member-ordering**: строгий порядок членов класса (static fields → constructors → getters → methods)
- **match-class-name-pattern**: 
  - `*State` для файлов `*state.dart`
  - `*Event` для файлов `*event.dart`
  - `*Bloc` для файлов `*bloc.dart`
- **Запрещены**: `avoid-cubits`, `no-boolean-literal-compare`
- **Предпочтения**: `prefer-trailing-comma`, `prefer-padding-over-container`

### Генерация кода

Проект использует code generation для:
- **Drift** (SQLite ORM): `.g.dart` файлы
- **Freezed** (immutable models): `.freezed.dart` файлы
- **Pigeon** (platform channels): в `vpn_plugin`
- **intl_utils** (локализация): `lib/common/localization/generated/`

```bash
# Запуск генерации
make gen

# Или напрямую
dart run build_runner build --delete-conflicting-outputs
```

### Локализация

- **Инструмент**: `intl_utils` + `flutter_intl`
- **Формат**: `.arb` файлы в `lib/common/localization/arb/`
- **Основной язык**: English (`en`)
- **Класс**: `AppLocalizations`

```bash
# Генерация локализации
make ln
# или
dart run intl_utils:generate
```

### Тестирование

- **Фреймворк**: `flutter_test`
- **Расположение**: `test/`
- **Запуск**: `flutter test`

> **Важно**: VPN-функциональность должна тестироваться на **реальных устройствах**, а не на эмуляторах.

### CI/CD (Bamboo)

Проект использует Bamboo для CI/CD. Скрипты в `bamboo-specs/scripts/`:
- `configure_before_android_build.sh` / `configure_before_ios_build.sh`
- `build_android.sh` / `build_ipa.sh`
- `increment_build_number.sh`
- `collect_changelog.sh`
- `deploy_to_testflight.sh`

## Key Dependencies

### Основные пакеты
| Пакет | Версия | Назначение |
|-------|--------|------------|
| `drift` | 2.30.0 | SQLite ORM |
| `rxdart` | 0.28.0 | Reactive extensions |
| `file_picker` | 10.3.10 | Выбор файлов |
| `app_links` | 7.0.0 | Deep links |
| `package_info_plus` | 9.0.0 | Информация о пакете |
| `url_launcher` | 6.3.2 | Открытие URL |
| `flutter_native_splash` | 2.4.7 | Splash screen |
| `vpn_plugin` | local | VPN функциональность |

### Dev зависимости
- `build_runner` — code generation
- `drift_dev` — Drift ORM tools
- `flutter_lints` — линтинг
- `pigeon` — platform channels (в vpn_plugin)

## VPN Plugin Architecture

Проект разделён на два независимых слоя:

1. **Flutter App** (`lib/`) — UI, бизнес-логика, управление соединением
2. **VPN Plugin** (`plugins/vpn_plugin/`) — нативная VPN интеграция

### Плагин поддерживает платформы:
- Android (Kotlin)
- iOS (Swift)
- Linux (C++)
- macOS (Swift)
- Windows (C++)

### Pigeon API
Межплатформенное взаимодействие через Pigeon:
```bash
# Генерация Pigeon кода
cd plugins/vpn_plugin
make gen
```

## Troubleshooting

### Ошибки сборки GitHub Packages
```bash
# Убедитесь, что GPR_KEY установлен
echo $GPR_KEY
# Если пустой — экспортируйте токен
export GPR_KEY=<token>
```

### Проблемы с генерацией кода
```bash
# Очистить и перегенерировать
flutter clean
make init
```

### Ошибки подписи Android
```bash
# Перегенерировать keystore
make aux-setup-android-signing
```

### Проблемы с iOS pods
```bash
cd ios
pod deintegrate
pod install --repo-update
```

## Additional Resources

- [README.md](./README.md) — основная документация
- [pubspec.yaml](./pubspec.yaml) — зависимости и конфигурация Flutter
- [analysis_options.yaml](./analysis_options.yaml) — правила линтинга
- [Makefile](./Makefile) — скрипты сборки
- [plugins/vpn_plugin/](./plugins/vpn_plugin/) — VPN плагин
