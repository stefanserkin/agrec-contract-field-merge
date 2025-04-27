/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Service to prepare Contract and Form records by merging field-level and table-level data.
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractFieldMerge {

    private static final String WAIVER_TEXT_FIELD = 'TREX1__Waiver_Text__c';

    private List<TREX1__Contract_and_Form__c> contracts;

    public ContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = Database.query(getQuery());
        
        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            String waiverText = contract.TREX1__Waiver_Text__c;
            if (String.isBlank(waiverText)) {
                continue;
            }
            
            // Step 1: Prepare child data for any tables
            Map<String, List<SObject>> tableData = ContractAndFormQueryService.prepareChildData(contract, waiverText);
            // Step 2: Expand table blocks
            waiverText = ContractMergeFieldService.expandTables(contract, waiverText, tableData);
            // Step 3: Expand simple field-level merge fields
            waiverText = ContractMergeFieldService.replaceMergeFieldsWithValues(waiverText, contract);
            // Save the updated text back
            contract.TREX1__Waiver_Text__c = waiverText;
        }
        
        return contractsWithMergeInfo;
    }

    private String getQuery() {
        List<String> mergeFields = getMergeFields();
        String query = 'SELECT ' + String.join(mergeFields, ', ') +
                       ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
        return query;
    }

    private List<String> getMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{ FieldPathManager.normalize(WAIVER_TEXT_FIELD) };
        for (TREX1__Contract_and_Form__c contract : contracts) {
            uniqueMergeFields.addAll(ContractMergeFieldService.getMergeFieldsFromString(contract.TREX1__Waiver_Text__c));
        }
        return new List<String>(uniqueMergeFields);
    }

}
