class MockProjectFinder
  def find_project(_date)
    ProjectFactory.new.build
  end
end
