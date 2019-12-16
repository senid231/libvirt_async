# LibvirtAsync

Libvirt event async implementation.
Libvirt event api implementation on Fibers based on [libvirt-ruby](https://github.com/qwe/libvirt-ruby) and [async](https://github.com/socketry/async)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'libvirt_async'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install libvirt_async

## Usage

```ruby
require 'libvirt_async'

LibvirtAsync.use_logger!
LibvirtAsync.logger.level = Logger::Severity::DEBUG # optional for debugging
LibvirtAsync.register_implementations!
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/libvirt_async. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/libvirt_async/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LibvirtAsync project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/libvirt_async/blob/master/CODE_OF_CONDUCT.md).
