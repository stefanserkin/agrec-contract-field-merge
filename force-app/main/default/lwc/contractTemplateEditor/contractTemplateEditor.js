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
import { LightningElement, track } from 'lwc';

export default class ContractTemplateEditor extends LightningElement {
    @track templateBody = '';
    @track previewContent = '';
    @track showMergeWizard = false;

    handleEditorChange(event) {
        this.templateBody = event.detail.value;
    }

    openMergeFieldWizard() {
        this.showMergeWizard = true;
    }

    handleMergeFieldSelected(event) {
        const mergeText = event.detail.mergeText;
        this.templateBody += mergeText;
        this.showMergeWizard = false;
    }

    previewTemplate() {
        this.previewContent = this.templateBody;
    }
}