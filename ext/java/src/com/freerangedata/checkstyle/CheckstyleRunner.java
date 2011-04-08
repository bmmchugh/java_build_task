package com.freerangedata.checkstyle;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

import com.puppycrawl.tools.checkstyle.Checker;
import com.puppycrawl.tools.checkstyle.ConfigurationLoader;
import com.puppycrawl.tools.checkstyle.DefaultLogger;
import com.puppycrawl.tools.checkstyle.PropertiesExpander;
import com.puppycrawl.tools.checkstyle.api.CheckstyleException;

/**
 * Lightweight Checkstyle runner.
 *
 * Usage:
 * <code>java com.freerangedata.checkstyle.CheckstyleRunner config.xml
 * sourcefiles | @argfile</code>
 *
 * Where sourcefiles is one ore more source files to check and @argfile is a
 * file that lists source files to check.  Results are printed to
 * <code>System.out</code> in plain format.
 */
public final class CheckstyleRunner {

    private CheckstyleRunner() {
    }

    public static void main(String[] args) {
        Checker checker = null;
        try {
            checker = new Checker();
            checker.setModuleClassLoader(Checker.class.getClassLoader());
            checker.addListener(new DefaultLogger(System.out, false));
            checker.configure(ConfigurationLoader.loadConfiguration(
                        args[0],
                        new PropertiesExpander(System.getProperties())));
        } catch (CheckstyleException e) {
            System.out.println("Unable to create Checker: " + e.getMessage());
            e.printStackTrace(System.out);
            System.exit(1);
        }

        int errors = checker.process(CheckstyleRunner.fileList(args));
        checker.destroy();
        System.exit(errors);
    }

    private static List<File> fileList(String[] args) {
        ArrayList<String> fileArgs
            = new ArrayList<String>(Arrays.asList(args));
        fileArgs.remove(0);

        ArrayList<String> fileNames = new ArrayList<String>();

        if (fileArgs.get(0).startsWith("@")) {
            String s = CheckstyleRunner.read(fileArgs.get(0).substring(1));
            fileNames.addAll(Arrays.asList(s.split(",\\s*|\\s+")));
        } else {
            fileNames.addAll(fileArgs);
        }

        ArrayList<File> files = new ArrayList<File>();

        for (String fileName : fileNames) {
            files.add(new File(fileName));
        }

        return files;
    }

    private static String read(String fileName) {
        File f = new File(fileName);
        if (!f.exists()) {
            return null;
        }

        FileInputStream in = null;

        try {
            in = new FileInputStream(f);
            byte[] bytes = new byte[(int) f.length()];
            in.read(bytes);
            return new String(bytes);
        } catch (IOException e) {
            System.out.println("Unable to read " + fileName + ": "
                    + e.getMessage());
            e.printStackTrace(System.out);
            System.exit(1);
            return null;
        } finally {
            if (in != null) {
                try {
                    in.close();
                } catch (IOException e) {
                    System.out.println("Failed to close " + fileName + ": "
                            + e.getMessage());
                }
            }
        }
    }
}
