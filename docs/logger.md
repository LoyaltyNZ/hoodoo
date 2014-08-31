# ApiTools::Logger

## Purpose

A class intended as a standardised API/service logger. The class acts as a proxy, an external logger can be set in the class. If a logger is not set, the class will log to STDOUT with an appropriate 'DEBUG', 'INFO', 'WARN' or 'ERROR' prefix.

## Usage

In the your sinatra API class:

    require 'api_tools'

All methods are class methods.

The module provides the following methods in the API class, available in the sinatra DSL and custom methods:

| Method              | Description                                       |
|:--------------------|:--------------------------------------------------|
| `self.logger`       | Return the current logger, or `nil` if undefined. |
| `self.logger=`      | Set the current logger.                           |
| `self.debug(*args)` | Write to the DEBUG log.                           |
| `self.info(*args)`  | Write to the INFO log.                            |
| `self.warn(*args)`  | Write to the WARN log.                            |
| `self.error(*args)` | Write to the ERROR log.                           |

## External Logger Interface.

If an external logger is set, it should support the following interface:

| Method        | Description             |
|:--------------|:------------------------|
| `debug(args)` | Write to the DEBUG log. |
| `info(args)`  | Write to the INFO log.  |
| `warn(args)`  | Write to the WARN log.  |
| `error(args)` | Write to the ERROR log. |


## Dependencies

None.

## Example

    require 'api_tools'

    ApiTools::Logger.info('Logger is being used!')
