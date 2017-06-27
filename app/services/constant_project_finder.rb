class ConstantProjectFinder
  def initialize(project_by_dates)
    @project_by_dates = project_by_dates
  end

  def find_project(_project, date)
    project = @project_by_dates[date]
    raise "No project for #{date} only #{@project_by_dates.keys}" unless project
    project
  end
end
