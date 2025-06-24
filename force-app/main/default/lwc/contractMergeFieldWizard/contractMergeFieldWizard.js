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
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTemplateQueries from '@salesforce/apex/ContractTemplateEditorController.getTemplateQueries';
import getFieldDescriptors from '@salesforce/apex/ContractTemplateEditorController.getFieldDescriptors';

export default class ContractMergeFieldWizard extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track fieldOptions = [];
    @track breadcrumbTrail = [];
    currentObject = '';
    currentPath = '';
    selectedValue = '';
    includeFallback = false;
    fallbackValue = '';

    wiredTemplateQueries = [];
    @track templateQueries;
    selectedQueryKey;
    @track selectedQueryFields = [];

    activeTab = 'fields';
    isLoading = false;
    pathIsCopied = false;
    error;

    get queryOptions() {
        let options = [];
        this.templateQueries.forEach(row => {
            options.push({
                label: row.name,
                value: row.key
            });
        });
        return options;
    }

    get queryFieldOptions() {
        if (!this.selectedQueryKey) {
            return;
        }

        const query = this.templateQueries.find(opt => opt.key === this.selectedQueryKey);
        let options = [];
        query.fields.forEach(field => {
            options.push({
                label: field.apiName,
                value: field.apiName
            });
        });
        return options;
    }

    get breadcrumbLabels() {
        return this.breadcrumbTrail.map(crumb => crumb.label);
    }

    get isAtRoot() {
        return this.breadcrumbTrail.length === 0;
    }
    
    get pathActionsAreDisabled() {
        return !this.mergeField || !this.mergeField.includes('{!') || (this.includeFallback && !this.fallbackValue);
    }

    get mergeField() {
        let result = '';
        if (this.activeTab === 'fields') {
            result = this.selectedValue;
            if (this.includeFallback && this.fallbackValue) {
                result = `${result.slice(0, -1)}, "${this.fallbackValue}"}`;
            }
        } else if (this.activeTab === 'tables') {
            if (this.selectedQueryKey) {
                let fieldBullets = [];
                this.selectedQueryFields.forEach(field => {
                    fieldBullets.push(`{!${field}}`);
                });
                result += `{!tableStart:${this.selectedQueryKey}}&bull; ${fieldBullets.join(' | ')}<br>{!tableEnd}`;
            }
        }
        return result;
    }

    connectedCallback() {
        this.loadFieldOptions(this.objectApiName);
    }

    /**
     * Database Calls
     */

    @wire(getTemplateQueries, { templateId: '$recordId' })
    wiredQueryResult(result) {
        this.isLoading = true;
        this.wiredTemplateQueries = result;

        if (result.data) {
            this.templateQueries = result.data;
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.templateQueries = undefined;
            this.error = result.error;
            this.handleError();
            this.isLoading = false;
        }
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
                this.error = error;
                this.handleError();
            });
    }

    /**
     * Events
     */

    handleActiveTab(event) {
        this.activeTab = event.target.value;
    }

    handleComboChange(event) {
        this.selectedValue = event.detail.value;
        this.handleFieldSelection();
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

    handleFallbackChange(event) {
        this.includeFallback = event.detail.checked;
    }

    handleFallbackValueChange(event) {
        this.fallbackValue = event.detail.value;
    }

    handleQueryChange(event) {
        this.selectedQueryKey = event.detail.value;
    }

    handleQueryFieldsChange(event) {
        this.selectedQueryFields = event.detail.value;
    }

    handleBack() {
        if (this.breadcrumbTrail.length > 0) {
            const previous = this.breadcrumbTrail.pop();
            this.selectedValue = previous.relationshipPath;
            this.loadFieldOptions(previous.objectApiName, previous.relationshipPath);
        }
    }

    handleInsert() {
        if (!this.mergeField) {
            return;
        }

        this.dispatchEvent(new CustomEvent('mergefieldselected', {
            detail: { mergeText: this.mergeField }
        }));
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