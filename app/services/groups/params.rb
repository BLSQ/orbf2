module Groups
  module Params
    def ensure_whodunnit(params)
      @whodunnit = params.fetch(:dhis2UserId)
      raise ArgumentError, "invalid dhis2UserId (#{whodunnit})" unless whodunnit && whodunnit.size == 11
    end
  end
end
