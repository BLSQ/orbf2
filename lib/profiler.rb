module Profiler

  module ProfilingMethods
    def clean_method_name(method)
      method.to_s.gsub(/[\?\!]/, "")
    end

    def profile_method(klass, method)
      clean        = clean_method_name(method)
      name = klass.to_s + " " + method.to_s

      with_profiling    = ("#{clean}_with_instrumentation").intern
      without_profiling = ("#{clean}_without_instrumentation").intern

      if klass.send :method_defined?, with_profiling
        return # dont double profile
      end

      klass.send :alias_method, without_profiling, method
      klass.send :define_method, with_profiling do |*args, &orig|
        puts "#{Time.now} Instrumenting #{method}.calculation"
        ActiveSupport::Notifications.instrument("#{method}.calculation") do |payload|
          payload[:identifier] = profile_id if respond_to?(:profile_id)
          payload[:name] = name
          self.send without_profiling, *args, &orig
        end
      end
      klass.send :alias_method, method, with_profiling
    end

    def profile_singleton_method(klass, method)
      profile_method(singleton_class(klass), method)
    end
  end

  extend ProfilingMethods
end
