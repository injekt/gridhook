require 'active_support/core_ext/hash/except'

module Gridhook
  class Event

    # Process a String or stream of JSON and execute our
    # event processor.
    #
    # body - A String or stream for MultiJson to parse
    #
    # Returns nothing.
    def self.process(body, params = {})
      begin
        event = MultiJson.load(body)
        if event.is_a?(Array)
          process_events event
        else
          process_event event
        end
      rescue MultiJson::LoadError
        process_event params.except(:controller, :action)
      end
    end

    # The original Hash of attributes received from SendGrid.
    attr_reader :attributes

    def initialize(attributes)
      @attributes = attributes.with_indifferent_access
    end

    # An alias for returning the type of this event, ie:
    # sent, delivered, bounced, etc
    def name
      attributes[:event]
    end
    alias event name

    # Returns a new Time object from the event timestamp.
    def timestamp
      Time.at((attributes[:timestamp] || Time.now).to_i)
    end

    # A helper for accessing the original values sent from
    # SendGrid, ie
    #
    # Example:
    #
    #   event = Event.new(event: 'sent', email: 'lee@example.com')
    #   event[:event]  #=> 'sent'
    #   event['email'] #=> 'lee@example.com' # indifferent access
    def [](key)
      attributes[key]
    end

    class << self
      private

      def process_events(events)
        events.each { |e| process_event e }
      end

      def process_event(event)
        processor = Gridhook.config.event_processor
        if processor.respond_to?(:call)
          processor.call Event.new(event)
        else
          raise InvalidEventProcessor, "Your event processor is nil or "\
            "does not response to a `call' method."
        end
      end
    end

  end
end