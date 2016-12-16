class MockProjectFinder
  def find_project(_project, _date)
    ProjectFactory.new.build
  end
end
