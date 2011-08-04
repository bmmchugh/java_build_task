
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

  def self.path_escape(path)
    if / / =~ path
      "\"#{path}\""
    else
      path
    end
  end

  # Run a command and fail the rake task if the command fails
  def self.run(command, verbose = false)
    #puts command if verbose

    system command

    if $? != 0
      fail "Command failed: #$?"
    end
  end
end
