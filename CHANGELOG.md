# Changelog

## [2.4.1](https://github.com/dailypay/httpigeon/compare/v2.4.0...v2.4.1) (2026-02-11)


### Bug Fixes

* Bump version to 2.4.1 ([#54](https://github.com/dailypay/httpigeon/issues/54)) ([0585ee5](https://github.com/dailypay/httpigeon/commit/0585ee556de27eb07f543dd0cb8cd85e5b92684c))

## [2.4.0](https://github.com/dailypay/httpigeon/compare/v2.3.3...v2.4.0) (2025-10-31)


### Features

* **ruby:** [NO-TICKET] Support and test Ruby 3.3 ([#51](https://github.com/dailypay/httpigeon/issues/51)) ([56ff677](https://github.com/dailypay/httpigeon/commit/56ff6778f60d892e464e5df775b9db7a3dd7fe80))

## [2.3.3](https://github.com/dailypay/httpigeon/compare/v2.3.2...v2.3.3) (2025-08-20)


### Bug Fixes

* **main:** Upgrade rake version ([#48](https://github.com/dailypay/httpigeon/issues/48)) ([b83a5c2](https://github.com/dailypay/httpigeon/commit/b83a5c23ac326d5741000437467845b102ccdfb4))

## [2.3.2](https://github.com/dailypay/httpigeon/compare/v2.3.1...v2.3.2) (2024-11-14)


### Bug Fixes

* **UNTICKETED:** Dont parse pdf as json ([#44](https://github.com/dailypay/httpigeon/issues/44)) ([fd4c13c](https://github.com/dailypay/httpigeon/commit/fd4c13cbb6c8084aa054c2daa756ace651e1338b))

## [2.3.1](https://github.com/dailypay/httpigeon/compare/v2.3.0...v2.3.1) (2024-07-11)


### Bug Fixes

* Execute block within scope ([#42](https://github.com/dailypay/httpigeon/issues/42)) ([a9a43c3](https://github.com/dailypay/httpigeon/commit/a9a43c391b449b3316812e1c99fb88e25c923b31))

## [2.3.0](https://github.com/dailypay/httpigeon/compare/v2.2.0...v2.3.0) (2024-07-11)


### Features

* add and fix put and delete methods ([#41](https://github.com/dailypay/httpigeon/issues/41)) ([1d9e9b0](https://github.com/dailypay/httpigeon/commit/1d9e9b0585d56c9785efa97e5a743cdcbd179884))
* Use enumarable for collection delegation ([8fc143a](https://github.com/dailypay/httpigeon/commit/8fc143a8717aebdd072bd48dceccc34a318657b7))


### Bug Fixes

* Delegate :map to parsed response ([#39](https://github.com/dailypay/httpigeon/issues/39)) ([59b77e8](https://github.com/dailypay/httpigeon/commit/59b77e821a1356884cb7c426fe433229aa1bdfcc))

## [2.2.0](https://github.com/dailypay/httpigeon/compare/v2.1.0...v2.2.0) (2024-05-17)


### Features

* Add more callbacks ([#38](https://github.com/dailypay/httpigeon/issues/38)) ([660cfba](https://github.com/dailypay/httpigeon/commit/660cfba63a8cdc2ff73764913426d38644aaf53a))
* **request:** Implement circuit breaking ([#33](https://github.com/dailypay/httpigeon/issues/33)) ([c25eab4](https://github.com/dailypay/httpigeon/commit/c25eab406d26b50da806d122eb73be0701b84c4e))

## [2.1.0](https://github.com/dailypay/httpigeon/compare/v2.0.1...v2.1.0) (2024-01-05)


### Features

* **response:** [NO-TICKET] parsed_response tests and json support ([#31](https://github.com/dailypay/httpigeon/issues/31)) ([e169215](https://github.com/dailypay/httpigeon/commit/e169215e1394927cb9137e1691196aa535ffd25d))

## [2.0.1](https://github.com/dailypay/httpigeon/compare/v2.0.0...v2.0.1) (2023-12-21)


### Bug Fixes

* **request:** Handle edge cases in response parsing ([#29](https://github.com/dailypay/httpigeon/issues/29)) ([7818562](https://github.com/dailypay/httpigeon/commit/7818562736b5c5258b77357c73f24926e46eb458))

## [2.0.0](https://github.com/dailypay/httpigeon/compare/v1.3.0...v2.0.0) (2023-10-25)


### ⚠ BREAKING CHANGES

* **logging:** Improve redaction mechanism ([#23](https://github.com/dailypay/httpigeon/issues/23))

### Features

* Generate request ID header by default ([#25](https://github.com/dailypay/httpigeon/issues/25)) ([c2aa078](https://github.com/dailypay/httpigeon/commit/c2aa078947c422f544ff1b36d77576a2a3681d08))
* **logging:** Improve redaction mechanism ([#23](https://github.com/dailypay/httpigeon/issues/23)) ([ce090bd](https://github.com/dailypay/httpigeon/commit/ce090bd0124ef3f3ec616d7c0af5a4652be11b0a))

## [1.3.0](https://github.com/dailypay/httpigeon/compare/v1.2.1...v1.3.0) (2023-08-24)


### Features

* **request:** Add helper :get and :post class methods ([#21](https://github.com/dailypay/httpigeon/issues/21)) ([e7427a6](https://github.com/dailypay/httpigeon/commit/e7427a6f1fe2d39e4cce2ec3ea1188e03b563287))

## [1.2.1](https://github.com/dailypay/httpigeon/compare/v1.2.0...v1.2.1) (2023-07-28)


### Bug Fixes

* **logger:** Fix reference to ruby Logger constant ([#19](https://github.com/dailypay/httpigeon/issues/19)) ([ec99bd5](https://github.com/dailypay/httpigeon/commit/ec99bd5b6371256ded6c88c8413b0bd2c926a7a1))

## [1.2.0](https://github.com/dailypay/httpigeon/compare/v1.1.1...v1.2.0) (2023-07-28)


### Features

* Add customizable log redactor that can handle both Hash and String payload. Also add support for auto-generating request IDs ([#14](https://github.com/dailypay/httpigeon/issues/14)) ([c3efa0a](https://github.com/dailypay/httpigeon/commit/c3efa0a510cda687f6a6822e17c1c9600ba4dfd0))

## [1.1.1](https://github.com/dailypay/httpigeon/compare/v1.1.0...v1.1.1) (2023-06-20)


### Bug Fixes

* **httpigeon:** Leave event logger constructor signature up to call site ([#10](https://github.com/dailypay/httpigeon/issues/10)) ([03ba441](https://github.com/dailypay/httpigeon/commit/03ba441c66d8ea6562f218b41cc8f724bd98a4a9))

## 1.0.0 (2023-06-20)
Initial release

### Features

* **httpigeon:** [XAPI-1353] Gemify HTTPigeon library ([#1](https://github.com/dailypay/httpigeon/issues/1)) ([ee89810](https://github.com/dailypay/httpigeon/commit/ee898102b2dffe6623e57a0d799a8b9a37d068a1))
