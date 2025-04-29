@IsTest
private class ContractFieldMergeInvocable_Test {

    private static List<ContractFieldMergeInvocable.Request> requests = new List<ContractFieldMergeInvocable.Request>();
    private static ContractFieldMergeInvocable.Request req = new ContractFieldMergeInvocable.Request();
    private static List<ContractFieldMergeInvocable.Result> results;
    
    @TestSetup
    static void makeData() {
        TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
        insert contract;
    }

    @IsTest
    static void testRefreshContracts() {
        TREX1__Contract_and_Form__c contract = [
            SELECT Id, TREX1__Waiver_Text__c
              FROM TREX1__Contract_and_Form__c
             LIMIT 1
        ];

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