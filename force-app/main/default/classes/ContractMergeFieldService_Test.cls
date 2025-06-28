@IsTest
private class ContractMergeFieldService_Test {

    private static final String PERM_SET_TREC_BASE_ACCESS = 'Traction_Rec_Base_Access_v2';
    private static final String PERM_SET_TREC_FULL_ACCESS = 'Traction_Rec_Full_Access';
    private static final String PERM_SET_MERGE_ADMIN = 'agrec_Contract_and_Form_Admin';
    
    private static List<String> adminPermissionSetNames = new List<String>{
        PERM_SET_TREC_BASE_ACCESS,
        PERM_SET_TREC_FULL_ACCESS, 
        PERM_SET_MERGE_ADMIN
    };

    private static User getUser() {
        return agrec.TestDataFactory.getUser(adminPermissionSetNames);
    }

    @IsTest
    static void testMergeSingleContractById() {
        System.runAs(getUser()) {
            TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
            insert contract;

            Test.startTest();
            Map<Id, TREX1__Contract_and_Form__c> updatedContracts;
            updatedContracts = ContractMergeFieldService.mergeById( new Set<Id>{contract.Id} );
            Test.stopTest();

            System.Assert.areEqual(1, updatedContracts.size(), 'Should have received an updated record for the contract');
            System.Assert.areEqual(contract.Id, updatedContracts.values().get(0).Id, 'Returned contract id should match the original record id');

            String accountName = [SELECT Name FROM Account WHERE Id = :contract.TREX1__Account__c LIMIT 1].get(0).Name;
            String updatedWaiverText = updatedContracts.values().get(0).TREX1__Waiver_Text__c;
            System.Assert.isTrue(updatedWaiverText.contains(accountName), 'Contract waiver text should contain the account name.');
        }
    }

    @IsTest
    static void testMergeContractCollectionById() {
        System.runAs(getUser()) {
            TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
            TREX1__Contract_and_Form__c contract2 = agrec.TestDataFactory.createContract(
                contract.TREX1__caf_Template__c,
                contract.TREX1__Account__c,
                contract.TREX1__Contact__c
            );
            insert new List<TREX1__Contract_and_Form__c>{ contract, contract2 };

            Set<Id> contractIds = new Set<Id>{ contract.Id, contract2.Id };

            Test.startTest();
            Map<Id, TREX1__Contract_and_Form__c> updatedContracts;
            updatedContracts = ContractMergeFieldService.mergeById(contractIds);
            Test.stopTest();

            System.Assert.areEqual(2, updatedContracts.size(), 'Should have received an updated record for each contract');
            System.Assert.areEqual(contract.Id, updatedContracts.values().get(0).Id, 'Should have received the first contract in the same order as the input');
            System.Assert.areEqual(contract2.Id, updatedContracts.values().get(1).Id, 'Should have received the second contract in the same order as the input');
        }
    }

    @IsTest
    static void testUpdateContracts() {
        String updatedWaiverText = 'My updated waiver text';

        TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
        insert contract;

        Test.startTest();
        contract.TREX1__Waiver_Text__c = updatedWaiverText;
        ContractMergeFieldService.updateContracts(new List<TREX1__Contract_and_Form__c>{contract});
        Test.stopTest();

        TREX1__Contract_and_Form__c updatedContract = [SELECT TREX1__Waiver_Text__c FROM TREX1__Contract_and_Form__c WHERE Id = :contract.Id LIMIT 1];
        System.Assert.areEqual(updatedWaiverText, updatedContract.TREX1__Waiver_Text__c, 'Received unexpected waiver text after update');
    }
    
}