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
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFieldDescriptors from '@salesforce/apex/ContractTemplateEditorController.getFieldDescriptors';

export default class ContractMergeFieldWizard extends LightningElement {
    @api objectApiName;
    @track fieldOptions = [];
    @track breadcrumbTrail = [];
    @track currentObject = '';
    @track currentPath = '';
    @track selectedValue = '';
    pathIsCopied = false;
    includeFallback = false;
    fallbackValue = '';

    get breadcrumbLabels() {
        return this.breadcrumbTrail.map(crumb => crumb.label);
    }

    get isAtRoot() {
        return this.breadcrumbTrail.length === 0;
    }
    
    get pathActionsAreDisabled() {
        return !this.selectedValue || !this.selectedValue.includes('{!') || 
            (this.includeFallback && !this.fallbackValue);
    }

    get mergeField() {
        let result = this.selectedValue;
        if (this.includeFallback && this.fallbackValue) {
            result = `${result.slice(0, -1)}, "${this.fallbackValue}"}`;
        }
        return result;
    }

    connectedCallback() {
        this.loadFieldOptions(this.objectApiName);
    }

    loadFieldOptions(objectApiName, relationshipPath = null) {
        this.currentObject = objectApiName;
        this.currentPath = relationshipPath || '';

        getFieldDescriptors({ objectApiName, relationshipPath })
            .then((data) => {
                const options = [];

                data.forEach(field => {
                    if (field.isRelationship) {
                        // Direct field reference
                        options.push({
                            label: `${field.label} (Id)`,
                            value: `{!${field.apiName}}`
                        });

                        // Traversal path
                        const relationshipSegment = field.relationshipName;
                        const fullPath = this.currentPath ? `${this.currentPath}.${relationshipSegment}` : relationshipSegment;
                        options.push({
                            label: `${field.label} (→)`,
                            value: fullPath,
                            isRelationship: true,
                            relationshipName: field.relationshipName,
                            baseObject: this.currentObject,
                            fullPath: fullPath,
                            targetObjectApiName: field.targetObjectApiName
                        });
                    } else {
                        // Non-relationship fields
                        options.push({
                            label: field.label,
                            value: `{!${field.apiName}}`
                        });
                    }
                });

                options.sort((a, b) => a.label.toLowerCase().localeCompare(b.label.toLowerCase()));
                this.fieldOptions = options;
            })
            .catch((error) => {
                console.error('Error loading fields:', error);
            });
    }

    handleFieldSelection() {
        const selected = this.fieldOptions.find(opt => opt.value === this.selectedValue);
        if (selected?.isRelationship) {
            this.breadcrumbTrail.push({
                objectApiName: this.currentObject,
                relationshipPath: this.currentPath,
                label: selected.label
            });
            const nextPath = selected.fullPath;
            const nextObject = selected.targetObjectApiName;
            this.loadFieldOptions(nextObject, nextPath);
        }
    }

    handleComboChange(event) {
        this.selectedValue = event.detail.value;
        this.handleFieldSelection();
    }

    handleFallbackChange(event) {
        const selected = event.detail.checked;
        this.includeFallback = selected;
    }

    handleFallbackValueChange(event) {
        const selected = event.detail.value;
        this.fallbackValue = selected;
    }

    handleBack() {
        if (this.breadcrumbTrail.length > 0) {
            const previous = this.breadcrumbTrail.pop();
            this.selectedValue = previous.relationshipPath;
            this.loadFieldOptions(previous.objectApiName, previous.relationshipPath);
        }
    }

    handleInsert() {
        const selected = this.fieldOptions.find(opt => opt.value === this.selectedValue);
        if (selected && !selected.isRelationship) {
            this.dispatchEvent(new CustomEvent('mergefieldselected', {
                detail: { mergeText: this.mergeField }
            }));
        }
    }

    handleCopyPath() {
        if (!this.mergeField) {
            return;
        }

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(this.mergeField)
                .then(() => {
                    this.showToast('Success', 'Merge path was copied to the clipboard', 'success');
                })
                .catch(error => {
                    const errorMessage = error && error.message ? error.message : 'Merge path could not be copied';
                    this.showToast('Error', errorMessage, 'error');
                });
        } else {
            let input = document.createElement("input");
            input.value = this.mergeField;
            document.body.appendChild(input);
            input.focus();
            input.select();
            document.execCommand("Copy");
            input.remove();
            this.showToast('Success', 'Merge path was copied to the clipboard', 'success');
        }

        this.pathIsCopied = true;
        setTimeout(() => {
            this.pathIsCopied = false;
        }, 4000);
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