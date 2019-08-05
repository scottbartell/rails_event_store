# frozen_string_literal: true

module RubyEventStore
  class Dispatcher
    def call(subscriber, event, _)
      subscriber = subscriber.new if Class === subscriber
      subscriber.call(event)
    end

    def verify(subscriber)
      begin
        subscriber_instance = Class === subscriber ? subscriber.new : subscriber
      rescue ArgumentError
        false
      else
        subscriber_instance.respond_to?(:call)
      end
    end

    def inspect
      "#<#{self.class}:0x#{__id__.to_s(16)}>"
    end
  end
end
