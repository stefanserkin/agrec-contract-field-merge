/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Service to prepare Contract and Form records by merging field-level and table-level data
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractFieldMerge {

    private static final String WAIVER_TEXT_FIELD = 'TREX1__Waiver_Text__c';

    private List<TREX1__Contract_and_Form__c> contracts;
    private Map<String, agrec__Contract_and_Form_Query__c> queryKeyToQuery = new Map<String, agrec__Contract_and_Form_Query__c>();

    public ContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        loadAndCacheQueries();
        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = queryContractsWithAllNeededFields();
        mergeContracts(contractsWithMergeInfo);
        return contractsWithMergeInfo;
    }

    private void loadAndCacheQueries() {
        ContractAndFormQueryService.clearCache();
        ContractAndFormQueryService.loadQueriesFromContracts(contracts);
        queryKeyToQuery = ContractAndFormQueryService.getCachedQueries();
    }

    private List<TREX1__Contract_and_Form__c> queryContractsWithAllNeededFields() {
        String soql = buildContractQuery();
        return Database.query(soql);
    }

    private String buildContractQuery() {
        Set<String> mergeFields = new Set<String>{
            FieldPathManager.normalize(WAIVER_TEXT_FIELD)
        };

        for (TREX1__Contract_and_Form__c contract : contracts) {
            if (String.isNotBlank(contract.TREX1__Waiver_Text__c)) {
                mergeFields.addAll(ContractMergeFieldService.getMergeFieldsFromString(contract.TREX1__Waiver_Text__c));
            }
        }

        for (agrec__Contract_and_Form_Query__c queryRec : queryKeyToQuery.values()) {
            if (String.isNotBlank(queryRec.SOQL_Query__c)) {
                mergeFields.addAll(ContractMergeFieldService.getMergeFieldsFromString(queryRec.SOQL_Query__c));
            }
        }

        return 'SELECT ' + String.join(new List<String>(mergeFields), ', ') +
               ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
    }

    private void mergeContracts(List<TREX1__Contract_and_Form__c> contractsWithMergeInfo) {
        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            if (String.isBlank(contract.TREX1__Waiver_Text__c)) {
                continue;
            }

            Map<String, List<SObject>> tableData = ContractMergeFieldService.prepareChildData(contract, contract.TREX1__Waiver_Text__c, queryKeyToQuery);
            String waiverText = ContractMergeFieldService.expandTables(contract, contract.TREX1__Waiver_Text__c, tableData);
            waiverText = ContractMergeFieldService.replaceMergeFieldsWithValues(waiverText, contract);

            contract.TREX1__Waiver_Text__c = waiverText;
        }
    }
    
}
