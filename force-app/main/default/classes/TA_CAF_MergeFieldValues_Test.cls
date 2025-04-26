@IsTest
private class TA_CAF_MergeFieldValues_Test {

    @TestSetup
    static void makeData() {
        TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
        insert contract;
    }

    @IsTest
    static void testPopulateMergeFields() {
        TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__Waiver_Text__c FROM TREX1__Contract_and_Form__c LIMIT 1];

        Test.startTest();
        TA_CAF_MergeFieldValuesAI triggerAction = new TA_CAF_MergeFieldValuesAI();
        triggerAction.afterInsert(new List<TREX1__Contract_and_Form__c>{contract});
        Test.stopTest();

        TREX1__Contract_and_Form__c refreshedContract = [SELECT TREX1__Waiver_Text__c, Name, TREX1__Account__r.Name, TREX1__Contact__r.Account.Name FROM TREX1__Contract_and_Form__c WHERE Id = :contract.Id LIMIT 1];
        String waiverText = refreshedContract.TREX1__Waiver_Text__c;

        System.Assert.isTrue(waiverText.contains(refreshedContract.Name), 'Should have received the contract name. Received: ' + waiverText);
        System.Assert.isTrue(waiverText.contains(refreshedContract.TREX1__Account__r.Name), 'Should have received the account name. Received: ' + waiverText);
        System.Assert.isTrue(waiverText.contains(refreshedContract.TREX1__Contact__r.Account.Name), 'Should have received the account name through the contact. Received: ' + waiverText);
    }

}