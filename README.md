# Rack::Session::Moped

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'rack-session-moped'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-session-moped

## Usage

Simple (localhost:27017 db:rack, collection:sessions)

    use Rack::Session::Moped

Set Moped Session

    session = Moped::Session.new(['localhost:27017'])
    use Rack::Sessionn::Moped, {
      session: session
    }

Set Config

    use Rack::Sessionn::Moped, {
      seeds: ['127.0.0.1:27017'],
      db: 'rack_test',
      collection: 'sessions_test'
    }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License
[rack-session-mongo](http://github.com/aoyagikouhei/rack-session-moped) is Copyright (c) 2012 [Kouhei Aoyagi](http://github.com/aoyagikouhei)(@[aoyagikouhei](http://twitter.com/aoyagikouhei)) and distributed under the [MIT license](http://www.opensource.org/licenses/mit-license).
