//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages setting fields on `LogEntry__c` before insert & before update
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
public without sharing class LogEntryHandler extends LoggerSObjectHandler {
    private static final Map<Schema.SObjectType, String> SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME = new Map<Schema.SObjectType, String>();

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LogEntry__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        List<LogEntry__c> logEntries = (List<LogEntry__c>) triggerNew;

        // setApexStackTraceFields() has to run before setApexClassFields() and setApexTriggerFields()
        this.setApexStackTraceFields(logEntries);
        this.setApexClassFields(logEntries);
        this.setApexTriggerFields(logEntries);
        this.setComponentFields(logEntries);
        this.setFlowDefinitionFields(logEntries);
        this.setFlowVersionFields(logEntries);
        this.setRecordNames(logEntries);
        // This method should run last, in case any other methods modify fields related to the checkboxes
        this.setCheckboxFields(logEntries);
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        List<LogEntry__c> logEntries = (List<LogEntry__c>) triggerNewMap.values();

        // Realistically, these checkbox fields probably only need to be set on insert
        // but some admins & devs might decide to update/append data in some of the related fields
        // and it conceptually feels weird for there to be scenarios where these fields could be inaccurate,
        // so keep them up to date just to be safe
        this.setCheckboxFields(logEntries);
    }

    private void setApexStackTraceFields(List<LogEntry__c> logEntries) {
        for (LogEntry__c logEntry : logEntries) {
            if (logEntry.OriginType__c != 'Apex') {
                continue;
            }

            if (String.isNotBlank(logEntry.StackTrace__c) == true) {
                LoggerStackTrace originStackTrace = new LoggerStackTrace(logEntry.StackTrace__c);
                new OriginApexStackTraceFieldApplier().apply(logEntry, originStackTrace);
            }

            if (String.isNotBlank(logEntry.ExceptionStackTrace__c) == true) {
                LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(logEntry.ExceptionStackTrace__c);
                new ExceptionApexStackTraceFieldApplier().apply(logEntry, exceptionStackTrace);
            }
        }
    }

    private void setApexClassFields(List<LogEntry__c> logEntries) {
        List<String> apexClassNames = new List<String>();
        List<LogEntry__c> apexClassLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : logEntries) {
            Boolean isApexClassLogEntry = false;
            if (String.isNotBlank(logEntry.ApexClassName__c) == true) {
                isApexClassLogEntry = true;
                apexClassNames.add(logEntry.ApexClassName__c);
            }

            if (logEntry.ExceptionSourceType__c == 'ApexClass' && String.isNotBlank(logEntry.ExceptionSourceApiName__c) == true) {
                isApexClassLogEntry = true;
                apexClassNames.add(logEntry.ExceptionSourceApiName__c);
            }

            if (isApexClassLogEntry == true) {
                apexClassLogEntries.add(logEntry);
            }
        }

        if (apexClassNames.isEmpty() == true) {
            return;
        }

        Map<String, ApexClass> classNameToApexClass = new Map<String, ApexClass>();
        for (ApexClass apexClass : LogManagementDataSelector.getInstance().getApexClasses(apexClassNames)) {
            classNameToApexClass.put(apexClass.Name, apexClass);
        }

        if (classNameToApexClass.isEmpty() == true) {
            return;
        }

        for (LogEntry__c logEntry : apexClassLogEntries) {
            ApexClass originApexClass = classNameToApexClass.get(logEntry.ApexClassName__c);
            if (originApexClass != null) {
                new OriginApexMetadataFieldApplier().apply(logEntry, originApexClass, Integer.valueOf(logEntry.OriginSourceLineNumber__c));
            }

            ApexClass exceptionApexClass = classNameToApexClass.get(logEntry.ExceptionSourceApiName__c);
            if (exceptionApexClass != null) {
                new ExceptionApexMetadataFieldApplier().apply(logEntry, exceptionApexClass, Integer.valueOf(logEntry.ExceptionSourceLineNumber__c));
            }
        }
    }

    private void setApexTriggerFields(List<LogEntry__c> logEntries) {
        List<String> apexTriggerNames = new List<String>();
        List<LogEntry__c> apexTriggerLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : logEntries) {
            Boolean isApexTriggerLogEntry = false;
            if (String.isNotBlank(logEntry.OriginSourceApiName__c) == true) {
                isApexTriggerLogEntry = true;
                apexTriggerNames.add(logEntry.OriginSourceApiName__c);
            }

            if (logEntry.ExceptionSourceType__c == 'ApexTrigger' && String.isNotBlank(logEntry.ExceptionSourceApiName__c) == true) {
                isApexTriggerLogEntry = true;
                apexTriggerNames.add(logEntry.ExceptionSourceApiName__c);
            }

            if (isApexTriggerLogEntry == true) {
                apexTriggerLogEntries.add(logEntry);
            }
        }

        if (apexTriggerNames.isEmpty() == true) {
            return;
        }

        Map<String, ApexTrigger> TriggerNameToApexTrigger = new Map<String, ApexTrigger>();
        for (ApexTrigger apexTrigger : LogManagementDataSelector.getInstance().getApexTriggers(apexTriggerNames)) {
            TriggerNameToApexTrigger.put(apexTrigger.Name, apexTrigger);
        }

        if (TriggerNameToApexTrigger.isEmpty() == true) {
            return;
        }

        for (LogEntry__c logEntry : apexTriggerLogEntries) {
            ApexTrigger originApexTrigger = TriggerNameToApexTrigger.get(logEntry.OriginSourceApiName__c);
            if (originApexTrigger != null) {
                new OriginApexMetadataFieldApplier().apply(logEntry, originApexTrigger, Integer.valueOf(logEntry.OriginSourceLineNumber__c));
            }

            ApexTrigger exceptionApexTrigger = TriggerNameToApexTrigger.get(logEntry.ExceptionSourceApiName__c);
            if (exceptionApexTrigger != null) {
                new ExceptionApexMetadataFieldApplier().apply(logEntry, exceptionApexTrigger, Integer.valueOf(logEntry.ExceptionSourceLineNumber__c));
            }
        }
    }

    private void setComponentFields(List<LogEntry__c> logEntries) {
        for (LogEntry__c logEntry : logEntries) {
            if (logEntry.OriginType__c == 'Component' && String.isNotBlank(logEntry.OriginLocation__c)) {
                logEntry.ComponentApiName__c = logEntry.OriginLocation__c.substringBefore('.');
                logEntry.ComponentFunctionName__c = logEntry.OriginLocation__c.substringAfterLast('.');
            }
        }
    }

    private void setFlowDefinitionFields(List<LogEntry__c> logEntries) {
        List<String> flowApiNames = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : logEntries) {
            if (logEntry.OriginType__c == 'Flow' && String.isNotBlank(logEntry.OriginSourceApiName__c)) {
                flowApiNames.add(logEntry.OriginSourceApiName__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowApiNames.isEmpty() == true) {
            return;
        }

        Map<String, FlowDefinitionView> flowApiNameToDefinition = new Map<String, FlowDefinitionView>();
        for (FlowDefinitionView flowDefinition : LogManagementDataSelector.getInstance().getFlowDefinitionViewsByFlowApiName(flowApiNames)) {
            flowApiNameToDefinition.put(flowDefinition.ApiName, flowDefinition);
        }

        if (flowApiNameToDefinition.isEmpty() == true) {
            return;
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowDefinitionView flowDefinition = flowApiNameToDefinition.get(logEntry.OriginSourceApiName__c);
            if (flowDefinition == null) {
                continue;
            }

            logEntry.FlowActiveVersionId__c = flowDefinition.ActiveVersionId;
            logEntry.FlowDescription__c = flowDefinition.Description;
            logEntry.FlowDurableId__c = flowDefinition.DurableId;
            logEntry.FlowLabel__c = flowDefinition.Label;
            logEntry.FlowLastModifiedByName__c = flowDefinition.LastModifiedBy;
            logEntry.FlowLastModifiedDate__c = flowDefinition.LastModifiedDate;
            logEntry.FlowProcessType__c = flowDefinition.ProcessType;
            logEntry.FlowRecordTriggerType__c = flowDefinition.RecordTriggerType;
            logEntry.FlowTriggerOrder__c = flowDefinition.TriggerOrder;
            logEntry.FlowTriggerSObjectType__c = flowDefinition.TriggerObjectOrEvent?.QualifiedApiName;
            logEntry.FlowTriggerType__c = flowDefinition.TriggerType;
            // TODO finalize what should go here?!
            logEntry.OriginSourceId__c = flowDefinition.ActiveVersionId; // flowDefinition.DurableId;

            // logEntry.OriginSourceCreatedByName__c = flowDefinition.CreatedBy;
            // logEntry.OriginSourceCreatedDate__c = flowDefinition.CreatedDate;
            // logEntry.OriginSourceLastModifiedByName__c = flowDefinition.LastModifiedBy;
            // logEntry.OriginSourceLastModifiedDate__c = flowDefinition.LastModifiedDate;
        }
    }

    private void setFlowVersionFields(List<LogEntry__c> logEntries) {
        List<String> flowActiveVersionIds = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : logEntries) {
            if (logEntry.OriginType__c == 'Flow' && String.isNotBlank(logEntry.FlowActiveVersionId__c)) {
                flowActiveVersionIds.add(logEntry.FlowActiveVersionId__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowActiveVersionIds.isEmpty() == true) {
            return;
        }

        Map<String, FlowVersionView> flowDurableIdToFlowVersionView = new Map<String, FlowVersionView>();
        for (FlowVersionView flowVersionView : LogManagementDataSelector.getInstance().getFlowVersionViewsByDurableId(flowActiveVersionIds)) {
            // Filtering on Status in SOQL seems to always return 0 results, so filter in code instead
            if (flowVersionView.Status == 'Active') {
                flowDurableIdToFlowVersionView.put(flowVersionView.FlowDefinitionViewId, flowVersionView);
            }
        }

        if (flowDurableIdToFlowVersionView.isEmpty() == true) {
            return;
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowVersionView flowVersionView = flowDurableIdToFlowVersionView.get(logEntry.FlowDurableId__c);
            if (flowVersionView == null) {
                continue;
            }

            logEntry.FlowVersionApiVersionRuntime__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
            logEntry.FlowVersionRunInMode__c = flowVersionView.RunInMode;
            logEntry.FlowVersionNumber__c = flowVersionView.VersionNumber;

            logEntry.OriginSourceApiVersion__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
            // TODO populate these
            // logEntry.OriginSourceCreatedByUsername__c = flowVersionView.CreatedBy.Username;
            // logEntry.OriginSourceCreatedDate__c = flowVersionView.CreatedDate;
            // logEntry.OriginSourceId__c
            // logEntry.OriginSourceLastModifiedByUsername__c = flowVersionView.LastModifiedBy.Username;
            // logEntry.OriginSourceLastModifiedDate__c = flowVersionView.LastModifiedDate;
        }
    }

    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    private void setRecordNames(List<LogEntry__c> logEntries) {
        if (LoggerParameter.QUERY_RELATED_RECORD_DATA == false) {
            return;
        }

        // Assumption - only valid record IDs will be populated in LogEntry__c.RecordId__c
        // If that changes, then extra checks may be needed before casting to Id, using getSObjectType(), etc.
        // TODO: This method is pretty long & it's doing multiple things - consider breaking it up into separate methods or an inner class

        // 1. Figure out which SObjects & record IDs to query
        Map<Schema.SObjectType, List<Id>> sobjectTypeToRecords = new Map<Schema.SObjectType, List<Id>>();
        for (LogEntry__c logEntry : logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RecordId__c == null) {
                continue;
            }

            Id recordId = (Id) logEntry.RecordId__c;
            Schema.SObjectType sobjectType = getSObjectType(recordId);
            if (sobjectType == null) {
                continue;
            }

            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            if (sobjectTypeRecordIds == null) {
                sobjectTypeRecordIds = new List<Id>();
            }
            sobjectTypeRecordIds.add(recordId);
            sobjectTypeToRecords.put(sobjectType, sobjectTypeRecordIds);
        }

        // 2. Run the queries and store the results in the map
        Map<Id, SObject> recordIdToRecord = new Map<Id, SObject>();
        for (Schema.SObjectType sobjectType : sobjectTypeToRecords.keySet()) {
            // Stop if we've used up all the queries
            if (System.Limits.getQueries() == System.Limits.getLimitQueries()) {
                break;
            }

            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            String sobjectDisplayFieldName = getDisplayFieldApiName(sobjectType);

            if (sobjectDisplayFieldName == null) {
                continue;
            }

            List<SObject> results = LogManagementDataSelector.getInstance()
                .getById(sobjectType, new Set<String>{ sobjectDisplayFieldName }, sobjectTypeRecordIds);
            recordIdToRecord.putAll(results);
        }

        // 3. Finally, save the record name on the log entry
        for (LogEntry__c logEntry : logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RecordId__c == null) {
                continue;
            }

            Id recordId = (Id) logEntry.RecordId__c;
            Schema.SObjectType sobjectType = getSObjectType(recordId);
            if (sobjectType == null) {
                continue;
            }

            String sobjectDisplayFieldName = getDisplayFieldApiName(sobjectType);
            if (sobjectDisplayFieldName != null) {
                if (recordIdToRecord.containsKey(logEntry.RecordId__c)) {
                    String recordName = (String) recordIdToRecord.get(logEntry.RecordId__c).get(sobjectDisplayFieldName);
                    logEntry.RecordName__c = recordName;
                }
            }
        }
    }

    private void setCheckboxFields(List<LogEntry__c> logEntries) {
        // A formula field can't be used for checking if a long text area field is set/null
        // So, this code handles maintaing some checkbox fields via Apex instead
        for (LogEntry__c logEntry : logEntries) {
            logEntry.HasExceptionSourceSnippet__c = logEntry.ExceptionSourceSnippet__c != null;
            logEntry.HasExceptionStackTrace__c = logEntry.ExceptionStackTrace__c != null;
            logEntry.HasInlineTags__c = logEntry.Tags__c != null;
            logEntry.HasOriginSourceSnippet__c = logEntry.OriginSourceSnippet__c != null;
            logEntry.HasRecordJson__c = logEntry.RecordJson__c != null;
            logEntry.HasStackTrace__c = logEntry.StackTrace__c != null;
        }
    }

    // Static helper methods
    private static String getDisplayFieldApiName(Schema.SObjectType sobjectType) {
        if (SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.containsKey(sobjectType) == true) {
            return SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.get(sobjectType);
        }

        // Use username instead of name for user
        if (sobjectType == Schema.User.SObjectType) {
            String userFieldName = Schema.User.Username.getDescribe().getName();
            SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.put(Schema.User.SObjectType, userFieldName);
            return userFieldName;
        }

        // There are several commonly used names for the display field name - typically, Name
        // The order of the field names has been sorted based on number of objects in a dev org with that field
        List<String> educatedGuesses = new List<String>{
            'Name',
            'DeveloperName',
            'ApiName',
            'Title',
            'Subject',
            'AssetRelationshipNumber',
            'CaseNumber',
            'ContractNumber',
            'Domain',
            'FriendlyName',
            'FunctionName',
            'Label',
            'LocalPart',
            'OrderItemNumber',
            'OrderNumber',
            'SolutionName',
            'TestSuiteName'
        };

        String displayFieldApiName;
        List<String> fallbackFieldApiNames = new List<String>();
        for (String fieldName : educatedGuesses) {
            Schema.SObjectField field = sobjectType.getDescribe().fields.getMap().get(fieldName);

            if (field == null) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if (fieldDescribe.isNameField() == true) {
                displayFieldApiName = fieldDescribe.getName();
                break;
            } else {
                fallbackFieldApiNames.add(fieldDescribe.getName());
            }
        }

        // Some objects don't have a proper 'display field', but they do have a reasonable alternative field to use instead.
        // For example, EmailMessage doesn't have a true display field, but it has a 'Subject' field. If one (and only one)
        // of the educated guess-fields exists on the object - and the object does not have a display field - then use the
        // educated guess-field as the fallback for the display field.
        if (String.isBlank(displayFieldApiName) == true && fallbackFieldApiNames.size() == 1) {
            displayFieldApiName = fallbackFieldApiNames.get(0);
        }

        SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.put(sobjectType, displayFieldApiName);
        return displayFieldApiName;
    }

    private static Schema.SObjectType getSObjectType(Id recordId) {
        Schema.SObjectType sobjectType;
        try {
            sobjectType = recordId?.getSObjectType();
        } catch (System.SObjectException sobjectException) {
            // Some SObject Types are considered template objects, such as CaseComment, AccountHistory,
            // ContactHistory, etc, so calling Id.getSObjectType() does not work for some types of record IDs
            if (sobjectException.getMessage().contains('Cannot locate Apex Type') == false) {
                throw sobjectException;
            }
        }
        return sobjectType;
    }

    @SuppressWarnings('PMD.ApexDoc')
    @TestVisible
    private class ApexCodeSnippet {
        public String code { get; private set; }
        public Integer startingLineNumber { get; private set; }
        public Integer endingLineNumber { get; private set; }
        public Integer targetLineNumber { get; private set; }

        public ApexCodeSnippet(ApexClass apexClass, Integer targetLineNumber) {
            this(apexClass.Body, targetLineNumber);
        }

        public ApexCodeSnippet(ApexTrigger apexTrigger, Integer targetLineNumber) {
            this(apexTrigger.Body, targetLineNumber);
        }

        private ApexCodeSnippet(String codeBody, Integer targetLineNumber) {
            if (String.isNotBlank(codeBody) == true && targetLineNumber != null) {
                this.targetLineNumber = targetLineNumber;
                List<String> allCodeLines = codeBody.split('\n');
                this.calculateLineNumbers(allCodeLines.size());
                this.setCode(allCodeLines);
            }
        }

        private void calculateLineNumbers(Integer numberOfCodeLines) {
            // TODO consider making these values configurable with 2 new LoggerParameter__mdt records
            final Integer targetLeadingLines = 8;
            final Integer targetTrailingLines = 4;

            this.startingLineNumber = this.targetLineNumber - targetLeadingLines;
            if (this.startingLineNumber <= 0) {
                this.startingLineNumber = 1;
            }

            this.endingLineNumber = this.targetLineNumber + targetTrailingLines;
            if (this.endingLineNumber > numberOfCodeLines) {
                this.endingLineNumber = numberOfCodeLines;
            }
        }

        private void setCode(List<String> allCodeLines) {
            List<String> snippetCodeLines = new List<String>();
            for (Integer i = this.startingLineNumber; i <= this.endingLineNumber; i++) {
                // Indexes in arrays start with 0, but code lines start with 1
                Integer targetLineNumber = i - 1;
                snippetCodeLines.add(allCodeLines.get(targetLineNumber));
            }

            this.code = String.join(snippetCodeLines, '\n');
        }
    }

    // Helper classes that are used to apply field values for each entry's related ApexClass or ApexTrigger
    @SuppressWarnings('PMD.ApexDoc')
    private class ExceptionApexMetadataFieldApplier extends ApexMetadataFieldApplier {
        public override void apply(LogEntry__c logEntry, Schema.ApexClass apexClass, Integer codeLineNumber) {
            if (apexClass == null) {
                return;
            }

            logEntry.ExceptionSourceApiVersion__c = 'v' + apexClass.ApiVersion;
            logEntry.ExceptionSourceCreatedByUsername__c = apexClass.CreatedBy.Username;
            logEntry.ExceptionSourceCreatedDate__c = apexClass.CreatedDate;
            logEntry.ExceptionSourceId__c = apexClass.Id;
            logEntry.ExceptionSourceLastModifiedByUsername__c = apexClass.LastModifiedBy.Username;
            logEntry.ExceptionSourceLastModifiedDate__c = apexClass.LastModifiedDate;
            logEntry.ExceptionSourceSnippet__c = JSON.serializePretty(new ApexCodeSnippet(apexClass, Integer.valueOf(codeLineNumber)));
        }

        public override void apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger, Integer codeLineNumber) {
            if (apexTrigger == null) {
                return;
            }

            logEntry.ExceptionSourceApiVersion__c = 'v' + apexTrigger.ApiVersion;
            logEntry.ExceptionSourceCreatedByUsername__c = apexTrigger.CreatedBy.Username;
            logEntry.ExceptionSourceCreatedDate__c = apexTrigger.CreatedDate;
            logEntry.ExceptionSourceId__c = apexTrigger.Id;
            logEntry.ExceptionSourceLastModifiedByUsername__c = apexTrigger.LastModifiedBy.Username;
            logEntry.ExceptionSourceLastModifiedDate__c = apexTrigger.LastModifiedDate;
            logEntry.ExceptionSourceSnippet__c = JSON.serializePretty(new ApexCodeSnippet(apexTrigger, Integer.valueOf(codeLineNumber)));
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private class OriginApexMetadataFieldApplier extends ApexMetadataFieldApplier {
        public override void apply(LogEntry__c logEntry, Schema.ApexClass apexClass, Integer codeLineNumber) {
            if (apexClass == null) {
                return;
            }

            logEntry.ApexClassLastModifiedDate__c = apexClass.LastModifiedDate;
            logEntry.OriginSourceApiVersion__c = 'v' + apexClass.ApiVersion;
            logEntry.OriginSourceCreatedByUsername__c = apexClass.CreatedBy.Username;
            logEntry.OriginSourceCreatedDate__c = apexClass.CreatedDate;
            logEntry.OriginSourceId__c = apexClass.Id;
            logEntry.OriginSourceLastModifiedByUsername__c = apexClass.LastModifiedBy.Username;
            logEntry.OriginSourceLastModifiedDate__c = apexClass.LastModifiedDate;
            logEntry.OriginSourceSnippet__c = JSON.serializePretty(new ApexCodeSnippet(apexClass, Integer.valueOf(codeLineNumber)));
        }

        public override void apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger, Integer codeLineNumber) {
            if (apexTrigger == null) {
                return;
            }

            logEntry.OriginSourceApiVersion__c = 'v' + apexTrigger.ApiVersion;
            logEntry.OriginSourceCreatedByUsername__c = apexTrigger.CreatedBy.Username;
            logEntry.OriginSourceCreatedDate__c = apexTrigger.CreatedDate;
            logEntry.OriginSourceId__c = apexTrigger.Id;
            logEntry.OriginSourceLastModifiedByUsername__c = apexTrigger.LastModifiedBy.Username;
            logEntry.OriginSourceLastModifiedDate__c = apexTrigger.LastModifiedDate;
            logEntry.OriginSourceSnippet__c = JSON.serializePretty(new ApexCodeSnippet(apexTrigger, Integer.valueOf(codeLineNumber)));
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private abstract class ApexMetadataFieldApplier {
        public abstract void apply(LogEntry__c logEntry, Schema.ApexClass topLevelApexClass, Integer codeLineNumber);
        public abstract void apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger, Integer codeLineNumber);
    }

    // Helper classes that are used to apply field values for each entry's stack trace
    @SuppressWarnings('PMD.ApexDoc')
    private class ExceptionApexStackTraceFieldApplier extends ApexStackTraceFieldApplier {
        public override void apply(LogEntry__c logEntry, LoggerStackTrace stackTrace) {
            logEntry.ExceptionSourceType__c = stackTrace.originSourceType;
            logEntry.ExceptionSourceLineNumber__c = stackTrace.apexCodeLineNumber;
            logEntry.ExceptionSourceApiName__c = String.isNotBlank(stackTrace.apexTopLevelClassName) == true
                ? stackTrace.apexTopLevelClassName
                : stackTrace.apexTriggerName;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private class OriginApexStackTraceFieldApplier extends ApexStackTraceFieldApplier {
        public override void apply(LogEntry__c logEntry, LoggerStackTrace stackTrace) {
            logEntry.ApexClassName__c = stackTrace.apexTopLevelClassName;
            logEntry.ApexInnerClassName__c = stackTrace.apexInnerClassName;
            logEntry.ApexMethodName__c = stackTrace.apexMethodName;
            logEntry.OriginSourceApiName__c = stackTrace.originSourceApiName;
            logEntry.OriginSourceLineNumber__c = stackTrace.apexCodeLineNumber;
            logEntry.OriginSourceType__c = stackTrace.originSourceType;
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private abstract class ApexStackTraceFieldApplier {
        public abstract void apply(LogEntry__c logEntry, LoggerStackTrace stackTrace);
    }
}
