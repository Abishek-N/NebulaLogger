/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.               *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.   *
 ************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMetadata from '@salesforce/apex/LogEntryMetadataViewerController.getMetadata';

import LOG_ENTRY_OBJECT from '@salesforce/schema/LogEntry__c';
import EXCEPTION_APEX_CLASS_NAME_FIELD from '@salesforce/schema/LogEntry__c.ExceptionApexClassName__c';
import EXCEPTION_APEX_CODE_SNIPPET_FIELD from '@salesforce/schema/LogEntry__c.ExceptionApexCodeSnippet__c';
import EXCEPTION_TYPE_FIELD from '@salesforce/schema/LogEntry__c.ExceptionType__c';
import MESSAGE_MASKED_FIELD from '@salesforce/schema/LogEntry__c.MessageMasked__c';
import MESSAGE_TRUNCATED_FIELD from '@salesforce/schema/LogEntry__c.MessageTruncated__c';
import ORIGIN_APEX_CLASS_NAME_FIELD from '@salesforce/schema/LogEntry__c.ApexClassName__c';
import ORIGIN_APEX_CODE_SNIPPET_FIELD from '@salesforce/schema/LogEntry__c.ApexCodeSnippet__c';

const LOG_ENTRY_FIELDS = [
    EXCEPTION_APEX_CLASS_NAME_FIELD,
    EXCEPTION_APEX_CODE_SNIPPET_FIELD,
    EXCEPTION_TYPE_FIELD,
    MESSAGE_MASKED_FIELD,
    MESSAGE_TRUNCATED_FIELD,
    ORIGIN_APEX_CLASS_NAME_FIELD,
    ORIGIN_APEX_CODE_SNIPPET_FIELD
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

    get hasFullExceptionApexClass() {
        return !!this._logEntryExceptionApexClassCode;
    }

    get hasFullOriginApexClass() {
        return !!this._logEntryOriginApexClassCode;
    }

    get showMessageMaskedField() {
        return !!getFieldValue(this._logEntry, MESSAGE_MASKED_FIELD);
    }

    get showMessageTruncatedField() {
        return !!getFieldValue(this._logEntry, MESSAGE_TRUNCATED_FIELD);
    }

    get showExceptionDetails() {
        return !!getFieldValue(this._logEntry, EXCEPTION_TYPE_FIELD);
    }

    @wire(getMetadata, {
        recordId: '$recordId'
    })
    wiredGetLogEntryMetadata({ error, data }) {
        if (data) {
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
    wiredGetLogEntry({ data }) {
        if (data) {
            this._logEntry = data;
            const originApexCodeSnippetValue = getFieldValue(this._logEntry, ORIGIN_APEX_CODE_SNIPPET_FIELD);
            if (originApexCodeSnippetValue) {
                const apexClassName = getFieldValue(this._logEntry, ORIGIN_APEX_CLASS_NAME_FIELD) + '.cls';
                this.originApexCodeSnippet = { ...JSON.parse(originApexCodeSnippetValue), ...{ language: 'apex', title: apexClassName } };
            }

            if (this.showExceptionDetails) {
                const exceptionApexCodeSnippetValue = getFieldValue(this._logEntry, EXCEPTION_APEX_CODE_SNIPPET_FIELD);
                if (exceptionApexCodeSnippetValue) {
                    const apexClassName = getFieldValue(this._logEntry, EXCEPTION_APEX_CLASS_NAME_FIELD) + '.cls';
                    this.exceptionApexCodeSnippet = { ...JSON.parse(exceptionApexCodeSnippetValue), ...{ language: 'apex', title: apexClassName } };
                }
            }
        }
    }

    handleShowModal(event) {
        this.modalApexCodeSnippet = undefined;
        const buttonId = event.target.dataset.id;

        // eslint-disable-next-line default-case
        switch (buttonId) {
            case 'exception-apex-class':
                if (this._logEntryMetadata.exceptionApexClassCode) {
                    this.showModalWarning = this._logEntryMetadata.hasExceptionApexClassBeenModified;
                    this.modalApexCodeSnippet = {
                        code: this._logEntryMetadata.exceptionApexClassCode,
                        language: this.exceptionApexCodeSnippet.language,
                        title: this.exceptionApexCodeSnippet.title
                    };
                }
                break;
            case 'origin-apex-class':
                if (this._logEntryMetadata.originApexClassCode) {
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
