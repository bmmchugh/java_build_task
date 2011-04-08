# JavaBuildTask

## DESCRIPTION

Java build tool for [rake](http://rake.rubyforge.org "Rake").

## EXAMPLE

Add the following to your Rakefile:

    require 'java/task'

    JavaBuildTask.new()

Produces the following Rake tasks:

    $ rake -T
    (in /path/to/project)
    rake autotest        # Run autotest
    rake checkstyle      # Check the style of the source
    rake clean           # Removes the build path
    rake compile         # Compiles Java class files to the target
    rake dist            # Copies files required for distribution to the dist...
    rake docs            # Create javadoc documentation
    rake jar             # Generates Java archive file
    rake resources       # Copies resource files to the target
    rake serialver       # Generate serial version UIDs
    rake test            # Runs unit tests
    rake test:compile    # Compiles test Java class files to the test target
    rake test:resources  # Copies test resource files to the test target
    rake test:run        # Runs unit tests

## DEPENDENCIES

  * Ruby (used with 1.8.7)
  * Rake (used with 0.8.7)
  * ZenTest (optional for the autotest task)
  * Java SE Development Kit with the JAVA_HOME environment variable set, or
    the JDK bin found in the PATH environment variable (used with JDK 5
    and 6)
  * JUnit (used with 4.7)
  * Checkstyle (optional used with 5.0)  Checkstyle will also require the
    checkstyle runner found in ext/java/src/com/freerangedata/checkstyle

## TODO

This project was extracted from a large Java project where more flexibility was
needed than is offered with [ant](http://ant.apache.org "Ant").  Some of the
tasks were created specifically to fill the needs of the project and can be
made to suit a more general purpose.

## LICENSE

Copyright (c) 2011 Free Range Data, LLC, released under the MIT license
