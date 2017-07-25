class Codifier
  def self.codify(string)
    string.parameterize(separator: "_").gsub("-","_").gsub("__","_")
  end
end
