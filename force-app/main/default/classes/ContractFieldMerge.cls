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

    public ContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        loadTemplateMap();
        contractsWithMergeInfo = Database.query( buildContractQuery() );
        return replaceMergeFieldsWithValues(contractsWithMergeInfo);
    }

    private void loadTemplateMap() {
        Set<Id> templateIds = new Set<Id>();
        for (TREX1__Contract_and_Form__c contract : contracts) {
            templateIds.add(contract.TREX1__caf_Template__c);
        }
        ContractTemplateService.addTemplates(templateIds);
    }

    private String buildContractQuery() {
        List<String> mergeFields = getMergeFields();
        String query = 'SELECT ' + String.join(mergeFields, ', ') + 
                        ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
        return query;
    }

    private List<String> getMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{ WAIVER_TEMPLATE_ID_FIELD, WAIVER_TEXT_FIELD };

        Map<Id, TREX1__Contract_or_Form_Template__c> templateMap = ContractTemplateService.getTemplates();
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
            TREX1__Contract_or_Form_Template__c template = ContractTemplateService.getTemplates().get(contract.TREX1__caf_Template__c);
            Map<String, List<SObject>> tableData = ContractMergeFieldService.prepareChildData(contract, template.TREX1__Waiver_Text__c);
            String waiverText = ContractMergeFieldService.expandTables(template.TREX1__Waiver_Text__c, tableData);
            waiverText = ContractMergeFieldService.replaceMergeFieldsWithValues(waiverText, contract);
            contract.TREX1__Waiver_Text__c = waiverText;
        }
        return contractsWithMergeInfo;
    }
    
}
