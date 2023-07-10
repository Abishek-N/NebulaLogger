//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Class used for tracking & parsing stack traces
 * @see Logger
 * @see LogEntryBuilder
 */
public without sharing class LoggerStackTrace {
    private final static Set<String> IGNORED_APEX_CLASSES = new Set<String>{ LoggerStackTrace.class.getName() };
    private final static String NEW_LINE_DELIMITER = '\n';

    public String apexTopLevelClassName { get; private set; }
    public String apexInnerClassName { get; private set; }
    public Integer apexCodeLineNumber { get; private set; }
    public String apexMethodName { get; private set; }
    public String originLocation { get; private set; }
    public String parsedStackTraceString { get; private set; }

    public static void ignoreOrigin(System.Type apexType) {
        IGNORED_APEX_CLASSES.add(apexType.getName());
    }

    public static void ignoreOrigins(Set<System.Type> apexTypes) {
        for (System.Type apexType : apexTypes) {
            IGNORED_APEX_CLASSES.add(apexType.getName());
        }
    }

    public LoggerStackTrace() {
        this(new System.DmlException());
    }

    public LoggerStackTrace(Exception apexException) {
        this(apexException?.getStackTraceString());
    }

    public LoggerStackTrace(String apexStackTraceString) {
        this.setApexClassDetails(apexStackTraceString);
    }

    private void setApexClassDetails(String apexStackTraceString) {
        if (this.isValidStackTrace(apexStackTraceString) == false) {
            return;
        }

        // In a managed package, we can end up with an invalid (unhelpful) stack trace, so only store when valid
        List<String> cleansedStackTraceLines = this.getCleansedStackTraceLines(apexStackTraceString);
        this.parsedStackTraceString = String.join(cleansedStackTraceLines, NEW_LINE_DELIMITER);
        if (this.isValidStackTrace(this.parsedStackTraceString)) {
            String firstStackTraceLine = cleansedStackTraceLines.get(0);
            String cleanedOriginLocation = firstStackTraceLine;
            if (cleanedOriginLocation.contains(':')) {
                cleanedOriginLocation = cleanedOriginLocation.substringBefore(':');
            }
            if (cleanedOriginLocation.startsWith('Class.')) {
                cleanedOriginLocation = cleanedOriginLocation.substringAfter('Class.');
            }

            this.originLocation = cleanedOriginLocation;

            // Example anonymous block: AnonymousBlock: line 9, column 1
            // Example top-level class: Class.ExampleClassWithLogging.throwSomeException: line 25, column 1
            // Example inner class: Class.ExampleClassWithLogging.SomeInnerClass.doSomethingElse(): line 97, column 1
            String apexCodeLineNumberString = firstStackTraceLine.substringAfter('line ').substringBefore(',');
            if (String.isNotBlank(apexCodeLineNumberString) == true) {
                this.apexCodeLineNumber = Integer.valueOf(apexCodeLineNumberString);
            }
            List<String> originLocationPieces = cleanedOriginLocation.split('\\.');
            this.apexTopLevelClassName = originLocationPieces.get(0);
            this.apexInnerClassName = originLocationPieces.size() == 3 ? originLocationPieces.get(1) : null;
            this.apexMethodName = originLocationPieces.size() >= 2 ? originLocationPieces.get(originLocationPieces.size() - 1) : null;
        }
    }

    private Boolean isValidStackTrace(String stackTraceString) {
        // Some lines, especially in the managed package, can result in '()' or '(Some_Namespace)'
        if (
            String.isBlank(stackTraceString) == true ||
            stackTraceString == '()' ||
            System.Pattern.compile('^\\([0-9A-Za-z_]+\\)$').matcher(stackTraceString).matches() == true
        ) {
            return false;
        }

        return true;
    }

    private List<String> getCleansedStackTraceLines(String stackTraceString) {
        List<String> stackTraceLines = new List<String>();
        String previousStackTraceLine;
        for (String currentStackTraceLine : stackTraceString.split(NEW_LINE_DELIMITER)) {
            // Duplicate lines are sometimes introduced, so skip the current line if it's the same as the previous line
            if (currentStackTraceLine == previousStackTraceLine) {
                continue;
            }

            // Don't include the logging system's classes in the stack trace
            Boolean ignoreLine = false;
            for (String ignoredApexClass : IGNORED_APEX_CLASSES) {
                if (currentStackTraceLine.contains('.' + ignoredApexClass.trim() + '.')) {
                    ignoreLine = true;
                    continue;
                }
            }
            // Some lines, especially in the managed package, can result in '()' or '(Nebula)'
            if (this.isValidStackTrace(currentStackTraceLine) == false) {
                ignoreLine = true;
            }

            if (ignoreLine == false) {
                previousStackTraceLine = currentStackTraceLine;
                stackTraceLines.add(currentStackTraceLine);
            }
        }

        return stackTraceLines;
    }
}
