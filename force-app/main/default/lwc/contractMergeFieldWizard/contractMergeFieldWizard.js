/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Wizard to guide merge field insertion for contract or form templates
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
import { LightningElement, api, track } from 'lwc';

export default class ContractMergeFieldWizard extends LightningElement {
    @api objectApiName;
    @track selectedField = '';
    @track tableAlias = '';

    @track fieldOptions = [
        { label: 'Name', value: '{!Name}' },
        { label: 'Membership Name', value: '{!TREX1__Membership__r.Name}' },
        { label: 'Contract Item Table', value: '{!tableStart:contractItems}{!Name} - {!Price__c}{!tableEnd}' }
    ];

    handleFieldChange(event) {
        this.selectedField = event.detail.value;
    }

    handleAliasChange(event) {
        this.tableAlias = event.detail.value;
    }

    handleInsert() {
        let mergeText = this.selectedField;
        this.dispatchEvent(new CustomEvent('mergefieldselected', {
            detail: { mergeText }
        }));
    }
}