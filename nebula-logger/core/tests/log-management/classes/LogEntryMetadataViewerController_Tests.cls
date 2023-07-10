@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest
private class LogEntryMetadataViewerController_Tests {
    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        insert LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    }

    @IsTest
    static void it_returns_metadata_for_log_entry_when_exception_apex_class_name_is_not_null() {
        // The specific ApexClass used here doesn't really matter, but since LogEntryMetadataViewerController
        // is the class under test here, it seems reasonable to also use it as an example class
        ApexClass exceptionApexClass = [
            SELECT Body, Name
            FROM ApexClass
            WHERE NamespacePrefix = :Logger.getNamespacePrefix() AND Name = :LogEntryMetadataViewerController.class.getName()
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = createLogEntry(log.Id, null, exceptionApexClass);
        insert logEntry;

        LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(logEntry.Id);

        System.Assert.areEqual(exceptionApexClass.Body, logEntryMetadata.exceptionApexClassCode);
        System.Assert.isFalse(logEntryMetadata.hasExceptionApexClassBeenModified);
        System.Assert.isFalse(logEntryMetadata.hasOriginApexClassBeenModified);
        System.Assert.isNull(logEntryMetadata.originApexClassCode);
    }

    @IsTest
    static void it_indicates_when_exception_class_has_been_modified_after_log_entry_timestamp() {
        // The specific ApexClass used here doesn't really matter, but since LogEntryMetadataViewerController
        // is the class under test here, it seems reasonable to also use it as an example class
        ApexClass exceptionApexClass = [
            SELECT Body, LastModifiedDate, Name
            FROM ApexClass
            WHERE NamespacePrefix = :Logger.getNamespacePrefix() AND Name = :LogEntryMetadataViewerController.class.getName()
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = createLogEntry(log.Id, null, exceptionApexClass);
        logEntry.Timestamp__c = exceptionApexClass.LastModifiedDate.addDays(-1);
        insert logEntry;

        LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(logEntry.Id);

        System.Assert.areEqual(exceptionApexClass.Body, logEntryMetadata.exceptionApexClassCode);
        System.Assert.isTrue(logEntryMetadata.hasExceptionApexClassBeenModified);
        System.Assert.isFalse(logEntryMetadata.hasOriginApexClassBeenModified);
        System.Assert.isNull(logEntryMetadata.originApexClassCode);
    }

    @IsTest
    static void it_returns_metadata_for_log_entry_when_origin_apex_class_name_is_not_null() {
        // The specific ApexClass used here doesn't really matter, but since LogEntryMetadataViewerController
        // is the class under test here, it seems reasonable to also use it as an example class
        ApexClass originApexClass = [
            SELECT Body, Name
            FROM ApexClass
            WHERE NamespacePrefix = :Logger.getNamespacePrefix() AND Name = :LogEntryMetadataViewerController.class.getName()
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = createLogEntry(log.Id, originApexClass, null);
        insert logEntry;

        LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(logEntry.Id);

        System.Assert.isNull(logEntryMetadata.exceptionApexClassCode);
        System.Assert.isFalse(logEntryMetadata.hasExceptionApexClassBeenModified);
        System.Assert.isFalse(logEntryMetadata.hasOriginApexClassBeenModified);
        System.Assert.areEqual(originApexClass.Body, logEntryMetadata.originApexClassCode);
    }


    @IsTest
    static void it_indicates_when_origin_class_has_been_modified_after_log_entry_timestamp() {
        // The specific ApexClass used here doesn't really matter, but since LogEntryMetadataViewerController
        // is the class under test here, it seems reasonable to also use it as an example class
        ApexClass originApexClass = [
            SELECT Body, LastModifiedDate, Name
            FROM ApexClass
            WHERE NamespacePrefix = :Logger.getNamespacePrefix() AND Name = :LogEntryMetadataViewerController.class.getName()
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = createLogEntry(log.Id, originApexClass, null);
        logEntry.Timestamp__c = originApexClass.LastModifiedDate.addDays(-1);
        insert logEntry;

        LogEntryMetadataViewerController.LogEntryMetadata logEntryMetadata = LogEntryMetadataViewerController.getMetadata(logEntry.Id);

        System.Assert.isNull(logEntryMetadata.exceptionApexClassCode);
        System.Assert.isFalse(logEntryMetadata.hasExceptionApexClassBeenModified);
        System.Assert.isTrue(logEntryMetadata.hasOriginApexClassBeenModified);
        System.Assert.areEqual(originApexClass.Body, logEntryMetadata.originApexClassCode);
    }

    static LogEntry__c createLogEntry(Id logId, ApexClass originApexClass, ApexClass exceptionApexClass) {
        LogEntry__c logEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateRequiredFields().getRecord();
        logEntry.ApexClassName__c = originApexClass?.Name;
        logEntry.ExceptionApexClassName__c = exceptionApexClass?.Name;
        logEntry.Log__c = logId;
        logEntry.Timestamp__c = System.now();
        return logEntry;
    }
}
