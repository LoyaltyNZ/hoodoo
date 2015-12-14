---
layout: default
categories: [guide]
title: Utilities
---

## Purpose

Hoodoo includes a grab-bag of utility methods used internally to keep its footprint, including external dependencies, to a minimum. These methods are part of the public API and covered by [RDoc]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html). This Guide lists the facilities available in groups, making them easier to discover.

It is generally recommended that service authors use Hoodoo utility methods where possible to help ensure consistent behaviour across the system.

## Hashes

### Creation

* [`collated_hash_from`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-collated_hash_from) -- build a Hash from an Array, allowing duplicate entries
* [`deep_dup`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-deep_dup) -- duplicate a Hash and any nested Hashes
* [`stringify`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-stringify) -- convert keys to Strings
* [`symbolize`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-symbolize) -- convert keys to Symbols

### Modification

* [`deep_merge_into`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-deep_merge_into) -- merge one Hash into another, including any nested Hashes

### Comparison and access

* [`hash_diff`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-hash_diff) -- compare two Hashes
* [`hash_key_paths`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-hash_key_paths) -- extract the key paths for a Hash and any nested Hashes into a flat Array

## Date and time

### Conversion

* [`nanosecond_iso8601`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-nanosecond_iso8601) -- consistent rendering of a Time or DateTime with nanosecond precision
* [`rationalise_datetime`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-rationalise_datetime) -- convert various forms of input representation into a DateTime instance

### Validation

* [`valid_iso8601_subset_date?`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-valid_iso8601_subset_date-3F) -- see if a String describing a date conforms to the Hoodoo ISO 8601 subset
* [`valid_iso8601_subset_datetime?`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-valid_iso8601_subset_datetime-3F) -- see if a String describing a date and time conforms to the Hoodoo ISO 8601 subset

## Miscellaneous

* [`spare_port`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-spare_port) -- find a spare TCP port on `localhost`
* [`to_integer?`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Utilities.html#method-c-to_integer-3F) -- check to see if an input quantity will convert to an Integer without loss or ignored characters
