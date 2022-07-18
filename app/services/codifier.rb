# frozen_string_literal: true

class Codifier
  def self.codify(string)
    Orbf::RulesEngine::Codifier.codify(string)
  end
end
