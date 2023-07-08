/**
//  * @description An example Apex class for utilizing Nebula Logger.
 */
public with sharing class AnotherClassWithLogging {
    /**
     * @description Default constructor, logs initial message but does not save said log.
     */
    public AnotherClassWithLogging() {
        LogMessage logMessage = new LogMessage('new instance of {0} initialized', AnotherClassWithLogging.class.getName());
        Logger.info(logMessage);
    }

    /**
     * @description Example method for logging that saves log and writes a log entry.
     */
    public void throwSomeException() {
        Logger.info('running throwSomeException() method!');

        Account problematicAccount = new Account();
        Logger.info('going to cause a DML exception here by inserting an account with no fields populated', problematicAccount);
        insert problematicAccount;
    }

    /**
     * @description Example inner class.
     */
    public class ExampleInnerClass {
        /**
         * @description Example constructor
         */
        ExampleInnerClass() {
            LogMessage logMessage = new LogMessage('new instance of {0} initialized', ExampleInnerClass.class.getName());
            Logger.info(logMessage);
        }

        /**
         * @description example method in inner class.
         */
        public void doAnInnerSomething() {
            Logger.info('running doAnInnerSomething() method!');
            System.DmlException exceptionToThrow = new System.DmlException('some DML issue, whoops!');
            Logger.warn('about to throw exception', exceptionToThrow);
            Logger.saveLog();
            throw exceptionToThrow;
        }
    }
}
