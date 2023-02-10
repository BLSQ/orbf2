require "profiler"

Profiler.profile_method(Invoicing::InvoiceEntity, :fetch_and_solve)
Profiler.profile_method(Invoicing::InvoiceEntity, :publish_to_dhis2)
Profiler.profile_method(Orbf::RulesEngine::FetchAndSolve, :fetch_data)
Profiler.profile_method(Orbf::RulesEngine::FetchAndSolve, :new_solver)
Profiler.profile_method(Orbf::RulesEngine::Solver, :solve)


class CalculationSubscriber < ActiveSupport::LogSubscriber
  def fetch_data(event)
    log_event(event)
  end

  def new_solver(event)
    log_event(event)
  end

  def solve(event)
    log_event(event)
  end

  def fetch_and_solve(event)
    log_event(event)
  end

  def publish_to_dhis2(event)
    log_event(event)
  end

  def logger
    return @logger if @logger
    @logger = Logger.new("log/thing.log")
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime}: #{msg}\n"
    end
    @logger
  end

  # name, started, finished, unique_id, data
  def log_event(event)
    name = event.payload[:name]
    details = event.duration
    debug "[#{event.payload[:identifier]}]  #{color(name, CYAN, true)}  [ #{details} ]"
  end
end

CalculationSubscriber.attach_to :calculation
