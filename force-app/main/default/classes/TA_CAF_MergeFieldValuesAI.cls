/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description Called by trigger action, after insert. Handle merge field value substitution.
 * 
 * @date 2025
 * @author Asphalt Green Data and Information Systems
 ***********************************************************************/
@NamespaceAccessible
public without sharing class TA_CAF_MergeFieldValuesAI implements agrec.TriggerAction.AfterInsert {

    private static final String STATUS_DRAFT = 'Draft';
    private static final String TYPE_WAIVER = 'Waiver Form';

    private List<TREX1__Contract_and_Form__c> filteredContracts;
    private List<TREX1__Contract_and_Form__c> contractsToUpdate;

    @NamespaceAccessible
    public void afterInsert(List<TREX1__Contract_and_Form__c> newList) {
        filteredContracts = filterContracts(newList);
        contractsToUpdate = new ContractFieldMerge(filteredContracts).resolveMergeFields();
        ContractMergeFieldService.updateContracts(contractsToUpdate);
    }

    private static List<TREX1__Contract_and_Form__c> filterContracts(List<TREX1__Contract_and_Form__c> newList) {
        List<TREX1__Contract_and_Form__c> filteredContracts = new List<TREX1__Contract_and_Form__c>();
        for (TREX1__Contract_and_Form__c contract : newList) {
            if (contract.TREX1__Status__c == STATUS_DRAFT && contract.TREX1__Type__c == TYPE_WAIVER) {
                filteredContracts.add(contract);
            }
        }
        return filteredContracts;
    }

}