module ResponseFactory
  def self.valid_bulk
    {
      responseType: "ImportSummary",
      status: "SUCCESS",
      importCount: {}
    }.to_json
  end
end