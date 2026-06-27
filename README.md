[![Actions Status](https://github.com/lizmat/JSON-Webhook/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/JSON-Webhook/actions) [![Actions Status](https://github.com/lizmat/JSON-Webhook/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/JSON-Webhook/actions) [![Actions Status](https://github.com/lizmat/JSON-Webhook/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/JSON-Webhook/actions)

NAME
====

JSON::Webhook - provide webhook logic for processing JSON payloads

SYNOPSIS
========

```raku
use JSON::Webhook;

JSON::Webhook.new :$host, :$port, :$application;
```

DESCRIPTION
===========

The `JSON::Webhook` distribution provides a `JSON::Webhook` role that provides the logic for running a webservice that accepts JSON payloads (typically from services such as Github / Codeberg) and collects them using the logic provided by [JSON::Collector](https://raku.land/zef:lizmat/JSON::Collector).

Customization can either be done by providing extra named arguments to the `new` and/or `application` methods, or by consuming the `JSON::Webhook` role into a class that provides customized `collector` and `processor` methods.

```raku
use JSON::Webhook;

# Custom class that inserts the value of the "channels" named
# argument from the request into the data structure to be saved
class JSON::Webhook::Channels does JSON::Webhook {
    method processor() {
        -> %data, %nameds {
            %data<channels> := .split(",") with %nameds<channels>;
            %data
        }
    }
}
```

METHODS
=======

new
---

```raku
say "starting server";
JSON::Webhook.new :$host, :$port, :$application, ...
say "server stopped";
```

The `new` method provides the simplest way to set up an endpoint for a JSON push service. It creates a `JSON::Webhook` object with the given arguments.

If a `JSON::Webhook` is sunk, it calls the `serve` method which starts listening on the indicated host IP and port and activates a control-C handler to stop the server in an orderly manner.

It takes the following named arguments:

### :host

The name of the endpoint to set up a listening server on. Defaults to calling the `host` method, which by default returns the value of the dynamic variable `$*WEBHOOK-HOST`, the environment variable `WEBHOOK_HOST` or `"localhost"`.

### :port

The port number on which the server will be listening on. Defaults to calling the `port` method, which by default returns the value of the dynamic variable `$*WEBHOOK-PORT`, the environment variable `WEBHOOK_PORT` or `9999`.

### :application

The `Cro::HTTP::Router::RouteSet` compatible object that will be used to run the server with. If not specified, will call the `application` class method with the rest of the named arguments to set up the application.

### additional named argments

Any additional named arguments are passed on as appropriate.

application
-----------

The `application` instance method returns whatever was (implicitely) specified with `:application` named argument to the `new` method.

```raku
my $application = JSON::Webhook.application :$collector, :$processor, ...
JSON::Webhook.new(:$host, :$port, :$application);
```

The `application` class method returns a `Cro::HTTP::Router::RouteSet` compatible object that can be used as the "application" in setting up a `JSON::Webhook` object.

It takes the following named arguments:

### :collector

The object with `JSON::Collector` semantics that will be used to store any incoming JSON payloads. If not specified, it will call the `collector` method, which by default creates a `JSON::Collector` object with any additional named arguments passed.

### :processor

A `Callable` that will be called with the data structure representing the JSON payload that was received, and any names arguments that were part of the request being served. It should return the data structure that should be stored by the collector. If not specified, it will call the `processor` method, which by default returns a `Callable` that will just return the data structure of the JSON payload verbatim.

serve
-----

```raku
my $webhook = JSON::Webhook.new(:$host, :$port, :$application);
say "starting";
$webhook.serve;
say "stopped";
```

The `serve` method takes an instantiated `JSON::Webhook` object, starts listening on the given `host` and `port`, and starts serving requests with the given <application>. Also installs a control-C handler for an orderly shutdown when control-C is pressed.

OVERRIDABLE METHODS
===================

These methods can be overriden by a consumer of the `JSON::Webhook` class to customize behaviour.

host
----

Expected to return a value that can be used as a `:host` argument to `Cro::HTTP::Server.new`.

port
----

Expected to return a value that can be used as a `:port` argument to `Cro::HTTP::Server.new`.

collector
---------

Expected to return an object with `JSON::Collector` semantics.

processor
---------

Expected to return a `Callable` that will take the data structure parsed from a JSON payload, and return a possibly adapted data structure to be stored by the collector.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

COPYRIGHT AND LICENSE
=====================

Copyright 2026 Elizabeth Mattijsen

Source can be located at: https://codeberg.org/lizmat/JSON-Collector . Comments and Pull Requests are welcome.

If you like this module, or what I'm doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

