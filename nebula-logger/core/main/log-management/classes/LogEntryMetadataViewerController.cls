//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `logEntryMetadataViewer`
 */
public without sharing class LogEntryMetadataViewerController {
    /**
     * @description Returns an instance of the inner class `LogEntryMetadataViewerController.LogEntryMetadata`,
     *              which contains information about the log entry's origin and exception Apex classes
     * @param       recordId The `ID` of the `LogEntry__c` record
     * @return      An instance of `LogEntryMetadataViewerController.LogEntryMetadata`
     */
    @AuraEnabled(cacheable=true)
    public static LogEntryMetadata getMetadata(Id recordId) {
        LogEntryMetadata metadata = new LogEntryMetadata();
        if (Schema.ApexClass.SObjectType.getDescribe().isAccessible() == false) {
            return metadata;
        }

        LogEntry__c logEntry = LogManagementDataSelector.getInstance().getLogEntryById(recordId);

        if (logEntry.ApexClassName__c == null && logEntry.ExceptionApexClassName__c == null) {
            return metadata;
        }

        List<String> apexClassNames = new List<String>{ logEntry.ApexClassName__c, logEntry.ExceptionApexClassName__c };
        Map<String, ApexClass> apexClassNameToClass = new Map<String, ApexClass>();
        for (ApexClass apexClass : LogManagementDataSelector.getInstance().getApexClasses(apexClassNames)) {
            apexClassNameToClass.put(apexClass.Name, apexClass);
        }

        if (apexClassNameToClass.containsKey(logEntry.ApexClassName__c) == true) {
            ApexClass matchingApexClass = apexClassNameToClass.get(logEntry.ApexClassName__c);
            metadata.originApexClassCode = matchingApexClass?.Body;
            metadata.hasOriginApexClassBeenModified = matchingApexClass?.LastModifiedDate > logEntry.Timestamp__c;
        }
        if (logEntry.ExceptionApexClassName__c != null) {
            ApexClass matchingApexClass = apexClassNameToClass.get(logEntry.ExceptionApexClassName__c);
            metadata.exceptionApexClassCode = matchingApexClass?.Body;
            metadata.hasExceptionApexClassBeenModified = matchingApexClass?.LastModifiedDate > logEntry.Timestamp__c;
        }

        return metadata;
    }

    @SuppressWarnings('PMD.ApexDoc')
    public class LogEntryMetadata {
        @AuraEnabled
        public String exceptionApexClassCode;
        @AuraEnabled
        public Boolean hasExceptionApexClassBeenModified = false;
        @AuraEnabled
        public Boolean hasOriginApexClassBeenModified = false;
        @AuraEnabled
        public String originApexClassCode;
    }
}
