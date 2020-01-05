# LibvirtAsync

Libvirt event loop asynchronous implementation on Fibers.
Based on [libvirt-ruby](https://github.com/qwe/libvirt-ruby) and [async](https://github.com/socketry/async).
Allows to receive domain events.
Allows to work with streams in asynchronous mode.

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

`LibvirtAsync.register_implementations!` must be called once per process before connecting to hypervisor.

### Receiving domain events

We can subscribe for event from all hypervisor's domains 
```ruby
require 'libvirt_async'

LibvirtAsync.register_implementations!

connection = Libvirt::open('qemu+tcp://127.0.0.1:16509')

some_object = Object.new

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_LIFECYCLE,
    ->(connection, domain, event, detail, opaque) { 
      puts "LIFECYCLE event #{domain.uuid} #{event} #{detail}" 
    },
    nil, # optional domain, can be omitted
    some_object # will be an opaque in callback, can be omitted
)
```

Or we can subscribe on particular domain

```ruby
require 'libvirt_async'

LibvirtAsync.register_implementations!

connection = Libvirt::open('qemu+tcp://127.0.0.1:16509')
domain = connection.list_all_domains.first

some_object = Object.new

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_LIFECYCLE,
    ->(connection, domain, event, detail, opaque) { 
      puts "LIFECYCLE event #{domain.uuid} #{event} #{detail}" 
    },
    domain, 
    some_object # will be an opaque in callback, can be omitted
)
```

All available domain events:
```ruby
connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_REBOOT,
    ->(connection, domain, opaque) { 
      puts "REBOOT event #{domain.uuid}" 
    }
)

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_RTC_CHANGE,
    ->(connection, domain, utc_offset, opaque) { 
      puts "RTC_CHANGE event #{domain.uuid} #{utc_offset}" 
    }
)

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_WATCHDOG,
    ->(connection, domain, action, opaque) { 
      puts "WATCHDOG event #{domain.uuid} #{action}" 
    }
)

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_IO_ERROR,
    ->(connection, domain, src_path, dev_alias, action, opaque) { 
      puts "IO_ERROR event #{domain.uuid} #{src_path} #{dev_alias} #{action}" 
    }
)

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_IO_ERROR_REASON,
    ->(connection, domain, src_path, dev_alias, action, opaque) { 
      puts "IO_ERROR_REASON event #{domain.uuid} #{src_path} #{dev_alias} #{action}" 
    }
)

connection.domain_event_register_any(
    Libvirt::Connect::DOMAIN_EVENT_ID_GRAPHICS,
    ->(connection, domain, phase, local, remote, auth_scheme, subject, opaque) { 
      puts "GRAPHICS event #{domain.uuid} #{phase} #{local} #{remote} #{auth_scheme} #{subject}" 
    }
)
```

### Taking screenshot

```ruby
require 'libvirt_async'

LibvirtAsync.register_implementations!

connection = Libvirt::open('qemu+tcp://127.0.0.1:16509')
domain = connection.list_all_domains.first

file = File.new("/screenshots/#{domain.uuid}.pnm", 'wb')
stream = LibvirtAsync::StreamRead.new(connection, file)
mime_type = domain.screenshot(stream.stream, 0)
puts "screenshot saving initiated mime_type=#{mime_type}"

# will start screenshot saving
stream.call do |success, reason, io|
  # this block will be called asynchronously on complete or error
  io.close
  if success
   puts "screenshot saved at #{io.path}"
  else
   puts "screenshot was not saved: #{reason}"
  end
end
```

Logging.
```ruby
require 'libvirt_async'

LibvirtAsync.use_logger!
LibvirtAsync.logger.level = Logger::Severity::DEBUG # for debugging
```

Look at [ruby-libvirt Documenation](https://libvirt.org/ruby/documentation.html) for further details.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/libvirt_async. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/libvirt_async/blob/master/CODE_OF_CONDUCT.md).


## Releasing

    $ bundle exec rake release
    $ gem push pkg/libvirt_async-X.Y.Z.gem

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LibvirtAsync project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/libvirt_async/blob/master/CODE_OF_CONDUCT.md).
