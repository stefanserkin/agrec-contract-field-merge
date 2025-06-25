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
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { handleError, showToast } from 'c/lwcUtils';
import { unescapeAllowedHtml, normalizeHtml } from 'c/htmlUtils';
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
    originalTemplateBody = '';
    templateBody = '';

    get waiverTextHasChanged() {
        return normalizeHtml(this.templateBody) !== normalizeHtml(this.originalTemplateBody);
    }

    /**
     * Database calls
     */

    @wire(getRecord, { recordId: '$recordId', fields: [WAIVER_TEXT_FIELD] })
    wiredRecord(result) {
        this.isLoading = true;
        this.wiredContractTemplate = result;

        if (result.error) {
            this.error = result.error;
            handleError(this, this.error, 'Error retrieving waiver text');
            this.isLoading = false;
        } else if (result.data) {
            this.contractTemplate = result.data;
            this.originalTemplateBody = getFieldValue(this.contractTemplate, WAIVER_TEXT_FIELD);
            this.templateBody = this.originalTemplateBody;
            this.isLoading = false;
        }
    }

    updateContractTemplate() {
        this.isLoading = true;

        const editor = this.template.querySelector('lightning-input-rich-text');
        if (!editor.valid) {
            showToast(this, 'Error', 'This content is not valid. Please fix the errors on the page before saving.', 'error');
        }

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[WAIVER_TEXT_FIELD.fieldApiName] = this.templateBody;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                showToast(this, 'Success', `The template's Waiver Text has been updated`, 'success');
                refreshApex(this.wiredContractTemplate);
            })
            .catch((error) => {
                this.error = error;
                handleError(this, this.error, 'Error updating waiver test');
            })
            .finally(() => {
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
        if (!this.waiverTextHasChanged) {
            showToast(this, 'No Updates', 'There are no changes to save', 'info');
            return;
        }
        this.updateContractTemplate();
    }

    async openMergeFieldWizard() {
        const result = await MergeFieldModal.open({
            size: 'small',
            recordId: this.recordId
        });

        if (result) {
            const editor = this.template.querySelector('lightning-input-rich-text');
            editor.insertTextAtCursor(result);

            // Small timeout to let the DOM update before reading bound value
            await Promise.resolve();

            this.templateBody = unescapeAllowedHtml(this.templateBody);
        }
    }

    async openPreviewModal() {
        const result = await PreviewModal.open({
            size: 'medium',
            templateId: this.recordId
        });
    }

}