/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Modal for contract previews
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ContractTemplatePreviewModal extends LightningModal {
    @api templateId;

    handleClose() {
        this.close('okay');
    }
}