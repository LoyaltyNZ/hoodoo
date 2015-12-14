---
layout: default
categories: [home]
title: Home
---

## Welcome

### With a subheading

Lorem ipsum dolor sit amet, _consectetur adipiscing_ elit. Mauris **sed semper enim**. Vivamus `lorem` enim, molestie sed mollis et, fermentum ac quam. Suspendisse pharetra nulla id lectus blandit, at imperdiet felis malesuada. Etiam eget augue aliquam, semper nibh sit amet, scelerisque odio. Nunc `finibus mi` ut mi faucibus iaculis. Phasellus porttitor eu ligula ut mollis. Nullam ultrices mattis sagittis. Etiam vitae risus eu dui fringilla gravida et quis sapien. Cras vehicula ullamcorper nibh. Ut dapibus ex ac tempor sodales. Etiam efficitur metus erat, ac dapibus dolor fringilla et. Maecenas pellentesque metus eu condimentum ornare. Suspendisse eget odio ut felis fermentum vulputate.

Praesent at tristique leo. Integer id bibendum velit. Vivamus a velit nec nisi tincidunt commodo. Etiam imperdiet tellus et lacus pellentesque, id sollicitudin augue congue. Praesent fringilla nibh nisi, at auctor nibh sagittis et. Mauris sed eros nec urna imperdiet pretium in vitae libero. Maecenas placerat nibh non nisl fermentum, vitae pulvinar ex accumsan.

> **Important:** Cras accumsan molestie ante, id ullamcorper nulla cursus ut. Morbi tincidunt libero sed ultricies tincidunt. In interdum, mi eget pulvinar vestibulum, arcu eros imperdiet turpis, non luctus risus arcu tincidunt ex. Maecenas ullamcorper purus quam. Duis mollis suscipit metus sit amet luctus. Nulla accumsan rutrum dignissim.

### Another subheading

Fusce tempor tellus quis quam tincidunt ultricies. Duis eget nibh eleifend, auctor orci eget, vulputate magna. Ut at sollicitudin mi. Integer mattis consectetur risus. Etiam non sapien pharetra, ultrices felis et, finibus elit. Mauris scelerisque nisl eleifend turpis volutpat egestas. Vestibulum in odio commodo, laoreet leo id, imperdiet eros. Phasellus in auctor dolor. Maecenas cursus lacinia odio, nec ornare sapien tempor id. Mauris mattis semper metus, at luctus felis tincidunt non.

## New section

Some introductory text.

### Subheading

#### Fourth level

Ut laoreet condimentum dui, a ultrices mi semper quis. Nullam sollicitudin ipsum quis quam iaculis vehicula. Quisque vel libero justo. Nullam quis nibh mauris. Quisque a pellentesque lectus. Quisque ultricies, nulla eget ultricies venenatis, lorem lectus aliquet orci, ut ullamcorper quam elit a mauris. Nunc placerat luctus eros, sit amet molestie enim porta id.

Some code from http://sandbox.mc.edu/ at ~bennet/ruby/code/csim_rb.html:

```ruby
# This is a "yes gate" or amplifier.  It just forwards its input to all its
# outputs
class Connector < LimitedGate
  def value
    return @inputs[0]
  end

  # We can also use it as a one-bit input device.
  def send(v)
    self.signal(0,v)
  end
end

# D Flip-Flop.  Level-triggered.  First input is D, second is clock.
class FlipFlop < LimitedGate
  def initialize
    super(2)
  end
  def value
    return (if @inputs[1] then @inputs[0] else @outval end)
  end
end
```

#### Fourth level

Curabitur et posuere nisi, in aliquam mauris. Nam fermentum, nisi nec scelerisque molestie, erat lorem porttitor lectus, id fermentum tortor ligula vel nisl. Praesent semper sapien nec sem tincidunt egestas id vel massa. Nunc malesuada ex in mi vehicula, quis mollis magna molestie. Nullam molestie placerat auctor. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Vivamus eu massa nulla. Phasellus nec nisl ut eros gravida faucibus sit amet sed tortor. Curabitur tincidunt at mi sit amet blandit.