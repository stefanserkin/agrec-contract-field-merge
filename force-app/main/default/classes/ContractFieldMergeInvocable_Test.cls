@IsTest
private class ContractFieldMergeInvocable_Test {

    private static final String PERM_SET_TREC_BASE_ACCESS = 'Traction_Rec_Base_Access_v2';
    private static final String PERM_SET_TREC_FULL_ACCESS = 'Traction_Rec_Full_Access';
    private static final String PERM_SET_MERGE_ADMIN = 'agrec_Contract_and_Form_Admin';
    
    private static List<String> adminPermissionSetNames = new List<String>{
        PERM_SET_TREC_BASE_ACCESS,
        PERM_SET_TREC_FULL_ACCESS, 
        PERM_SET_MERGE_ADMIN
    };

    private static List<ContractFieldMergeInvocable.Request> requests = new List<ContractFieldMergeInvocable.Request>();
    private static ContractFieldMergeInvocable.Request req = new ContractFieldMergeInvocable.Request();
    private static List<ContractFieldMergeInvocable.Result> results;

    private static User getUser() {
        return agrec.TestDataFactory.getUser(adminPermissionSetNames);
    }
    
    private static void makeData() {
        Contract_and_Form_Query__c query = new Contract_and_Form_Query__c(
            Key__c = 'addOns',
            SOQL_Query__c = 'SELECT Name, TREX1__Status__c FROM TREX1__Add_On__c WHERE TREX1__Registration__c = \'{!TREX1__Registration__c}\''
        );
        insert query;

        TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();

        Contract_and_Form_Template_Query__c link = new Contract_and_Form_Template_Query__c();
        link.Contract_and_Form_Query__c = query.Id;
        link.Contract_or_Form_Template__c = contract.TREX1__caf_Template__c;
        insert link;

        TREX1__Registration__c registration = agrec.TestDataFactory.createRegistrationWithAddOns(contract.TREX1__Account__c, contract.TREX1__Contact__c);
        contract.TREX1__Registration__c = registration.Id;
        insert contract;
    }

    @IsTest
    static void testRefreshContracts() {
        System.runAs(getUser()) {
            makeData();
            
            TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__caf_Template__c FROM TREX1__Contract_and_Form__c LIMIT 1];

            req.contract = contract;
            requests.add(req);

            Test.startTest();
            results = ContractFieldMergeInvocable.refreshContracts(requests);
            Test.stopTest();

            System.assertNotEquals(null, results, 'Results should not be null');
            System.assertEquals(1, results.size(), 'There should be one result returned');
            System.assertNotEquals(null, results[0].updatedContract, 'Updated Contract should not be null');
            System.assertEquals(contract.Id, results[0].updatedContract.Id, 'Updated Contract Id should match input');
        }
    }

    @IsTest
    static void testRefreshContractsWithNoRequests() {
        Test.startTest();
        results = ContractFieldMergeInvocable.refreshContracts(requests);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'There should be no results returned for empty input');
    }

    @IsTest
    static void testRefreshContractsWithNullRequests() {
        Test.startTest();
        results = ContractFieldMergeInvocable.refreshContracts(null);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null even if input is null');
        System.assertEquals(0, results.size(), 'There should be no results returned for null input');
    }

}