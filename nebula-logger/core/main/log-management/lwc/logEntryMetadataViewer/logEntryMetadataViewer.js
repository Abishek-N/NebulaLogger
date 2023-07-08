import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMetadata from '@salesforce/apex/LogEntryMetadataViewerController.getMetadata';

// TODO move to a separate, dedicated Apex controller class or LWC service (?)
// import getLogEntry from '@salesforce/apex/LogEntrySectionController.getLogEntry';

import LOG_ENTRY_OBJECT from '@salesforce/schema/LogEntry__c';

import EXCEPTION_APEX_CLASS_NAME_FIELD from '@salesforce/schema/LogEntry__c.ExceptionApexClassName__c';
import EXCEPTION_APEX_CLASS_SNIPPET_FIELD from '@salesforce/schema/LogEntry__c.ExceptionApexClassSnippet__c';
import EXCEPTION_TYPE_FIELD from '@salesforce/schema/LogEntry__c.ExceptionType__c';
import FLOW_ACTIVE_VERSION_ID_FIELD from '@salesforce/schema/LogEntry__c.FlowActiveVersionId__c';
import LOGGING_APEX_CLASS_NAME_FIELD from '@salesforce/schema/LogEntry__c.ApexClassName__c';
import LOGGING_APEX_CLASS_SNIPPET_FIELD from '@salesforce/schema/LogEntry__c.ApexClassSnippet__c';
import MESSAGE_MASKED_FIELD from '@salesforce/schema/LogEntry__c.MessageMasked__c';
import MESSAGE_TRUNCATED_FIELD from '@salesforce/schema/LogEntry__c.MessageTruncated__c';

const LOG_ENTRY_FIELDS = [
    EXCEPTION_APEX_CLASS_NAME_FIELD,
    EXCEPTION_APEX_CLASS_SNIPPET_FIELD,
    EXCEPTION_TYPE_FIELD,
    FLOW_ACTIVE_VERSION_ID_FIELD,
    LOGGING_APEX_CLASS_NAME_FIELD,
    LOGGING_APEX_CLASS_SNIPPET_FIELD,
    MESSAGE_MASKED_FIELD,
    MESSAGE_TRUNCATED_FIELD
];

export default class LogEntryMetadataViewer extends LightningElement {
    @api recordId;

    exceptionApexCodeSnippet;
    originApexCodeSnippet;
    modalApexCodeSnippet;

    objectApiName = LOG_ENTRY_OBJECT;
    sectionTitleExceptionDetails = 'Exception Details';
    sectionTitleOriginDetails = 'Message Details';
    showModal = false;
    showModalWarning = false;

    _logEntry;
    _logEntryMetadata;
    _logEntryExceptionApexClassCode;
    _logEntryOriginApexClassCode;

    get hasLoaded() {
        return !!this._logEntry;
    }

    get showMessageMaskedField() {
        return !!getFieldValue(this._logEntry, MESSAGE_MASKED_FIELD);
    }

    get showMessageTruncatedField() {
        return !!getFieldValue(this._logEntry, MESSAGE_TRUNCATED_FIELD);
    }

    get showExceptionApexClassInformation() {
        const exceptionType = getFieldValue(this._logEntry, EXCEPTION_TYPE_FIELD);
        console.log('>>> exceptionType: ' + exceptionType);
        return !!exceptionType;
    }

    @wire(getMetadata, {
        recordId: '$recordId'
    })
    wiredLogEntryMetadata({ error, data }) {
        console.log('>>> running wiredLogEntryMetadata', this.recordId);
        console.log('>>> wiredLogEntryMetadata data', data);
        console.log('>>> wiredLogEntryMetadata error', error);
        if (data) {
            console.log('>>> found data', data);
            this._logEntryMetadata = data;
            this._logEntryExceptionApexClassCode = data.exceptionApexClassCode;
            this._logEntryOriginApexClassCode = data.originApexClassCode;
        } else if (error) {
            this._logEntryMetadata = undefined;
            this._logEntryExceptionApexClassCode = undefined;
            this._logEntryOriginApexClassCode = undefined;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId',
        fields: LOG_ENTRY_FIELDS
    })
    wiredLogEntry({ error, data }) {
        console.log('>>> running wiredLogEntry', this.recordId);
        console.log('>>> wiredLogEntry data', data);
        console.log('>>> wiredLogEntry error', error);
        console.log('>>> EXCEPTION_APEX_CLASS_SNIPPET_FIELD', EXCEPTION_APEX_CLASS_SNIPPET_FIELD);
        console.log('>>> FLOW_ACTIVE_VERSION_ID_FIELD', FLOW_ACTIVE_VERSION_ID_FIELD);
        console.log('>>> LOGGING_APEX_CLASS_SNIPPET_FIELD', LOGGING_APEX_CLASS_SNIPPET_FIELD);
        if (data) {
            console.log('>>> found data', data);
            this._logEntry = data;
            const originApexCodeSnippetValue = getFieldValue(this._logEntry, LOGGING_APEX_CLASS_SNIPPET_FIELD);
            if (originApexCodeSnippetValue) {
                const apexClassName = getFieldValue(this._logEntry, LOGGING_APEX_CLASS_NAME_FIELD) + '.cls';
                console.log('>>> origin apex class name: ' + apexClassName);
                this.originApexCodeSnippet = { ...JSON.parse(originApexCodeSnippetValue), ...{ language: 'apex', title: apexClassName } };
            }

            if (this.showExceptionApexClassInformation) {
                const exceptionApexCodeSnippetValue = getFieldValue(this._logEntry, EXCEPTION_APEX_CLASS_SNIPPET_FIELD);
                if (exceptionApexCodeSnippetValue) {
                    const apexClassName = getFieldValue(this._logEntry, EXCEPTION_APEX_CLASS_NAME_FIELD) + '.cls';
                    console.log('>>> exception apex class name: ' + apexClassName);
                    this.exceptionApexCodeSnippet = { ...JSON.parse(exceptionApexCodeSnippetValue), ...{ language: 'apex', title: apexClassName } };
                }
            }
            console.log('>>> matching origin code snippet', JSON.parse(JSON.stringify(this.originApexCodeSnippet)));
            console.log('>>> matching exception code snippet', JSON.parse(JSON.stringify(this.exceptionApexCodeSnippet)));
        } else if (error) {
            this.originApexCodeSnippet = undefined;
            this.exceptionApexCodeSnippet = undefined;
        }
    }

    handleShowModal(event) {
        this.modalApexCodeSnippet = undefined;
        // TODO check for either data id, and set modal content property
        const buttonId = event.target.dataset.id;
        console.log('>>> running handleShowModal for button ID', buttonId);
        switch(buttonId) {
            case 'exception-apex-class':
                console.log('>>> running case "exception-apex-class"');
                if (this._logEntryMetadata.exceptionApexClassCode) {
                    console.log('>>> no code found for "exception-apex-class"');
                    console.log('seems like we have code for _logEntryMetadata.exceptionApexClassCode!');
                    console.log('>>> this._logEntryMetadata.exceptionApexClassCode', this._logEntryMetadata.exceptionApexClassCode);
                    this.showModalWarning = this._logEntryMetadata.hasExceptionApexClassBeenModified;
                    this.modalApexCodeSnippet = {
                        code: this._logEntryMetadata.exceptionApexClassCode,
                        language: this.exceptionApexCodeSnippet.language,
                        title: this.exceptionApexCodeSnippet.title
                     };
                }
                break;
            case 'origin-apex-class':
                console.log('>>> running case "origin-apex-class"');
                if (this._logEntryMetadata.originApexClassCode) {
                    console.log('>>> no code found for "origin-apex-class"');
                    console.log('seems like we have code for _logEntryMetadata.originApexClassCode!');
                    console.log('>>> this._logEntryMetadata.originApexClassCode', this._logEntryMetadata.originApexClassCode);
                    this.showModalWarning = this._logEntryMetadata.hasOriginApexClassBeenModified;
                    this.modalApexCodeSnippet = {
                        code: this._logEntryMetadata.originApexClassCode,
                        language: this.originApexCodeSnippet.language,
                        title: this.originApexCodeSnippet.title
                     };
                }
                break;

        }
        this.modalTitle = 'Apex Class ' + this.modalApexCodeSnippet.title;
        console.log('>>> finished processing modal snippet');
        console.log('>>> this.modalApexCodeSnippet', JSON.parse(JSON.stringify(this.modalApexCodeSnippet)));
        // - data-id="origin-apex-class"
        // - data-id="exception-apex-class"
        this.showModal = true;
    }

    handleHideModal() {
        this.showModal = false;
    }

    handleKeyDown(event) {
        if (event.code === 'Escape') {
            this.handleHideModal();
        }
    }
}
