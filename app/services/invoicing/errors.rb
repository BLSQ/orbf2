# frozen_string_literal: true

module Invoicing
  class PublishingError < StandardError
  end

  class BlockingConflictsError < PublishingError
  end

  class RequestFailed < PublishingError
  end
end
