public without sharing class LogEntryMetadataViewerController {
    @AuraEnabled(cacheable=true)
    public static LogEntryMetadata getMetadata(Id recordId) {
        LogEntryMetadata metadata = new LogEntryMetadata();
        if (Schema.ApexClass.SObjectType.getDescribe().isAccessible() == false) {
            return metadata;
        }

        // TODO consolidate use selector class
        LogEntry__c logEntry = [
            SELECT
                ApexClassId__c,
                ApexClassName__c,
                ApexClassSnippet__c,
                ExceptionApexClassName__c,
                ExceptionApexClassSnippet__c,
                FlowActiveVersionId__c,
                Id,
                OriginType__c,
                RecordCollectionType__c,
                RecordJson__c,
                Timestamp__c
            FROM LogEntry__c
            WHERE Id = :recordId
        ];

        // TODO consolidate queries & use selector class
        if (logEntry.ApexClassName__c != null) {
            List<ApexClass> possibleMatches = [
                SELECT Id, Body, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate
                FROM ApexClass
                WHERE Name = :logEntry.ApexClassName__c
            ];
            ApexClass matchingApexClass = possibleMatches.size() == 1 ? possibleMatches.get(0) : null;
            metadata.originApexClassCode = matchingApexClass?.Body;
            metadata.hasOriginApexClassBeenModified = matchingApexClass?.LastModifiedDate > logEntry.Timestamp__c;
        }
        if (logEntry.ExceptionApexClassName__c != null) {
            List<ApexClass> possibleMatches = [
                SELECT Id, Body, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate
                FROM ApexClass
                WHERE Name = :logEntry.ExceptionApexClassName__c
                LIMIT 1
            ];
            ApexClass matchingApexClass = possibleMatches.size() == 1 ? possibleMatches.get(0) : null;
            metadata.exceptionApexClassCode = matchingApexClass?.Body;
            metadata.hasExceptionApexClassBeenModified = matchingApexClass?.LastModifiedDate > logEntry.Timestamp__c;
        }

        return metadata;
    }

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
