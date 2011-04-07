require 'rake/tasklib'
require 'java/command_line'

module Java
  module TaskMethods

    def define_compile_task(
      classpath,
      source_path,
      target_path,
      name = :compile,
      temp_file_path = nil,
      compiler_options = {},
      compiler_system_properties = {})

      temp_file_path = target_path if temp_file_path.nil?
      directory target_path
      task name => target_path do |t|
        source_paths = source_path.to_a
        sources = []
        source_paths.each do |path|
          FileList["#{path}/**/*.java"].each do |source|
            target = source.sub(path, target_path)
            target.sub!('.java', '.class')
            unless File.exists?(target) && File.mtime(target) > File.mtime(source)
              sources << source
            end
          end
          unless sources.empty?
            sources_string = Java::CommandLine::join(' ', sources)
            sources_arg = if sources_string.length > 5000
                            sources_input_file = File.join(
                              temp_file_path,
                              '.sources')
                            File.open(sources_input_file, 'w') do |f|
                              f.write(sources_string)
                            end
                            "@#{sources_input_file}"
                          else
                            sources_string
                          end
            Java::CommandLine::javac(
              classpath,
              target_path,
              source_paths,
              sources_arg,
              compiler_options,
              compiler_system_properties)
          end
        end
      end
    end

    def define_resources_task(
      source_path,
      target_path,
      name = :resources,
      excludes = [],
      include_java = false)

      source_paths = [source_path].flatten
      source_paths.each do |source_path|
        sources = FileList.new("#{source_path}/**/*") do |fl|
          unless include_java
            fl.exclude(/.*\.java$/)
          end
          excludes.to_a.each do |exclude|
            fl.exclude(exclude)
          end
        end
        sources.each do |source|
          target = source.sub(source_path, target_path)
          if File.directory?(source)
            directory target
          else
            file target => source do
              cp source, target, :verbose => true
            end
          end
          task name => target
        end
      end
    end

    def define_copy_task(
      source_path, target_path, name = :copy, excludes = [], include_java = false)

      task name do |t|
        source_paths = source_path.to_a
        source_paths.each do |source_path|
          sources = FileList.new(File.join(source_path, '**', '*')) do |fl|
            unless include_java
              fl.exclude(/\.java$/)
            end
            excludes.to_a.each do |exclude|
              fl.exclude(exclude)
            end
          end
          sources.each do |source|
            target = source.sub(source_path, target_path)
            if File.directory?(source)
              mkdir target unless File.exist?(target)
            else
              copy(source, target)
            end
          end
        end
      end
    end

    def define_jar_task(
      source_path, target_name, name = :jar, includes = '.')

      task name do |t|
        unless includes.empty?
          Java::CommandLine::jar(target_name, source_path, Java::CommandLine::join(' ', includes))
        end
      end
    end
  end

  class BuildTask < Rake::TaskLib
    include TaskMethods

    attr_accessor :name
    attr_accessor :source
    attr_accessor :test_source
    attr_accessor :build_path
    attr_accessor :target
    attr_accessor :test_target
    attr_accessor :doc_target
    attr_accessor :doc_packages
    attr_accessor :dist_target
    attr_accessor :dist_target_lib
    attr_accessor :dist_target_lib_vendor
    attr_accessor :dist_target_webinf
    attr_accessor :dist_target_webinf_lib
    attr_accessor :dist_target_webinf_lib_vendor
    attr_accessor :dist_name
    attr_accessor :dist_version
    attr_accessor :lib_path
    attr_accessor :test_lib_path
    attr_accessor :classpath
    attr_accessor :test_classpath
    attr_accessor :web_app_path
    attr_accessor :checkstyle_xml
    attr_accessor :checkstyle_basedir
    attr_accessor :doc_options
    attr_accessor :system_properties
    attr_accessor :compiler_system_properties
    attr_accessor :compiler_options
    attr_accessor :dependency_dist_paths
    attr_accessor :dependency_dist_tasks
    attr_accessor :config_paths
    attr_accessor :dist_lib_excludes

    def initialize(root_path = '.')
      self.root = root_path
      @system_properties = {}
      @compiler_system_properties = {}
      @compiler_options = ['-Xlint', '-Xlint:path']
      @doc_packages = []
      @config_paths = []
      @dependency_dist_paths = []
      @dependency_dist_tasks = []
      @doc_options = []
      @dist_lib_excludes = []
      @web_app_path = nil
      @classpath = []
      @test_classpath = []
      @dist_version = nil
      yield(self) if block_given?
      @classpath = [@target, File.join(@lib_path, '**', '*.jar')] + @classpath
      @test_classpath = [@classpath,
                         @test_target,
                         File.join(@test_lib_path, '**', '*.jar')] +
                         @test_classpath
      define
    end

    def root=(path)
      @root = path
      @source = [File.join(path, 'src')]
      @test_source = [File.join(path, 'test', 'src')]
      @build_path = File.join(path, 'build')
      @target = File.join(@build_path, 'classes')
      @test_target = File.join(@build_path, 'test')
      @doc_target = File.join(@build_path, 'docs')
      @dist_name = File.basename(path)
      self.dist_path = File.join(@build_path, 'dist')
      @lib_path = File.join(path, 'lib')
      @test_lib_path = File.join(path, 'test', 'lib')
      @checkstyle_xml = File.join(path, '..', 'checkstyle.xml')
      @checkstyle_basedir = path
    end

    def dist_path=(path)
      @dist_target = path
      @dist_target_lib = File.join(@dist_target, 'lib')
      @dist_target_lib_vendor = @dist_target_lib
      @dist_target_webinf = File.join(@dist_target, 'WEB-INF')
      @dist_target_webinf_lib = File.join(@dist_target_webinf, 'lib')
      @dist_target_webinf_lib_vendor = @dist_target_webinf_lib
    end

    def define
      directory @target
      directory @doc_target
      directory @dist_target
      directory @dist_target_lib
      directory @dist_target_webinf_lib
      directory @dist_target_lib_vendor
      directory @dist_target_webinf_lib_vendor

      desc("Removes the build path")
      task :clean do
        rm_r @build_path if File.exists?(@build_path)
      end

      desc("Copies resource files to the target")
      task :resources => @target
      define_resources_task(@source, @target, :resources)

      @config_paths.each do |config_path|
        define_resources_task(
          config_path, @target, :resources,
          [/.*\.properties$/,
           /.*\.yml$/,
           /.*\.template$/])
      end

      desc("Compiles Java class files to the target")
      compile_task = task :compile => :resources
      define_compile_task(
        @classpath,
        @source,
        @target,
        :compile,
        @build_path,
        @compiler_options,
        @compiler_system_properties)

      desc("Create javadoc documentation")
      task :docs => @doc_target do
        cd @root unless @root.nil?
        Java::CommandLine::javadoc(
          @classpath, @source, @doc_target, @doc_packages, @doc_options)
      end

      task :dist_lib do
        if @web_app_path.nil?
        Rake::Task[@dist_target_lib].invoke
        else
          Rake::Task[@dist_target_webinf_lib].invoke
        end
      end

      task :dist_lib_vendor do
        if @web_app_path.nil?
          Rake::Task[@dist_target_lib_vendor].invoke
        else
          Rake::Task[@dist_target_webinf_lib_vendor].invoke
        end
      end

      desc("Generates Java archive file")
      task :jar => [:compile, :dist_lib]

      if @web_app_path.nil?
        define_jar_task(
          @target, File.join(@dist_target_lib, "#{distribution_name}.jar"))
      else
        define_jar_task(
          @target, File.join(@dist_target_webinf_lib, "#{distribution_name}.jar"))
      end

      desc("Copies files required for distribution to the distribution target")
      task :dist => @dependency_dist_tasks + [:jar, :dist_lib_vendor] do
        cd @root unless @root.nil?
      end

      if @web_app_path.nil?
        define_resources_task(
          @lib_path, @dist_target_lib_vendor, :dist, @dist_lib_excludes)
        unless @dependency_dist_paths.empty?
          define_copy_task(@dependency_dist_paths,
                           @dist_target,
                           :dist,
                           @dist_lib_excludes)
        end
      else
        define_resources_task(@web_app_path, @dist_target, :dist)
        define_resources_task(
          @lib_path, @dist_target_webinf_lib_vendor, :dist, @dist_lib_excludes)
        unless @dependency_dist_paths.empty?
          define_copy_task(
            @dependency_dist_paths,
            @dist_target_webinf,
            :dist,
            @dist_lib_excludes)
        end
      end

      unless @web_app_path.nil?
        desc("Creates distribution war")
        task :war => :dist
        define_jar_task(
        @dist_target, File.join(@build_path, "#{distribution_name}.war"), :war)
      end

      desc("Generate serial version UIDs")
      task :serialver => :compile do
        cd @root unless @root.nil?

        class_names = []
        @source.each do |s|
          class_names <<
            FileList[File.join(s, '**', '*.java')].collect do |source_file|
              if File.exist?(source_file)
                source_file = File.expand_path(source_file)
                if source_file =~ /^#{s}/
                  source_file.gsub!(/#{s}\/|\.java/, '')
                  source_file.gsub!(/(\/|\\)/, '.')
                  source_file
                else
                  nil
                end
              else
                source_file
              end
            end.compact.uniq
        end

        Java::CommandLine::serialver(@classpath, class_names.flatten)
      end

      desc("Check the style of the source")
      task :checkstyle => @build_path do
        cd @root unless @root.nil?
        source_files = []
        @source.each do |s|
          source_files << File.join(s, '**', '*.java')
        end
          @test_source.each do |s|
          source_files << File.join(s, '**', '*.java')
        end
        test_files = if ENV['TESTS'].nil?
                       FileList.new(source_files)
                     else
                       tests = ENV['TESTS']
                       if tests.start_with?('@')
                         tests = File.read(tests[1..-1])
                       end
                       tests.split.join(',').split(',').compact
                     end

        test_files = test_files.collect do |d|
          if File.exist?(d)
            if d =~ /.*\.java$/
              File.expand_path(d)
            end
          end
        end.compact.uniq

        if test_files.empty?
          puts "No files to audit"
        else
          test_files_string = Java::CommandLine::join(' ', test_files);
          test_files_arg = if test_files_string.length > 5000
                             test_files_input_file = File.join(
                               @build_path,
                               '.checkstylesources')
                             File.open(test_files_input_file, 'w') do |f|
                               f.write(test_files_string)
                             end
                             "@#{test_files_input_file}"
                           else
                             test_files_string
                           end
          Java::CommandLine::java(
               @test_classpath,
               'com.freerangedata.checkstyle.CheckstyleRunner',
               @checkstyle_xml,
               test_files_arg,
               @system_properties.merge('basedir' => @checkstyle_basedir))
        end
      end

      begin
        require 'autotest'
        desc("Run autotest")
        task :autotest => @build_path do |t|
          task_name_parts = t.name.split(':')
          task_name_parts[-1] = 'test'
          cd @root unless @root.nil?
          require 'java/autotest'
          Autotest::Java.new("#{task_name_parts.join(':')}", @build_path).run
        end
      rescue LoadError
      end

      desc("Runs unit tests")
      task :test => [:checkstyle, 'test:run']

      namespace :test do

        directory @test_target

        desc("Copies test resource files to the test target")
        task :resources => @test_target
        define_resources_task(@test_source, @test_target, :resources)

        desc("Compiles test Java class files to the test target")
        task :compile => [compile_task, :resources]
        define_compile_task(
          @test_classpath,
          @test_source,
          @test_target,
          :compile,
          @build_path,
          @compiler_options,
          @compiler_system_properties)

        desc("Runs unit tests")
        task :run => [:compile] do
          cd @root unless @root.nil?
          test_files = if ENV['TESTS'].nil?
                         FileList.new do |fl|
                           @test_source.to_a.each do |ts|
                             fl.include(File.join(ts, '**', '*Test.java'))
                           end
                         end
                       else
                         tests = ENV['TESTS']
                         if tests.start_with?('@')
                           tests = File.read(tests[1..-1])
                         end
                         tests.split.join(',').split(',').compact
                       end

          Java::CommandLine::test(@test_classpath,
               test_files.collect { |d|
                 if File.exist?(d)
                   d = File.expand_path(d)
                   ts_regex = "(#{@test_source.to_a.join('|')})"
                   if d =~ /^#{ts_regex}/
                     d.gsub!(/#{ts_regex}\/|\.java/, '')
                     d.gsub!(/(\/|\\)/, '.')
                     d
                   else
                     nil
                   end
                 else
                   d
                 end }.compact.uniq,
               @system_properties)
        end
      end
    end

    def distribution_name
      @dist_name + distribution_number
    end

    def distribution_number
      if @dist_version.nil?
        return ''
      end
      "-#{@dist_version.to_f}"
    end
  end
end
