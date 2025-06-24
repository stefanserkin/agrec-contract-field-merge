/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Modal for the merge field wizard
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
import { api } from 'lwc';
import LightningModal from 'lightning/modal';

const DEFAULT_OBJECT_API_NAME = 'TREX1__Contract_and_Form__c';

export default class ContractMergeFieldModal extends LightningModal {
    @api recordId;
    objectApiName = DEFAULT_OBJECT_API_NAME;

    handleMergeFieldSelected(event) {
        this.close(event.detail.mergeText);
    }

    handleCancel() {
        this.close(null);
    }
}