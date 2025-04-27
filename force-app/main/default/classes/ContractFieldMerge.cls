/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description Substitute field values for their api field names 
 *              in Traction Rec contracts
 * 
 * @date 2025
 * @author Asphalt Green Data and Information Systems
 ***********************************************************************/
public without sharing class ContractFieldMerge {

    private static final String WAIVER_TEXT_FIELD = 'trex1__waiver_text__c';

    private List<TREX1__Contract_and_Form__c> contracts;

    public ContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = Database.query( getQuery() );
        return replaceMergeFieldsWithValues(contractsWithMergeInfo);
    }

    private String getQuery() {
        List<String> mergeFields = getMergeFields();
        String query = 'SELECT ' + String.join(mergeFields, ', ') + 
                        ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
        return query;
    }

    private List<String> getMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{ WAIVER_TEXT_FIELD };
        for (TREX1__Contract_and_Form__c contract : contracts) {
            uniqueMergeFields.addAll( ContractMergeFieldService.getMergeFieldsFromString(contract.TREX1__Waiver_Text__c) );
        }
        return new List<String>(uniqueMergeFields);
    }

    private List<TREX1__Contract_and_Form__c> replaceMergeFieldsWithValues(List<TREX1__Contract_and_Form__c> contractsWithMergeInfo) {
        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            contract.TREX1__Waiver_Text__c = ContractMergeFieldService.replaceMergeFieldsWithValues(contract.TREX1__Waiver_Text__c, contract);
        }
        return contractsWithMergeInfo;
    }

}