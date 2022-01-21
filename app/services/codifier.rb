# frozen_string_literal: true

class Codifier
  def self.codify(string)
    string.parameterize(separator: "_").tr("-", "_").gsub("__", "_")
  end
end
