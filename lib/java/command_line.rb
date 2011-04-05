
module Java

  module CommandLine

    def self.path(*args)
      join(File::PATH_SEPARATOR, args)
    end

    def self.join(separator, *args)
      FileList.new(args.flatten) do |fl|
        fl.resolve
      end.collect do |f|
        path_escape(f)
      end.join(separator)
    end

    # Run a command and fail the rake task if the command fails
    def self.run(command, verbose = false)
      #puts command if verbose

      system command

      if $? != 0
        fail "Command failed: #$?"
      end
    end

    def self.jar(jar_file, path, includes = '.')
      run "#{java_command('jar')} cvf #{path_escape(jar_file)} -C #{path_escape(path)} #{includes}", true
    end

    def self.path_escape(path)
      if / / =~ path
        "\"#{path}\""
      else
        path
      end
    end

    def self.war(war_file, path)
      jar(war_file, path)
    end

    def self.javac(classpath, target, sourcepath, sourcefiles, *args)
      system_properties = {}
      if args.last.is_a?(Hash)
        system_properties = args.pop
      end

      system_properties = system_properties.collect do |key, value|
        "-D#{key}=#{value}"
      end.join(' ')

      compiler_options = []
      if args.last.is_a?(Array)
        compiler_options = args.pop
      end

      compiler_options = compiler_options.collect do |value|
        value
      end.join(' ')

      run "#{java_command('javac')} #{system_properties} #{compiler_options} -source 5 -target 5 -sourcepath #{path(sourcepath)} -classpath #{path(classpath)} -d #{target} #{sourcefiles}", true
    end

    def self.test(classpath, test_files, system_properties = {})
      junit(classpath, test_files, system_properties)
    end

    def self.junit(classpath, test_files, system_properties = {})
      java(classpath,
           'org.junit.runner.JUnitCore',
           test_files,
           system_properties)
    end

    def self.java(classpath, class_to_run, *args)
      system_properties = {}

      if args.last.is_a?(Hash)
        system_properties.merge!(args.pop)
      end

      system_properties = system_properties.collect do |key, value|
        "-D#{key}=#{value}"
      end.join(' ')

      run "#{java_command('java')} #{system_properties} -cp #{path(classpath)} #{class_to_run} #{args.flatten.join(' ')}", true
    end

    def self.javadoc(classpath, sourcepath, target, packages, options = [])
      javadoc_options = options.join(' ')
      run "#{java_command('javadoc')} #{javadoc_options} -d #{target} -classpath #{path(classpath)} -sourcepath #{path(sourcepath)} #{join(' ', packages)}", true
    end

    def self.serialver(classpath, classnames)
      run "#{java_command('serialver')} -classpath #{path(classpath)} #{join(' ', classnames)}", true
    end

    def self.java_command(command)
      if ENV['JAVA_HOME']
        command.insert(0, ENV['JAVA_HOME'] + '/bin/')
      end

      command
    end
  end
end
