/***********************************************************************
 * @description Called by trigger action, after insert. Handle merge field value substitution.
 * @date 2025
 ***********************************************************************/
@NamespaceAccessible
public without sharing class TA_CAF_MergeFieldValuesAI {

    @NamespaceAccessible
    public void afterInsert(List<TREX1__Contract_and_Form__c> newList) {
        List<TREX1__Contract_and_Form__c> contractsToUpdate = new ContractFieldMerge(newList).populateMergeFields();
        updateContracts(contractsToUpdate);
    }

    private static void updateContracts(List<TREX1__Contract_and_Form__c> contractsToUpdate) {
        Database.update(contractsToUpdate, AccessLevel.SYSTEM_MODE);
    }

}