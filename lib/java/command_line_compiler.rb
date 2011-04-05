module Java

  class CommandLineCompiler

    attr_accessor :classpath

    def initialize
      yield(self) if block_given?
      self.classpath = [] if self.classpath.nil?
    end

    def compile(source_files)
      if source_files.nil?
        raise "No source files to compile"
      end

      sources_string = nil

      if source_files.is_a?(Array)
        sources_string = Java::CommandLine.join(' ', source_files)
      else
        sources_string = source_files.to_s
      end

      sources_file = nil
      sources_arg = if sources_string.length > 5000
                      sources_file = Tempfile.new('sources')
                      begin
                        sources_file.write(sources_string)
                      ensure
                        sources_file.close
                      end
                      "@#{sources_file.path}"
                    else
                      sources_string
                    end
      result = Java::CommandLine.javac(
        self.classpath,
        self.destination_path,
        self.source_paths,
        sources_arg,
        self.compiler_options,
        self.compiler_system_properties)

      sources_file.unlink if sources_file
      result
    end
  end
end
