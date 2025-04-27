@IsTest
private class ContractFieldMerge_Test {

    @TestSetup
    static void makeData() {
        // TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
        // insert contract;

        /*
        Account account = new Account(Name = 'Test Account');
        insert account;

        // Create a Contact
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = account.Id
        );
        insert contact;

        TREX1__Registration__c reg = new TREX1__Registration__c();
        reg.TREX1__Account__c = account.Id;
        reg.TREX1__Contact__c = contact.Id;
        insert reg;

        List<TREX1__Add_On__c> addOns = new List<TREX1__Add_On__c>{
            new TREX1__Add_On__c(Name = 'Locker Rental', TREX1__Status__c = 'Draft', TREX1__Registration__c = reg.Id),
            new TREX1__Add_On__c(Name = 'Swim Goggles', TREX1__Status__c = 'Draft', TREX1__Registration__c = reg.Id)
        };
        insert addOns;

        TREX1__Contract_and_Form__c contract = new TREX1__Contract_and_Form__c(
            Name = 'Test Contract',
            TREX1__Contact__c = contact.Id,
            TREX1__Account__c = account.Id,
            TREX1__Registration__c = reg.Id,
            TREX1__Contract_Expiry_Policy__c = 'Always Required',
            TREX1__Valid_For__c = 'Account',
            TREX1__Type__c = 'Waiver Form',
            TREX1__Status__c = 'Draft',
            TREX1__Waiver_Text__c = 'Hello {!TREX1__Contact__r.FirstName}, your account is {!TREX1__Account__r.Name}.' +
                                    '\nAdd-Ons:\n{!tableStart:addOns}- {!Name} (Status: {!TREX1__Status__c}){!tableEnd}'
        );
        insert contract;
        */

        TREX1__Contract_and_Form__c contract = CFM_TestDataFactory.createContractScenario();
        TREX1__Registration__c registration = CFM_TestDataFactory.createRegistrationWithAddOns(contract.TREX1__Account__c, contract.TREX1__Contact__c);
        contract.TREX1__Registration__c = registration.Id;
        insert contract;

        Contract_and_Form_Query__c query = new Contract_and_Form_Query__c(
            Key__c = 'addOns',
            SOQL_Query__c = 'SELECT Name, TREX1__Status__c FROM TREX1__Add_On__c WHERE TREX1__Registration__c = \'{!TREX1__Registration__c}\''
        );
        insert query;
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

        TREX1__Contract_and_Form__c refreshedContract = [SELECT TREX1__Waiver_Text__c, Name, TREX1__Account__r.Name, TREX1__Contact__r.Account.Name FROM TREX1__Contract_and_Form__c WHERE Id = :updatedContracts[0].Id LIMIT 1];
        String waiverText = refreshedContract.TREX1__Waiver_Text__c;

        System.Assert.isTrue(waiverText.contains(refreshedContract.TREX1__Account__r.Name), 'Should have received the account name. Received: ' + waiverText);
        System.Assert.isTrue(waiverText.contains(refreshedContract.TREX1__Contact__r.Account.Name), 'Should have received the account name through the contact. Received: ' + waiverText);
    }

}