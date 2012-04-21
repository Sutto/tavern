# Tavern

Tavern is a simple implementation of Pub / Sub for Ruby applications, allowing one
to subscribe to topics (named by a:b:c) and to then publish events. It's designed
to have a minimal surface area for the api to make it simple to integrate into other
systems (e.g. so you can publish events over a network).

## Installation

Add this line to your application's Gemfile:

    gem 'tavern'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tavern

## Usage


The core of Tavern is a `Tavern::Hub`, a default one which can be accessed at `Tavern.hub`.

The core methods on this object (and any new Taver Hub) are:

* `hub.subscribe(topic, callable = nil, &block)` - Creates a subscription for the given topic
  using either a callable object or a block. Will return the instance of the subscription. Note
  that this will also match any child notifications - e.g. publishing `a:b:c` will match subscriptions
  for `a:b` and `a`. The callable should take one argument which includes an environment merged with
  some extra details.
* `hub.publish(topic, context = {})` - Publishes an event with a given name, including the specified
  context optionally passed into the callable. Topics should be of the form `a:b:c` with no limit on items.
  Will return the full published metadata.
* `hub.unsubscribe(subscription)` - Given a return from `hub.subscribe`, will unsubscribe it and prevent
  it from receiving any new messages.

The idea behind this decoupled architecture is that it doesn't matter how the middle layer is implemented,
you can just publish and receive messages with no worries. At the moment, subscriptions happen in app.

For conveinience sake, we also proxy `subscribe` and `publish` on the `Tavern` object to the default hub
at `Tavern.hub`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
