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
import getFieldDescriptors from '@salesforce/apex/ContractTemplateEditorController.getFieldDescriptors';

export default class ContractMergeFieldWizard extends LightningElement {
    @api objectApiName;
    @track fieldOptions = [];
    @track breadcrumbTrail = [];
    @track currentObject = '';
    @track currentPath = '';
    @track selectedValue = '';

    connectedCallback() {
        this.loadFieldOptions(this.objectApiName);
    }

    loadFieldOptions(objectApiName, relationshipPath = null) {
        this.currentObject = objectApiName;
        this.currentPath = relationshipPath || '';

        getFieldDescriptors({ objectApiName, relationshipPath })
            .then((data) => {
                this.fieldOptions = data.map(field => {
                    if (field.apiName.startsWith('table:')) {
                        const alias = field.apiName.split(':')[1];
                        return {
                            label: field.label,
                            value: `{!tableStart:${alias}}{!Name} - {!Price__c}{!tableEnd}`
                        };
                    } else if (field.isRelationship) {
                        return {
                            label: field.label + ' (→)',
                            value: field.apiName,
                            isRelationship: true,
                            relationshipName: field.relationshipName,
                            baseObject: this.currentObject,
                            fullPath: field.apiName
                        };
                    } else {
                        return {
                            label: field.label,
                            value: `{!${field.apiName}}`
                        };
                    }
                });
            })
            .catch((error) => {
                console.error('Error loading fields:', error);
            });
    }

    handleFieldSelection(event) {
        const selected = this.fieldOptions.find(opt => opt.value === event.detail.value);
        console.log('selected --> ', JSON.stringify(selected));
        if (selected?.isRelationship) {
            this.breadcrumbTrail.push({
                objectApiName: this.currentObject,
                relationshipPath: this.currentPath,
                label: selected.label
            });
            console.log('breadcrumbTrail --> ', JSON.stringify(this.breadcrumbTrail));
            const nextPath = selected.fullPath;
            console.log('nextPath --> ', nextPath);
            const nextObject = selected.relationshipName;
            console.log('nextObject --> ', nextObject);
            this.loadFieldOptions(nextObject, nextPath);
        } else {
            this.dispatchEvent(new CustomEvent('mergefieldselected', {
                detail: { mergeText: selected.value }
            }));
        }
    }

    handleBack() {
        if (this.breadcrumbTrail.length > 0) {
            const previous = this.breadcrumbTrail.pop();
            this.loadFieldOptions(previous.objectApiName, previous.relationshipPath);
        }
    }

    handleComboChange(event) {
        this.selectedValue = event.detail.value;
        this.handleFieldSelection({ detail: { value: this.selectedValue } });
    }

    handleInsert() {
        const selected = this.fieldOptions.find(opt => opt.value === this.selectedValue);
        if (selected && !selected.isRelationship) {
            this.dispatchEvent(new CustomEvent('mergefieldselected', {
                detail: { mergeText: selected.value }
            }));
        }
    }

    get breadcrumbLabels() {
        return this.breadcrumbTrail.map(crumb => crumb.label);
    }

    get isAtRoot() {
        return this.breadcrumbTrail.length === 0;
    }

}