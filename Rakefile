# frozen_string_literal: true

FileList['tasks/**/*.rake'].each(&method(:import))

desc 'Run all tests'
task ci: %w[test]

task default: :test
