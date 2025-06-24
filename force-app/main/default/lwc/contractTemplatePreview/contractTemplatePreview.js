/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Preview contract with merge content for a sample record
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPreviewContent from '@salesforce/apex/ContractTemplateEditorController.getPreviewWaiverText';
import ID_FIELD from '@salesforce/schema/TREX1__Contract_and_Form__c.Id';
import NAME_FIELD from '@salesforce/schema/TREX1__Contract_and_Form__c.Name';
import STATUS_FIELD from '@salesforce/schema/TREX1__Contract_and_Form__c.TREX1__Status__c';
import CONTACT_FIELD from '@salesforce/schema/TREX1__Contract_and_Form__c.TREX1__Contact__c';
import ACCOUNT_FIELD from '@salesforce/schema/TREX1__Contract_and_Form__c.TREX1__Account__c';

export default class ContractTemplatePreview extends LightningElement {
    @api recordId;
    selectedContractId;
    previewContent;
    isShowPreview = false;
    isLoading = false;
    error;

    fields = {
        id: ID_FIELD,
        name: NAME_FIELD,
        status: STATUS_FIELD,
        contact: CONTACT_FIELD,
        account: ACCOUNT_FIELD
    };

    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['TREX1__Account__r.Name']
    };

    matchingInfo = {
        primaryField: { fieldPath: 'Name', mode: 'contains' },
        additionalFields: [{ fieldPath: 'TREX1__Account__r.Name', mode: 'contains' }]
    };

    get noSelectedContract() {
        return !this.selectedContractId;
    }

    handleContractSelection(event) {
        this.selectedContractId = event.detail.recordId;
    }

    handleShowPreview() {
        if (!this.selectedContractId) {
            this.showToast('Missing Selection', 'Please select a contract to preview', 'warning');
            return;
        }
        this.isLoading = true;
        
        getPreviewContent({templateId: this.recordId, contractId: this.selectedContractId})
            .then(result => {
                this.previewContent = result;
                this.isShowPreview = true;
            })
            .catch(error => {
                console.error(error);
                this.error = error;
                this.handleError();
            })
            .finally(() => {
                this.isLoading = false;
            })
    }

    handleBack() {
        this.toggleShowPreview();
    }

    toggleShowPreview() {
        this.isShowPreview = !this.isShowPreview;
    }

    /**
     * Utilities
     */

    handleError() {
        if (!this.error) {
            return;
        }
        
        const error = this.error;
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        } else {
            message = error.body?.message || JSON.stringify(error);
        }
        this.showToast('Something went wrong', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
    
}