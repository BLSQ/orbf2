class Dhis2Name
  attr_reader :long, :short, :code
  def initialize(long:, short:, code:)
    @long = long
    @short = short
    @code = code
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    self.class == other.class && values == other.values
  end

  def values
    { long:  long,
      short: short,
      code:  code }
  end
end
