/**
 * @description An example trigger handler class
 * You should use a trigger handler framework, but this trigger is just for demo purposes
 */
public with sharing class Account_Trigger_Handler_Logger_Example {
    public void execute() {
        Logger.info('Running Account handler class');
        new ExampleClassWithLogging().doSomething();
    }
}
