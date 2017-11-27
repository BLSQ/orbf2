class LevelScope
  def facts(package)
    codes = package.states.select(&:activity_level?).map(&:code)
    (1..5).map do |level|
      codes.map { |code| "#{code}_level_#{level}" }
    end.flatten
  end

  def to_fake_facts(package)
    facts(package).map { |code| [code.to_sym, "10"] }.to_h
  end
end
