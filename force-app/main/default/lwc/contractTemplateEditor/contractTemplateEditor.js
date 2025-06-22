/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Rich text editor with support for merge field insertion
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import MergeFieldModal from 'c/contractMergeFieldModal';
import PreviewModal from 'c/contractTemplatePreviewModal';
import ID_FIELD from '@salesforce/schema/TREX1__Contract_or_Form_Template__c.Id';
import WAIVER_TEXT_FIELD from '@salesforce/schema/TREX1__Contract_or_Form_Template__c.TREX1__Waiver_Text__c';

export default class ContractTemplateEditor extends LightningElement {
    @api recordId;
    error;
    isLoading = false;

    wiredContractTemplate = [];
    contractTemplate;
    @track templateBody = '';
    @track previewContent = '';

    /**
     * Database calls
     */

    @wire(getRecord, { recordId: '$recordId', fields: [WAIVER_TEXT_FIELD] })
    wiredRecord(result) {
        this.isLoading = true;
        this.wiredContractTemplate = result;

        if (result.error) {
            this.error = result.error;
            this.handleError();
            this.isLoading = false;
        } else if (result.data) {
            this.contractTemplate = result.data;
            this.templateBody = getFieldValue(this.contractTemplate, WAIVER_TEXT_FIELD);
            this.isLoading = false;
        }
    }

    updateContractTemplate() {
        this.isLoading = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[WAIVER_TEXT_FIELD.fieldApiName] = this.templateBody;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', `The template's Waiver Text has been updated`, 'success');
                refreshApex(this.wiredContractTemplate);
                this.isLoading = false;
            })
            .catch((error) => {
                console.error(error);
                this.error = error;
                this.handleError();
                this.isLoading = false;
            });
    }

    /**
     * Events
     */

    handleEditorChange(event) {
        this.templateBody = event.detail.value;
    }

    handleSave() {
        this.updateContractTemplate();
    }

    async openMergeFieldWizard() {
        const result = await MergeFieldModal.open({
            size: 'small'
        });

        if (result) {
            const editor = this.template.querySelector('lightning-input-rich-text');
            editor.setRangeText(result);
        }
    }

    async openPreviewModal() {
        const result = await PreviewModal.open({
            size: 'medium',
            templateId: this.recordId
        });
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