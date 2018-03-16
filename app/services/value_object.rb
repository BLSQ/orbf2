require "active_support/core_ext/class/attribute"

class ValueObject
  class_attribute :_attributes
  self._attributes = []

  def initialize(hash)
    check_args_present!(hash)
    hash.each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    after_init
    freeze
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    self.class == other.class && values == other.values
  end

  protected

  def values
    self.class._attributes.map { |field| send(field) }
  end

  private

  def after_init
    # override at will
  end

  def check_args_present!(hash)
    return if (hash.keys & self.class._attributes).count == self.class._attributes.count
    raise "#{self.class} : incorrect number of args no such attributes: extra : #{hash.keys - self.class._attributes} missing: #{self.class._attributes - hash.keys}  possible attributes: #{self.class._attributes}"
  end

  class << self
    def attributes(*attrs)
      self._attributes = _attributes.dup

      attrs.each { |attr| attribute attr }
    end

    def attribute(attr)
      self._attributes = _attributes.concat([attr])
      define_method attr do
        instance_variable_get("@#{attr}")
      end
    end

    def with(hash)
      new(hash)
    end
  end
end
