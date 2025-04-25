@IsTest
private class ContractMergeFieldService_Test {

    @IsTest
    static void testGetMergeFieldsFromString() {
        String input = 'Hello {!Name}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'Name', 'Id'};
        
        Test.startTest();
        Set<String> actualFields = ContractMergeFieldService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testGetMergeFieldsWithFallbackValue() {
        String input = 'Hello {!Name, "Guest"}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'Name', 'Id'};
        
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
    
}