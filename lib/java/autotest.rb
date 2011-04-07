require 'autotest'

Autotest.add_hook :initialize do |at|
  at.clear_mappings
  %w{.svn/
     bin/
     build/
     config/
     coverage/
     db/
     log/
     rake/
     tmp/}.each do | exception |
    at.add_exception(exception)
  end
  at.add_mapping(%r%^test/src/(.*Test)\.java$%) do |filename, m|
    filename
  end
  at.add_mapping(%r%^src/(.*)\.java%) do |filename, m|
    [filename] + at.files_matching(%r%test/src/#{m[1]}.*Test.java$%)
  end
  at.add_mapping(%r%^generated/(.*)\.java$%) do
    at.files_matching %r%^test/src/.*Test\.java$%
  end
end

class Autotest::Java < Autotest

  def initialize(task, tmp_dir = nil)
    super()
    @task = task
    @tmp_dir = tmp_dir
    self.failed_results_re = /^\d+\) (.*)\((.*)\)/
    self.completed_re = /^Time: \d+\.?\d*$/
  end

  def consolidate_failures(failed)
    filters = new_hash_of_arrays
    failed.each do |test, trace|
      filters[trace] << test
    end
    return filters
  end

  def make_test_cmd(files_to_test)
    return '' if files_to_test.empty?
    files = files_to_test.keys.flatten.join(',')
    tests = if files.length > 5000 && !@tmp_dir.nil? && File.exist?(@tmp_dir)
              tests_input_file = File.join(@tmp_dir, '.autotestfiles')
              File.open(tests_input_file, 'w') do |f|
                f.write(files)
              end
              "@#{tests_input_file}"
            else
              files
            end

    return "rake #{@task} TESTS=#{tests}"
  end
end
