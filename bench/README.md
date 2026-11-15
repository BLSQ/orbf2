# Invoice calculation benchmarks

Track perf regressions during the ruby/rails upgrade. Each run appends a JSON
line to `results.jsonl` (ruby, rails, gem versions, median/min seconds,
allocations, digest of the exported values: the digest must not change).

    RUBY_VERSION=2.5.8 docker compose -f docker-compose.test.yml run --rm \
      -e BENCHMARK=1 test bundle exec rspec spec/benchmarks

The rules engine has its own one (Liberia project, ~32k equations):
`bundle exec ruby bench/invoice_bench.rb` in orbf-rules_engine.

Compare runs from the same machine only.
