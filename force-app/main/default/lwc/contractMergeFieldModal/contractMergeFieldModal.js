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
import LightningModal from 'lightning/modal';

export default class ContractMergeFieldModal extends LightningModal {
    objectApiName = 'TREX1__Contract_and_Form__c';

    handleMergeFieldSelected(event) {
        this.close(event.detail.mergeText);
    }

    handleCancel() {
        this.close(null);
    }
}