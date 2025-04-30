@IsTest
private class ContractMergeFieldService_Test {

    private static List<ContractFieldMergeInvocable.Request> requests = new List<ContractFieldMergeInvocable.Request>();
    private static ContractFieldMergeInvocable.Request req = new ContractFieldMergeInvocable.Request();
    private static List<ContractFieldMergeInvocable.Result> results;

    @IsTest
    static void testGetMergeFieldsFromString() {
        String input = 'Hello {!Name}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'name', 'id'};
        
        Test.startTest();
        Set<String> actualFields = ContractMergeFieldService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testGetMergeFieldsWithFallbackValue() {
        String input = 'Hello {!Name, "Guest"}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'name', 'id'};
        
        Test.startTest();
        Set<String> actualFields = ContractMergeFieldService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testReplaceMergeFieldsWithValues() {
        String accountName = 'Test Account for Merges';
        Account acc = new Account(Name = accountName, NumberOfEmployees = 100, Industry = null);

        String input = 'Hello {!Name} from the {!Industry, &quot;World&quot;}! Congrats on your {!NumberOfEmployees} employees.';

        Test.startTest();
        String result = ContractMergeFieldService.replaceMergeFieldsWithValues(input, acc);
        Test.stopTest();

        System.Assert.areEqual(
            'Hello ' + accountName + ' from the World! Congrats on your 100 employees.',
            result,
            'Merge fields should be replaced with actual values.'
        );
    }

    @IsTest
    static void testReplaceParentMergeFieldsWithValues() {
        Account acc = new Account(Name = 'Test Account for Merges');
        insert acc;

        Contact ct = new Contact(AccountId = acc.Id, FirstName = 'Testeroo', LastName = 'Merges');
        insert ct;

        Contact contactWithMergeFields = [SELECT Id, Account.Name FROM Contact WHERE Id = :ct.Id LIMIT 1];

        String input = 'Hello {!Account.Name}!';

        Test.startTest();
        String result = ContractMergeFieldService.replaceMergeFieldsWithValues(input, contactWithMergeFields);
        Test.stopTest();

        System.Assert.isTrue(
            result.contains(contactWithMergeFields.Account.Name), 
            'Merge field should be replaced with actual value.'
        );
    }

    @IsTest
    static void testFormatFieldValue() {
        Schema.DescribeFieldResult dateFieldDescribe = Account.CreatedDate.getDescribe();

        Test.startTest();
        String formattedDate = ContractMergeFieldService.formatFieldValue(Date.today(), dateFieldDescribe);
        Test.stopTest();

        System.Assert.isNotNull(formattedDate, 'Formatted date should not be empty');
    }

    @IsTest
    static void testFormatNullValue() {
        Schema.DescribeFieldResult annualRevenueFieldDescribe = Account.AnnualRevenue.getDescribe();

        Test.startTest();
        String formattedRevenue = ContractMergeFieldService.formatFieldValue(null, annualRevenueFieldDescribe);
        Test.stopTest();

        System.Assert.areEqual('', formattedRevenue, 'Formatted revenue should be an empty string');
    }

    @IsTest
    static void testFormatCurrencyFieldValue() {
        Schema.DescribeFieldResult annualRevenueFieldDescribe = Account.AnnualRevenue.getDescribe();

        Test.startTest();
        String formattedRevenue = ContractMergeFieldService.formatFieldValue(100.00, annualRevenueFieldDescribe);
        Test.stopTest();

        System.Assert.isNotNull(formattedRevenue, 'Formatted revenue should not be null');
    }

    @IsTest
    static void testRemoveTableBlocks() {
        String waiverWithTables = 'Hello {!TREX1__Contact__r.FirstName} {!tableStart:addOns}Item {!Name}{!tableEnd} Goodbye {!TREX1__Contact__r.LastName}';
        
        Test.startTest();
        String cleaned = ContractMergeFieldService.removeTableBlocks(waiverWithTables);
        Test.stopTest();

        System.assert(cleaned.contains('{!TREX1__Contact__r.FirstName}'), 'First name field should be retained.');
        System.assert(cleaned.contains('{!TREX1__Contact__r.LastName}'), 'Last name field should be retained.');
        System.assert(!cleaned.contains('{!Name}'), 'Field inside table block should be removed.');
        System.assert(!cleaned.contains('{!tableStart:addOns}'), 'tableStart tag should be removed.');
        System.assert(!cleaned.contains('{!tableEnd}'), 'tableEnd tag should be removed.');
    }

    
/*
    @IsTest
    static void testPrepareChildDataSkipsMissingQuery() {
        TREX1__Contract_and_Form__c dummyContract = agrec.TestDataFactory.createContractScenario();

        Map<String, String> emptyQueryMap = new Map<String, String>();
        String waiverText = 'This is a waiver with a table {!tableStart:missingQueryKey}{!Name}{!tableEnd}';

        Test.startTest();
        Map<String, List<SObject>> childData = ContractMergeFieldService.prepareChildData(dummyContract, waiverText, emptyQueryMap);
        Test.stopTest();

        System.assertEquals(0, childData.size(), 'Child data should be empty if query key not found.');
    }

    @IsTest
    static void testExpandTables() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Account1'),
            new Account(Name = 'Account2')
        };
        insert accounts;

        Map<String, List<SObject>> tableData = new Map<String, List<SObject>>{
            'accs' => new List<SObject>( (List<SObject>) accounts)
        };

        String waiverText = 'Start {!tableStart:accs}{!Name}{!tableEnd} End';

        Test.startTest();
        String expanded = ContractMergeFieldService.expandTables(waiverText, tableData);
        Test.stopTest();

        System.assert(expanded.contains('Account1'), 'Expanded text should contain first child record name');
        System.assert(!expanded.contains('{!tableStart:addons}'), 'Start tag should be replaced');
        System.assert(!expanded.contains('{!tableEnd}'), 'End tag should be replaced');
    }

    @IsTest
    static void testGetMergeFieldsFromString() {
        String input = 'Hello {!Name}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'name', 'id'};
        
        Test.startTest();
        Set<String> actualFields = ContractMergeFieldService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testGetMergeFieldsWithFallbackValue() {
        String input = 'Hello {!Name, "Guest"}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'name', 'id'};
        
        Test.startTest();
        Set<String> actualFields = ContractMergeFieldService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testReplaceMergeFieldsWithValues() {
        String accountName = 'Test Account for Merges';
        Account acc = new Account(Name = accountName, NumberOfEmployees = 100, Industry = null);

        String input = 'Hello {!Name} from the {!Industry, &quot;World&quot;}! Congrats on your {!NumberOfEmployees} employees.';

        Test.startTest();
        String result = ContractMergeFieldService.replaceMergeFieldsWithValues(input, acc);
        Test.stopTest();

        System.Assert.areEqual(
            'Hello ' + accountName + ' from the World! Congrats on your 100 employees.',
            result,
            'Merge fields should be replaced with actual values.'
        );
    }

    @IsTest
    static void testReplaceParentMergeFieldsWithValues() {
        Account acc = new Account(Name = 'Test Account for Merges');
        insert acc;

        Contact ct = new Contact(AccountId = acc.Id, FirstName = 'Testeroo', LastName = 'Merges');
        insert ct;

        Contact contactWithMergeFields = [SELECT Id, Account.Name FROM Contact WHERE Id = :ct.Id LIMIT 1];

        String input = 'Hello {!Account.Name}!';

        Test.startTest();
        String result = ContractMergeFieldService.replaceMergeFieldsWithValues(input, contactWithMergeFields);
        Test.stopTest();

        System.Assert.isTrue(
            result.contains(contactWithMergeFields.Account.Name), 
            'Merge field should be replaced with actual value.'
        );
    }

    @IsTest
    static void testFormatFieldValue() {
        Schema.DescribeFieldResult dateFieldDescribe = Account.CreatedDate.getDescribe();

        Test.startTest();
        String formattedDate = ContractMergeFieldService.formatFieldValue(Date.today(), dateFieldDescribe);
        Test.stopTest();

        System.Assert.isnotNull(formattedDate, 'Formatted date should not be empty');
    }

    @IsTest
    static void testFormatNullValue() {
        Schema.DescribeFieldResult annualRevenueFieldDescribe = Account.AnnualRevenue.getDescribe();

        Test.startTest();
        String formattedRevenue = ContractMergeFieldService.formatFieldValue(null, annualRevenueFieldDescribe);
        Test.stopTest();

        System.Assert.areEqual('', formattedRevenue, 'Formatted revenue should be an empty string');
    }

    @IsTest
    static void testFormatCurrencyFieldValue() {
        Schema.DescribeFieldResult annualRevenueFieldDescribe = Account.AnnualRevenue.getDescribe();

        Test.startTest();
        String formattedRevenue = ContractMergeFieldService.formatFieldValue(100.00, annualRevenueFieldDescribe);
        Test.stopTest();

        System.Assert.isNotNull(formattedRevenue, 'Formatted revenue should not be null');
    }

    @IsTest
    static void testRemoveTableBlocks() {
        String waiverWithTables = 'Hello {!TREX1__Contact__r.FirstName} {!tableStart:addOns}Item {!Name}{!tableEnd} Goodbye {!TREX1__Contact__r.LastName}';
        
        Test.startTest();
        String cleaned = ContractMergeFieldService.removeTableBlocks(waiverWithTables);
        Test.stopTest();

        System.assert(cleaned.contains('{!TREX1__Contact__r.FirstName}'), 'First name field should be retained.');
        System.assert(cleaned.contains('{!TREX1__Contact__r.LastName}'), 'Last name field should be retained.');
        System.assert(!cleaned.contains('{!Name}'), 'Field inside table block should be removed.');
        System.assert(!cleaned.contains('{!tableStart:addOns}'), 'tableStart tag should be removed.');
        System.assert(!cleaned.contains('{!tableEnd}'), 'tableEnd tag should be removed.');
    }
        */
    
}