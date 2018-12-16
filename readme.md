# SMS Server Alerts

### ⏱ 30 min build time

## Why build SMS server alerts?

For any online service advertising guaranteed uptime north of 99%, being available and reliable is extremely important. Therefore it is essential that any errors in the system are fixed as soon as possible, and the prerequisite for that is that error reports are delivered quickly to the engineers on duty. Providing those error logs via SMS ensures a faster response time compared to email reports and helps companies keep their uptime promises.

In this MessageBird Developer Tutorial, we will show you how to build an integration of SMS alerts into a Ruby application that uses the [Semantic Logger](https://rubygems.org/gems/semantic_logger) logging framework.

## Logging Primer with Semantic Logger

Logging is the default approach for gaining insights into running applications. Before we start building our sample application, let's take a minute to understand two fundamental concepts of logging: levels and transports.

**Levels** indicate the severity of the log item. Common log levels are _debug_, _info_, _warning_, and _error_. For example, a user trying to log in could have the _info_ level, a user entering the wrong password during login could be _warning_ as it's a potential attack, and a user not able to access the system due to a subsystem failure would trigger an _error_.

**Transports** are different channels into which the logger writes its data. Typical channels are the console, files, log collection servers and services or communication channels such as email, SMS or push notifications.

It's possible and common to set up multiple kinds of transport for the same logger but set different levels for each. In our sample application, we write entries of all severities to the console and a log file. The application will send SMS notifications only for log items that have the _error_ level.

## Getting Started

The sample application is built in Ruby and uses Semantic Logger as the logging library. We have also included an example using the [Sinatra framework](http://sinatrarb.com/) to demonstrate web application request logging.

You will need [Ruby](https://www.ruby-lang.org/en/) and [bundler](https://bundler.io/) to run the example.

We've provided the source code in the [MessageBird Developer Tutorials GitHub repository](https://github.com/messagebirdguides/sms-server-alerts-guide-ruby), so you can either clone the sample application with git or download a ZIP file with the code to your computer.

To install the [MessageBird SDK for Ruby](https://rubygems.org/gems/messagebird-rest) and the other dependencies mentioned above, open a console pointed at the directory into which you've saved the sample application and run the following command:

```
bundle install
```

## Building a MessageBird Transport

Semantic Logger enables developers to build custom transports and use them with the logger just like built-in transports such as the file or console transports. They are extensions of the `SemanticLogger::Subscriber` class and need to implement a constructor for initialization as well as the `log()` method. We have created one in the file `message_bird_transport.rb`.

Our SMS alert functionality needs the following information to work:

* A functioning MessageBird API key.
* An originator, i.e., a sender ID for the messages it sends.
* One or more recipients, i.e., the phone numbers of the system engineers that should be informed about problems with the server.
To keep the custom transport self-contained and independent from the way the application wants to provide the information we take all this as parameters in our constructor. Here's the code:

``` ruby
module SemanticLogger
  module Appender
    class MessageBirdTransport < SemanticLogger::Subscriber
      attr_reader :key, :originator, :recipients

      # Create Appender
      #
      # Parameters
      #   level: [:trace | :debug | :info | :warn | :error | :fatal]
      #     Override the log level for this appender.
      #     Default: :error
      #
      #   key: String
      #     The MessageBird API key
      #
      #   originator: String
      #     A sender ID for the messages being sent.
      #
      #   recipients: <String>
      #     One or more recipients to inform.
      #
      def initialize(level: :error, key:, originator:, recipients:, **args, &block)
        # Load and initialize MesageBird SDK
        @client = MessageBird::Client.new(key)
        @originator  = originator
        @recipients = recipients
        super(level: level, **args, &block)
      end
    end
  end
end
```

As you can see, the constructor loads and initializes the MessageBird SDK with the key and stores the other the necessary configuration fields as members of the object, then calls the `super()`-constructor to keep basic custom transport behavior intact.

Now, in the `log()` method, again we start with some default code from the basic custom transport class:

``` ruby
# Send the notification
def log(log)
  context = formatter.call(log, self)
```

Then, we shorten the log entry, to make sure it fits in the 160 characters of a single SMS so that notifications won't incur unnecessary costs or break limits:

``` ruby
# Shorten log entry
text = (context[:message].length > 140) ? "#{context[:message]}..." : context[:message]
```

Finally, we call `client.message_create` to send an SMS notification. For the required parameters _originator_ and _recipients_ we use the values stored in the constructor, and for body we use the (shortened) log text prefixed with the level:

``` ruby
@client.message_create(@originator, @recipients, text)
```

## Configuring our Transport

In `app.rb`, the primary file of our application, we start off by loading the dependencies and the custom transport class. We also use [dotenv](https://rubygems.org/gems/dotenv) to load configuration data from an `.env` file:

``` ruby
require 'dotenv'
require 'sinatra'
require 'messagebird'

require 'semantic_logger'
require_relative 'message_bird_transport'

set :root, File.dirname(__FILE__)

#  Load configuration from .env file
Dotenv.load if Sinatra::Base.development?
```

Copy `env.example` to `.env` and store your information:

```
MESSAGEBIRD_API_KEY=YOUR-API-KEY
MESSAGEBIRD_ORIGINATOR=Logger
MESSAGEBIRD_RECIPIENTS=31970XXXXXXX,31970YYYYYYY
```

You can create or retrieve an API key [in your MessageBird account](https://dashboard.messagebird.com/en/developers/access). The originator can be a phone number you registered through MessageBird or, for countries that support it, an alphanumeric sender ID with at most 11 characters. You can provide one or more comma-separated phone numbers as recipients.

Back in `app.rb`, it's time to set up the logger:

``` ruby
SemanticLogger.add_appender(io: STDOUT, level: :debug)
SemanticLogger.add_appender(file_name: 'app.log', level: :info)
appender = SemanticLogger::Appender::MessageBirdTransport.new(level: :error, key: ENV['MESSAGEBIRD_API_KEY'], originator: ENV['MESSAGEBIRD_ORIGINATOR'], recipients: ENV['MESSAGEBIRD_RECIPIENTS'].split(','))
SemanticLogger.add_appender(appender: appender)

logger = SemanticLogger['TestApp']
```

The `SemanticLogger.add_appender` method takes a variety of optional configuration parameters. As you see in the example, we have added three transports:

* The default Console transport, where we log everything starting with the `debug` level.
* A default File transport, where we log `info` and higher into a file called `app.log`.
* Our previously created custom MessageBirdTransport with all the configuration options taken from our environment file. We convert the comma-separated recipients into an array with `split(',')`. This transport only handles log events with the `error` level.

## Testing the Application

We have added some test log entries in `app.rb` and we have also created a Sinatra route to simulate a 500 server response. To run the application, go to your console and type the following command:

```
ruby app.rb
```

You should see:

* Four messages printed on the console.
* Three log items written to the `app.log` file (open it with a text editor or with `tail` in a new console tab).
* One error message on your phone.

Navigate your browser to http://localhost:4567/. For the successful request, you will see a log entry on the console and in the file.

Now, open http://localhost:4567/simulateError and, along with the request error on your console and the log file, another notification will arrive at your phone.

## Nice work!

And that's it. You've learned how to log with Sinatra and SemanticLogger to create a custom MessageBird transport. You can now take these elements and integrate them into a Ruby production application. Don't forget to download the code from the [MessageBird Developer Tutorials GitHub repository](https://github.com/messagebirdguides/sms-server-alerts-guide-ruby).

## Next steps

Want to build something similar but not quite sure how to get started? Please feel free to let us know at support@messagebird.com, we'd love to help!
