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
import { handleError, showToast } from 'c/lwcUtils';
import { convertHtmlForClipboard } from 'c/htmlUtils';
import getTemplateQueries from '@salesforce/apex/ContractTemplateEditorController.getTemplateQueries';
import getFieldDescriptors from '@salesforce/apex/ContractTemplateEditorController.getFieldDescriptors';

const TABS = Object.freeze({
    FIELDS: { label: 'Fields', value: 'fields' },
    TABLES: { label: 'Tables', value: 'tables' }
});

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

    tabs = TABS;
    activeTab = TABS.FIELDS.value;
    isLoading = false;
    pathIsCopied = false;
    error;

    get isFieldsTab() {
        return this.activeTab === this.tabs.FIELDS.value;
    }

    get isTablesTab() {
        return this.activeTab === this.tabs.TABLES.value;
    }

    get hasTemplateQueries() {
        return this.templateQueries && this.templateQueries.length > 0;
    }

    get queryOptions() {
        if (!this.templateQueries) return [];

        return this.templateQueries.map(row => ({
            label: row.name,
            value: row.key
        }));
    }

    get queryFieldOptions() {
        if (!this.selectedQueryKey) return [];

        const query = this.templateQueries.find(opt => opt.key === this.selectedQueryKey);
        if (!query.fields) return [];

        return query.fields.map(row => ({
            label: `${row.label} (${row.apiName})`,
            value: row.apiName
        }));
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
        if (this.isFieldsTab) {
            result = this.selectedValue;
            if (this.includeFallback && this.fallbackValue) {
                result = `${result.slice(0, -1)}, "${this.fallbackValue}"}`;
            }
        } else if (this.isTablesTab) {
            if (this.selectedQueryKey) {
                let fieldBullets = [];
                this.selectedQueryFields.forEach(field => {
                    fieldBullets.push(`{!${field}}`);
                });
                result = `{!tableStart:${this.selectedQueryKey}}&bull; ${fieldBullets.join(' | ')}<br>{!tableEnd}`;
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
        this.wiredTemplateQueries = result;

        if (result.data) {
            this.templateQueries = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.templateQueries = undefined;
            this.error = result.error;
            handleError(this, this.error, 'Error retrieving template queries');
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
                this.error = error;
                handleError(this, this.error, 'Error loading fields');
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

        const plainText = convertHtmlForClipboard(this.mergeField);

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(plainText)
                .then(() => {
                    showToast(this, 'Success', 'Merge path was copied to the clipboard', 'success');
                })
                .catch(error => {
                    const errorMessage = error && error.message ? error.message : 'Merge path could not be copied';
                    showToast(this, 'Error', errorMessage, 'error');
                });
        } else {
            let input = document.createElement("input");
            input.value = plainText;
            document.body.appendChild(input);
            input.focus();
            input.select();
            document.execCommand("Copy");
            input.remove();
            showToast(this, 'Success', 'Merge path was copied to the clipboard', 'success');
        }

        this.pathIsCopied = true;
        setTimeout(() => {
            this.pathIsCopied = false;
        }, 4000);
    }

}