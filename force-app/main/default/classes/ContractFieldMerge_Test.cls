@IsTest
private class ContractFieldMerge_Test {
    
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(Name = 'Rey Ordonez Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Rey', LastName = 'Ordonez', AccountId = testAccount.Id);
        insert testContact;

        TREX1__Contract_and_Form__c contract = new TREX1__Contract_and_Form__c(
            Name = 'Test Contract',
            TREX1__Waiver_Text__c = 'Hello {!Name}, your account is {!TREX1__Account__r.Name} and contact account is {!TREX1__Contact__r.Account.Name, "No account provided"}.',
            TREX1__Account__c = testAccount.Id,
            TREX1__Contact__c = testContact.Id,
            TREX1__Contract_Expiry_Policy__c = 'Always Required',
            TREX1__Valid_For__c = 'Account',
            TREX1__Type__c = 'Waiver Form',
            TREX1__Status__c = 'Draft'
        );
        insert contract;
    }

    @IsTest
    static void testPopulateMergeFields() {
        List<TREX1__Contract_and_Form__c> contracts = [SELECT Id, TREX1__Waiver_Text__c FROM TREX1__Contract_and_Form__c];

        Test.startTest();
        ContractFieldMerge fieldMerge = new ContractFieldMerge(contracts);
        List<TREX1__Contract_and_Form__c> updatedContracts = fieldMerge.populateMergeFields();
        Test.stopTest();

        System.Assert.areNotEqual(null, updatedContracts, 'Returned contract list should not be null.');
        System.Assert.isTrue(updatedContracts.size() > 0, 'At least one contract should be processed.');
    }

}