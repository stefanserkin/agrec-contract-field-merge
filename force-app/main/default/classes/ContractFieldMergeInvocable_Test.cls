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

    // Single Record Merge
    private static List<ContractFieldMergeInvocable.Request> requests = new List<ContractFieldMergeInvocable.Request>();
    private static ContractFieldMergeInvocable.Request request = new ContractFieldMergeInvocable.Request();
    private static List<ContractFieldMergeInvocable.Result> results;

    // Record Collection Merge
    private static List<ContractFieldMergeListInvocable.Request> listRequests = new List<ContractFieldMergeListInvocable.Request>();
    private static ContractFieldMergeListInvocable.Request listRequest = new ContractFieldMergeListInvocable.Request();
    private static List<ContractFieldMergeListInvocable.Result> listResults;

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
            
            TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c FROM TREX1__Contract_and_Form__c LIMIT 1];

            request.contract = contract;
            request.saveChanges = false;
            requests.add(request);

            Test.startTest();
            results = ContractFieldMergeInvocable.refreshContracts(requests);
            Test.stopTest();

            System.Assert.isNotNull(results, 'Results should not be null');
            System.Assert.areEqual(1, results.size(), 'There should be one result returned');
            System.Assert.isNotNull(results[0].updatedContract, 'Updated Contract should not be null');
            System.Assert.areEqual(contract.Id, results[0].updatedContract.Id, 'Updated Contract Id should match input');
        }
    }

    @IsTest
    static void testRefreshContractsWithDml() {
        System.runAs(getUser()) {
            makeData();
            
            TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c FROM TREX1__Contract_and_Form__c LIMIT 1];

            request.contract = contract;
            request.saveChanges = true;
            requests.add(request);

            Test.startTest();
            results = ContractFieldMergeInvocable.refreshContracts(requests);
            Test.stopTest();

            System.Assert.areEqual(1, results.size(), 'There should be one result returned');
            System.Assert.areEqual(contract.Id, results[0].updatedContract.Id, 'Updated Contract Id should match input');

            TREX1__Contract_and_Form__c refreshedContract = [SELECT TREX1__Waiver_Text__c, TREX1__Account__r.Name FROM TREX1__Contract_and_Form__c WHERE Id = :contract.Id LIMIT 1];
            System.Assert.isTrue(
                refreshedContract.TREX1__Waiver_Text__c.contains(refreshedContract.TREX1__Account__r.Name), 
                'The contract should have been updated with the account name merge field'
            );
        }
    }

    @IsTest
    static void testRefreshContractsWithNoRequests() {
        Test.startTest();
        results = ContractFieldMergeInvocable.refreshContracts(requests);
        Test.stopTest();

        System.Assert.isNotNull(results, 'Results should not be null');
        System.Assert.areEqual(0, results.size(), 'There should be no results returned for empty input');
    }

    @IsTest
    static void testRefreshContractsWithNullRequests() {
        Test.startTest();
        results = ContractFieldMergeInvocable.refreshContracts(null);
        Test.stopTest();

        System.Assert.isNotNull(results, 'Results should not be null even if input is null');
        System.Assert.areEqual(0, results.size(), 'There should be no results returned for null input');
    }

    @IsTest
    static void testRefreshContractCollection() {
        System.runAs(getUser()) {
            makeData();
            
            TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__caf_Template__c, TREX1__Account__c, TREX1__Contact__c, TREX1__Status__c, TREX1__Type__c FROM TREX1__Contract_and_Form__c LIMIT 1];
            TREX1__Contract_and_Form__c secondContract = agrec.TestDataFactory.createContract(
                contract.TREX1__caf_Template__c,
                contract.TREX1__Account__c,
                contract.TREX1__Contact__c
            );
            insert secondContract;

            listRequest.contracts = new List<TREX1__Contract_and_Form__c>{ contract, secondContract };
            listRequest.saveChanges = false;
            listRequests.add(listRequest);

            Test.startTest();
            listResults = ContractFieldMergeListInvocable.refreshContracts(listRequests);
            Test.stopTest();

            System.Assert.isNotNull(listResults, 'Results should not be null');
            System.Assert.areEqual(1, listResults.size(), 'There should be one result returned');
            System.Assert.areEqual(2, listResults[0].updatedContracts.size(), 'Result should contain 2 Contract and Form records');
            System.Assert.areEqual(contract.Id, listResults[0].updatedContracts[0].Id, 'Contract and Form Ids should match by index location');
        }
    }

    @IsTest
    static void testRefreshContractCollectionWithDml() {
        System.runAs(getUser()) {
            makeData();
            
            TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c FROM TREX1__Contract_and_Form__c LIMIT 1];
            List<TREX1__Contract_and_Form__c> contracts = new List<TREX1__Contract_and_Form__c>{contract};

            listRequest.contracts = contracts;
            listRequest.saveChanges = true;
            listRequests.add(listRequest);

            Test.startTest();
            listResults = ContractFieldMergeListInvocable.refreshContracts(listRequests);
            Test.stopTest();

            System.Assert.areEqual(1, listResults.size(), 'There should be one result returned');
            System.Assert.areEqual(contract.Id, listResults[0].updatedContracts[0].Id, 'Updated Contract Id should match input');

            TREX1__Contract_and_Form__c refreshedContract = [SELECT TREX1__Waiver_Text__c, TREX1__Account__r.Name FROM TREX1__Contract_and_Form__c WHERE Id = :contract.Id LIMIT 1];
            System.Assert.isTrue(
                refreshedContract.TREX1__Waiver_Text__c.contains(refreshedContract.TREX1__Account__r.Name), 
                'The contract should have been updated with the account name merge field'
            );
        }
    }

    @IsTest
    static void testRefreshEmptyCollection() {
        System.runAs(getUser()) {
            Test.startTest();
            listResults = ContractFieldMergeListInvocable.refreshContracts(listRequests);
            Test.stopTest();

            System.Assert.isNotNull(listResults, 'Results should not be null');
            System.Assert.isTrue(listResults.isEmpty(), 'An empty list of results should have been returned');
        }
    }

}