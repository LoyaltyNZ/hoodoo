# api_tools - Usage

## Gem Namespace

All classes and modules live in the module `ApiTools`.

## General Tools

| Component                 | Description                                                 |
|:--------------------------|:------------------------------------------------------------|
| [ApiTools::PlatformErrors](platform_errors.md)  | Module to add standard error functionality to any class     |
| [ApiTools::Logger](logger.md)          | A unified logger for eventual use with Platform logs        |

## Sinatra Extensions

| Component                 | Description                                                 |
|:--------------------------|:------------------------------------------------------------|
| [ApiTools::JsonErrors](json_errors.md)      | Unified JSON error functonality for Platform APIs           |
| [ApiTools::JsonPayload](json_payload.md)     | Unified JSON payload parsing/errors                         |
| [ApiTools::PlatformContext](platform_context.md) | Parsing of Platform Headers & Context                       |

## Presenter

| Component                            | Description |
|:-------------------------------------|:------------|
| [ApiTools::Presenters::BasePresenter](presenters/base_presenter.md)  | Base class for JSON presenters, includes a DSL for JSON schema validation |

## Working Examples

Platform services already using `api_tools`:

| Service  |
|:---------|
| [Fulfilment Service](https://github.com/LoyaltyNZ/fulfilment_service) |