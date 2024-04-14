# Changelog

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
