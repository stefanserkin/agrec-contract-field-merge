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
    static void testFormatDatetimeFieldValue() {
        Schema.DescribeFieldResult datetimeFieldDescribe = Account.CreatedDate.getDescribe();

        Test.startTest();
        String formattedDatetime = ContractMergeFieldService.formatFieldValue(Datetime.now(), datetimeFieldDescribe);
        Test.stopTest();

        System.Assert.isNotNull(formattedDatetime, 'Formatted date/time should not be empty');
    }

    @IsTest
    static void testFormatDateFieldValue() {
        Schema.DescribeFieldResult dateFieldDescribe = Opportunity.CloseDate.getDescribe();

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

        System.Assert.isTrue(cleaned.contains('{!TREX1__Contact__r.FirstName}'), 'First name field should be retained.');
        System.Assert.isTrue(cleaned.contains('{!TREX1__Contact__r.LastName}'), 'Last name field should be retained.');
        System.Assert.isTrue(!cleaned.contains('{!Name}'), 'Field inside table block should be removed.');
        System.Assert.isTrue(!cleaned.contains('{!tableStart:addOns}'), 'tableStart tag should be removed.');
        System.Assert.isTrue(!cleaned.contains('{!tableEnd}'), 'tableEnd tag should be removed.');
    }

    @IsTest
    static void testRemoveTableBlocksWithEmptyInput() {
        String emptyInput = '';
        
        Test.startTest();
        String cleaned = ContractMergeFieldService.removeTableBlocks(emptyInput);
        Test.stopTest();

        System.Assert.isTrue(String.isBlank(cleaned), 'Should have received an empty string');
    }

    @IsTest
    static void testGetFieldDescribeForInvalidField() {
        String invalidField = 'ruhroh__r';
        Contact contact = new Contact(FirstName = 'Testeroo', LastName = 'Testeroodle');

        Test.startTest();
        Schema.DescribeFieldResult fieldDescribe = ContractMergeFieldService.getFieldDescribe(contact, invalidField);
        Test.stopTest();

        System.Assert.isNull(fieldDescribe, 'Should have received a null response for the invalid field');
    }
    
}