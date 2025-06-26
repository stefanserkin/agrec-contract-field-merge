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
import { LightningElement, api } from 'lwc';
import { handleError, showToast } from 'c/lwcUtils';
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
            showToast(this, 'Missing Selection', 'Please select a contract to preview', 'warning');
            return;
        }
        this.isLoading = true;
        
        getPreviewContent({templateId: this.recordId, contractId: this.selectedContractId})
            .then(result => {
                this.previewContent = result;
                this.isShowPreview = true;
            })
            .catch(error => {
                this.error = error;
                handleError(this, this.error, 'Error retrieving preview content');
            })
            .finally(() => {
                this.isLoading = false;
            })
    }

    handleBack() {
        this.isShowPreview = false;
    }
    
}