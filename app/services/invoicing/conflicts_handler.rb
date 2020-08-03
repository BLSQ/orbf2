# frozen_string_literal: true

module Invoicing

  class ConflictsHandler
    def blocking_conflict?(conflict)
      message = conflict["value"]
      if message == "Category option combo is required but is not specified"
        return true
      elsif message.include?("Data element not found or not acccessible")
        return true
      elsif message == "Data element not found or not accessible"
        return true
      elsif message.include?("must be assigned through data sets to organisation unit")
        return true
      elsif message.include?("Period type of period")
        return true
      elsif message.starts_with?("Data value is not a percentage")
        return true
      elsif message.starts_with?("Data value is not an integer")
        return true
      elsif message.starts_with?("Value is zero and not significant, must match data element:")
        return false
      elsif message.starts_with?("value_not_zero_or_positive_integer")
        return true
      elsif message.starts_with?("Data value is not numeric, must match data element type")
        return true
      elsif message.include?("is after latest open future period")
        return false
      elsif message.include?("Current date is past expiry days for period")
        return true
      elsif message.include?("Data is already approved for data set")
        return true
      elsif message.include?("is not open for this data set at this time")
        return true
      end

      true
    end

    def raise_if_blocking_conflicts?(status)
      if status.raw_status["conflicts"]
        blocking_conflicts = status.raw_status["conflicts"].select { |c| blocking_conflict?(c) }
        if blocking_conflicts.any?
          messages = blocking_conflicts.map { |conflict| conflict["value"] }.uniq
          raise PublishingError, messages.join(", ")
        end
      end
    end
  end
end
