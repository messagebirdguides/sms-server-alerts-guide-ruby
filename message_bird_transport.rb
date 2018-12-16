# Send log messages to MessageBird
#
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

      # Send the notification
      def log(log)
        context = formatter.call(log, self)

        # Shorten log entry
        text = context[:message].length > 140 ? "#{context[:message]}..." : context[:message]

        @client.message_create(@originator, @recipients, text)
      end

      private

      # Use Raw Formatter by default
      def default_formatter
        SemanticLogger::Formatters::Raw.new
      end
    end
  end
end
