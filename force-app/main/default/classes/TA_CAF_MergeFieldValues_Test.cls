@IsTest
private class TA_CAF_MergeFieldValues_Test {

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
    static void testresolveMergeFields() {
        System.runAs(getUser()) {
            makeData();

            TREX1__Contract_and_Form__c contract = [SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c FROM TREX1__Contract_and_Form__c LIMIT 1];

            Test.startTest();
            TA_CAF_MergeFieldValuesAI triggerAction = new TA_CAF_MergeFieldValuesAI();
            triggerAction.afterInsert(new List<TREX1__Contract_and_Form__c>{contract});
            Test.stopTest();

            TREX1__Contract_and_Form__c refreshedContract = [SELECT TREX1__Waiver_Text__c, Name, TREX1__Account__r.Name, TREX1__Contact__r.FirstName FROM TREX1__Contract_and_Form__c WHERE Id = :contract.Id LIMIT 1];
            String waiverText = refreshedContract.TREX1__Waiver_Text__c;

            System.Assert.isTrue(waiverText.contains(refreshedContract.TREX1__Account__r.Name), 'Should have received the account name. Received: ' + waiverText);
            System.Assert.isTrue(waiverText.contains(refreshedContract.TREX1__Contact__r.FirstName), 'Should have received the contact\'s first name. Received: ' + waiverText);
        }
    }

}