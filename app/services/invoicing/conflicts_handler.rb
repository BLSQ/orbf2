# frozen_string_literal: true

module Invoicing
  class Conflict < Struct.new(:message, :mode, :blocking, keyword_init: true); end

  CONFLICTS = [
    Conflict.new(message: "Category option combo is required but is not specified", mode: :equal, blocking: true),
    Conflict.new(message: "Data element not found or not acccessible", mode: :include, blocking: true),
    Conflict.new(message: "Data element not found or not accessible", mode: :equal, blocking: true),
    Conflict.new(message: "must be assigned through data sets to organisation unit", mode: :include, blocking: true),
    Conflict.new(message: "Period type of period", mode: :include, blocking: true),

    Conflict.new(message: "Data value is not a percentage", mode: :starts_with, blocking: true),
    Conflict.new(message: "Data value is not an integer", mode: :starts_with, blocking: true),
    Conflict.new(message: "value_not_zero_or_positive_integer", mode: :starts_with, blocking: true),
    Conflict.new(message: "Data value is not numeric, must match data element type", mode: :starts_with, blocking: true),

    Conflict.new(message: "Value is zero and not significant, must match data element:", mode: :starts_with, blocking: false),

    Conflict.new(message: "is after latest open future period", mode: :include, blocking: false),

    Conflict.new(message: "Current date is past expiry days for period", mode: :include, blocking: true),
    Conflict.new(message: "Data is already approved for data set", mode: :include, blocking: true),
    Conflict.new(message: "is not open for this data set at this time", mode: :include, blocking: true)
  ].freeze

  class ConflictsHandler
    attr_reader :status

    def initialize(status)
      @status = status
    end

    def blocking_conflict?(conflict)
      message = conflict["value"]

      matching = CONFLICTS.find do |config|
        case config.mode
        when :equal
          message == config.message
        when :include
          message.include?(config.message)
        when :starts_with
          message.starts_with?(config.message)
        else
          raise "unsupported mode #{config.mode} in #{config}"
        end
      end

      return matching.blocking if matching

      true
    end

    def raise_if_blocking_conflicts?
      if status.raw_status["status"] == "ERROR"
        raise PublishingError, status.raw_status["description"]
      end

      return unless status.raw_status["conflicts"]

      blocking_conflicts = status.raw_status["conflicts"].select { |c| blocking_conflict?(c) }
      if blocking_conflicts.any?
        messages = blocking_conflicts.map { |conflict| conflict["value"] }.uniq
        raise PublishingError, messages.join(", ")
      end
    end
  end
end
