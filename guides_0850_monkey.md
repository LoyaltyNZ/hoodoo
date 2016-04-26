---
layout: default
categories: [guide]
title: "Hoodoo::Monkey"
---

## Purpose

In Ruby, [monkey patching](https://en.wikipedia.org/wiki/Monkey_patch) is often frowned upon. Modifying code by simply overwriting components of a class or a module is risky business - but there are times when it is justified. Debugging or testing scenarios, in particular, can benefit; debug-only or test-only code can be patched in at source code parse-time, leaving no run-time overhead for production releases. It's a way to simulate the compile-time debugging you might use with languages like 'C' while retaining the rapid development advantages of an interpreted language.

Given this, Hoodoo 1.8.0 introduced [`Hoodoo::Monkey`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Monkey.html), a first class citizen that provides a formal, reasonably clean, reversible monkey patching mechanism. It leans on Ruby 2 features which allow replacement method implementations to call the original via `super` - it "feels like" writing a subclass rather than a patch.



## In detail

The [`Hoodoo::Monkey` RDoc]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Monkey.html) includes a lot of background information and a series of examples which cover almost everything you need. There's not a lot left to cover in a Hoodoo Guide given the relative simplicity of the monkey patching system.



### Within services

If you're using the [service shell]({{ site.baseurl }}/guides_0100_fundamentals.html#Shell) as the basis for a service, then in revisions from 2016-04-26 onwards you'll find a folder `service/monkeys` which is auto-included _after_ all the other service folders. Put your monkey patches here. Otherwise, use whatever inclusion scheme you feel is appropriate.

#### Example

A monkey patch doesn't necessarily have to replace a method; it can add one which isn't already present. For example, a service resource implementation class might not already define a `before` or `after` filter method, but a monkey patch might add one; it should still call `super`, of course, just in case the implementation is subsequently updated.

```ruby
module AnalyticsMonkey
  module InstanceExtensions
    def after( context )
      if some_conditions_related_to_context?
        data = { :context_related_data => 'context-related stuff' }

        Hoodoo::Services::Middleware.logger.report(
          :info,
          interaction.target_interface.resource || '(unknown)',
          :analytics,
          data
        )
      end

      super( context )
    end
  end
end

Hoodoo::Monkey.register( extension_module: AnalyticsMonkey, target_unit: SomeImplementation )
Hoodoo::Monkey.enable( extension_module: AnalyticsMonkey )
```



### Within Hoodoo

Hoodoo uses a naming convention to mark parts of its normally-internal implementation which are exposed as public interfaces. Such methods start with the name `monkey_`; use the RDoc search field with text `monkey` to get a list of these. Methods thus named _must not_ be called by external code. They're considered very much an implementation detail. They may refer to input data or instance data which is not ordinarily exposed to external callers and may change without notice.

The potential fragility of a patch based upon what amounts to an internal implementation method is alleviated if you can simply act, as per RDoc recommendation, as a filter; modify input data or output data while deferring to the original implementation through `super`. If you require a more invasive change, then you'll either have to be much more careful to maintain your patch when Hoodoo updates occur, or consider sending in a Hoodoo pull request that adds the required features to the core code.

#### Example

Hoodoo's middleware uses a Hoodoo monkey for optional NewRelic cross-application tracing around inter-resource calls for on-queue architectures. Due to the use of a monkey, this only ever introduces any kind of overhead if it is opted into. Otherwise, the code is literally not present - no conditional branches, no subclasses, nothing. See the [source code](https://github.com/LoyaltyNZ/hoodoo/blob/master/lib/hoodoo/monkey/patch/newrelic_traced_amqp.rb) for details.



## Further reading

Remember, RDoc has deeper technical information about all of the classes and methods involved:

* [Monkey module]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Monkey.html)
* [`register`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Monkey.html#method-c-register)
* [`enable`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Monkey.html#method-c-enable)
* [`disable`]({{ site.custom.rdoc_root_url }}/classes/Hoodoo/Monkey.html#method-c-disable)
