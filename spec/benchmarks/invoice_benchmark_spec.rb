# frozen_string_literal: true

# App level invoice calculation benchmark (project from the DB -> orbf project
# mapping -> rules engine -> export payload), to spot perf regressions when
# upgrading ruby/rails/gems. Excluded from the normal run:
#
#   BENCHMARK=1 bundle exec rspec spec/benchmarks
#
# Appends one JSON line per run to bench/results.jsonl.

require "rails_helper"
require "digest"
require_relative "../workers/project_fixture"

RSpec.describe "Invoice calculation benchmark", benchmark: true do
  include ProjectFixture
  include_context "basic_context"

  ITERATIONS = Integer(ENV.fetch("BENCHMARK_ITERATIONS", 10))
  BENCH_ORG_UNIT_ID = "vRC0stJ5y9Q"
  ORG_UNIT_IDS = %w[
    AhnK8hb3JWm BLVKubgVxkF Bift1B4gjru Bq5nb7UAEGd C9uduqDZr9d DSBXsRQSXUW DmaLM8WYmWv ENHOJz3UH5L Ea3j0kUvyWg
    EmTN0L4EAVi GvFqTavdpGE HPg74Rr7UWp IXJg79fclDm ImspTQPwCqd JLKGG67z7oj JNJIPX9DfaW KIUCimTXf8Q KKkLOTpMXGV
    KuR0y0h0mOM LV2b3vaLRl1 LaxJ6CD2DHq Ls2ESQONh9S M2qEv692lS6 M721NHGtdZV O6uvpzGd5pu OuwX8H2CcRO PD1fqyvJssC
    PLoeN9CaL7z PMa2VCrupOd PQZJPIpTepd Qw7c6Ckb0XC QywkxFudXrC RUCp6OaTSAD T2Cn45nBY0u TEQlaapDQoK TQkG0sX9nca
    U6Kr7Gtpidn Uo4cyJwAhTW VCtF1DbspR5 VGAFxBXz16y Vnc2qIRLbyw Vth0fbpFcsO W5fN3G6y1VI XEyIRFd9pct XJ6DqDkMlPv
    at6UHUQatSo bM4Ky73uMao bPHn9IgjKLC bVZTNrnfn9G cDw53Ej8rju cM2BKSrj9F9 cZtKKa9eJZ3 cgqkFdShPzg ctfiYW0ePJ8
    eIQbndfxQMb fXT1scbEObM fdc6uOvgoji gmen7SXL9CU jCnyQOKQBFX jUb8gELQApl jmIPBj66vD6 kBP1UvZpsNj kJq2mPyFEHo
    kLNQT4KQ9hT kMTHqMgenme lc3eMKXaEfw mTNOoGXuC39 nCh5dBoJVNw nV3OkyzF4US nq7F0t1Pz6t qhqAxPSTUXp qtr8GGlm4gg
    roQ2l7TX0eZ tHUYjt9cU6h u6ZGNI8yUmt uNEhNuBUr0i vRC0stJ5y9Q vn9KJsLyP5f vv1QJFONsT6 wNYYRm2c9EK wicmjKI3xiP
    yP2nhllbQPh
  ].freeze

  let(:program) { create :program }

  let!(:project) do
    project = full_project
    project.save!
    project.update(read_through_deg: false)
    user.save!
    user.program = program
    with_activities_and_formula_mappings(project)
    create_snaphots(project)
    project.entity_group.external_reference = "MAs88nJc9nL"
    project.entity_group.save!
    with_latest_engine(project)
    with_multi_entity_rule(project)
    with_activities_and_formula_mappings(project)
    project
  end

  def stub_dhis2_values_for(project)
    refs = project.activities.flat_map(&:activity_states).map(&:external_reference).uniq.reject(&:empty?).sort
    values = refs.each_with_index.flat_map do |data_element, index|
      ([[BENCH_ORG_UNIT_ID, "2015"]] + (1..12).flat_map { |m| [[BENCH_ORG_UNIT_ID, "2015#{m}"], ["PMa2VCrupO", "2015#{m}"]] })
        .map do |org_unit, period|
          { dataElement: data_element, value: index, period: period, orgUnit: org_unit,
            categoryOptionCombo: "HllvX50cXC0", attributeOptionCombo: "HllvX50cXC0" }
        end
    end
    periods = %w[2014July 2015 201501 201502 201503 2015Q1]
    ORG_UNIT_IDS.each_slice(50) do |slice|
      stub_request(:get, "http://play.dhis2.org/demo/api/dataValueSets?" +
        %w[ds-0 ds-1 ds-2].each_with_index.map { |ds, i| "#{i.zero? ? '' : '&'}dataSet=#{ds}" }.join +
        periods.map { |pe| "&period=#{pe}" }.join +
        slice.map { |id| "&orgUnit=#{id}" }.join + "&children=false")
        .to_return(status: 200, body: JSON.generate(dataValues: values.select { |v| slice.include?(v[:orgUnit]) }))
    end
  end

  # monotonic wall time of the block (benchmark is not a default gem since ruby 4.0)
  def realtime
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  # BENCHMARK_ALLOCATIONS=1: top allocation sites of one calculation, by gem/app file
  def print_allocation_sites(perform)
    require "objspace"
    GC.disable
    ObjectSpace.trace_object_allocations_clear
    ObjectSpace.trace_object_allocations { perform.call }
    sites = Hash.new(0)
    ObjectSpace.each_object do |obj|
      file = ObjectSpace.allocation_sourcefile(obj)
      next unless file

      line = ObjectSpace.allocation_sourceline(obj)
      sites["#{file.sub(%r{.*/gems/}, '').sub(Rails.root.to_s + '/', '')}:#{line}"] += 1
    end
    puts "Top allocation sites:"
    sites.sort_by { |_, count| -count }.first(25).each { |site, count| puts format("%8d %s", count, site) }
  ensure
    ObjectSpace.trace_object_allocations_clear
    GC.enable
  end

  it "calculates the multi entities invoice (latest engine)" do
    stub_dhis2_values_for(project)
    payloads = []
    stub_request(:post, "http://play.dhis2.org/demo/api/dataValueSets")
      .to_return { |request| payloads << request.body; { status: 200, body: "" } }

    worker = InvoiceForProjectAnchorWorker.new
    perform = -> { worker.perform(project.project_anchor.id, 2015, 1, [BENCH_ORG_UNIT_ID]) }

    perform.call # warm up
    GC.start
    allocated_before = GC.stat(:total_allocated_objects)
    perform.call
    allocations = GC.stat(:total_allocated_objects) - allocated_before

    print_allocation_sites(perform) if ENV["BENCHMARK_ALLOCATIONS"]

    times = Array.new(ITERATIONS) do
      GC.start
      realtime(&perform)
    end

    exported = JSON.parse(payloads.last)["dataValues"]
                   .sort_by { |v| v.values_at("dataElement", "orgUnit", "period", "categoryOptionCombo").map(&:to_s) }
    expected = JSON.parse(fixture_content(:scorpio, "invoice_multi_entities_new_engine_v3.json"))["dataValues"]
                   .sort_by { |v| v.values_at("dataElement", "orgUnit", "period", "categoryOptionCombo").map(&:to_s) }
    expect(exported).to eq(expected), "exported values differ from invoice_multi_entities_new_engine_v3.json"
    expect(payloads.size).to eq(ITERATIONS + 2), "expected one export per invoice calculation"

    sorted = times.sort
    report = {
      at:              Time.now.utc.iso8601,
      ruby:            RUBY_VERSION,
      rails:           Rails.version,
      yjit:            defined?(RubyVM::YJIT) && RubyVM::YJIT.respond_to?(:enabled?) && RubyVM::YJIT.enabled?,
      gems:            %w[orbf-rules_engine dentaku hesabu bigdecimal pg].map { |g| [g, Gem.loaded_specs[g]&.version&.to_s] }.to_h,
      iterations:      ITERATIONS,
      exported_values: exported.size,
      digest:          Digest::SHA256.hexdigest(JSON.generate(exported))[0, 16],
      allocations:     allocations,
      median_s:        sorted[sorted.size / 2].round(4),
      min_s:           sorted.first.round(4)
    }
    puts JSON.pretty_generate(report)
    FileUtils.mkdir_p(Rails.root.join("bench"))
    File.open(Rails.root.join("bench", "results.jsonl"), "a") { |f| f.puts(JSON.generate(report)) }
  end
end
