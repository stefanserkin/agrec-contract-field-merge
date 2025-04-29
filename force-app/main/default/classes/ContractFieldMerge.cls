/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Merge field substitution handler for Contract and Form records
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractFieldMerge {

    private static final String WAIVER_TEMPLATE_ID_FIELD = 'trex1__caf_template__c';
    private static final String WAIVER_TEXT_FIELD = 'trex1__caf_template__r.trex1__waiver_text__c';

    private List<TREX1__Contract_and_Form__c> contracts;
    private List<TREX1__Contract_and_Form__c> contractsWithMergeInfo;
    private Map<Id, TREX1__Contract_or_Form_Template__c> templateMap;
    private Map<String, String> contractQueryMap;

    public ContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        loadTemplateMap();
        contractsWithMergeInfo = Database.query( buildContractQuery() );
        return replaceMergeFieldsWithValues(contractsWithMergeInfo);
    }

    private void loadTemplateMap() {
        templateMap = new Map<Id, TREX1__Contract_or_Form_Template__c>();
        contractQueryMap = new Map<String, String>();

        for (List<TREX1__Contract_or_Form_Template__c> templates : [
            SELECT Id, TREX1__Waiver_Text__c,
                   (SELECT Contract_and_Form_Query__r.Key__c, Contract_and_Form_Query__r.SOQL_Query__c
                      FROM Contract_and_Form_Template_Queries__r)
              FROM TREX1__Contract_or_Form_Template__c
             WHERE Id IN (SELECT TREX1__caf_Template__c 
                            FROM TREX1__Contract_and_Form__c 
                           WHERE Id IN :contracts)
              WITH USER_MODE
        ]) {
            for (TREX1__Contract_or_Form_Template__c template : templates) {
                templateMap.put(template.Id, template);
                for (Contract_and_Form_Template_Query__c templateQuery : template.Contract_and_Form_Template_Queries__r) {
                    contractQueryMap.put(
                        templateQuery.Contract_and_Form_Query__r.Key__c, 
                        templateQuery.Contract_and_Form_Query__r.SOQL_Query__c
                    );
                }
            }
        }
    }

    private String buildContractQuery() {
        List<String> mergeFields = getMergeFields();
        String query = 'SELECT ' + String.join(mergeFields, ', ') + 
                        ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
        return query;
    }

    private List<String> getMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{ WAIVER_TEMPLATE_ID_FIELD, WAIVER_TEXT_FIELD };

        for (TREX1__Contract_or_Form_Template__c template : templateMap.values()) {
            String waiverTextWithoutTables = ContractMergeFieldService.removeTableBlocks(template.TREX1__Waiver_Text__c);
            uniqueMergeFields.addAll( ContractMergeFieldService.getMergeFieldsFromString(waiverTextWithoutTables) );

            for (Contract_and_Form_Template_Query__c templateQuery : template.Contract_and_Form_Template_Queries__r) {
                uniqueMergeFields.addAll( ContractMergeFieldService.getMergeFieldsFromString(templateQuery.Contract_and_Form_Query__r.SOQL_Query__c) );
            }
        }

        return new List<String>(uniqueMergeFields);
    }

    private List<TREX1__Contract_and_Form__c> replaceMergeFieldsWithValues(List<TREX1__Contract_and_Form__c> contractsWithMergeInfo) {
        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            Map<String, List<SObject>> tableData = ContractMergeFieldService.prepareChildData(contract, contract.TREX1__caf_Template__r.TREX1__Waiver_Text__c, contractQueryMap);
            String waiverText = ContractMergeFieldService.expandTables(contract, contract.TREX1__caf_Template__r.TREX1__Waiver_Text__c, tableData);
            waiverText = ContractMergeFieldService.replaceMergeFieldsWithValues(waiverText, contract);
            contract.TREX1__Waiver_Text__c = waiverText;
        }
        return contractsWithMergeInfo;
    }
    
}
