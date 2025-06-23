@IsTest
private class ContractTemplateEditorController_Test {

    private static final String PERM_SET_TREC_BASE_ACCESS = 'Traction_Rec_Base_Access_v2';
    private static final String PERM_SET_TREC_FULL_ACCESS = 'Traction_Rec_Full_Access';
    private static final String PERM_SET_MERGE_ADMIN = 'agrec_Contract_and_Form_Admin';
    
    private static List<String> adminPermissionSetNames = new List<String>{
        PERM_SET_TREC_BASE_ACCESS,
        PERM_SET_TREC_FULL_ACCESS, 
        PERM_SET_MERGE_ADMIN
    };

    private static List<ContractTemplateEditorController.FieldDescriptor> fieldDescriptors;

    private static User getUser() {
        return agrec.TestDataFactory.getUser(adminPermissionSetNames);
    }
    
    @IsTest
    static void testGetPreviewWaiverText() {
        System.runAs(getUser()) {
            TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
            insert contract;

            Test.startTest();
            String waiverText = ContractTemplateEditorController.getPreviewWaiverText(contract.TREX1__caf_Template__c, contract.Id);
            Test.stopTest();

            TREX1__Contract_and_Form__c refreshedContract = [SELECT TREX1__Waiver_Text__c FROM TREX1__Contract_and_Form__c WHERE Id = :contract.Id LIMIT 1];
            System.Assert.areEqual(refreshedContract.TREX1__Waiver_Text__c, waiverText, 'Waiver text should be the same as the contract\'s waiver text');
        }
    }

    @IsTest
    static void testGetPreviewWaiverTextWithFakeTemplateId() {
        System.runAs(getUser()) {
            String fakeTemplateId = agrec.TriggerTestUtility.getFakeId(TREX1__Contract_and_Form__c.SObjectType);

            TREX1__Contract_and_Form__c contract = agrec.TestDataFactory.createContractScenario();
            insert contract;

            Test.startTest();
            try {
                String waiverText = ContractTemplateEditorController.getPreviewWaiverText(fakeTemplateId, contract.Id);
                System.Assert.fail('Should have received an exception for the invalid record id');
            } catch (Exception e) {
                System.debug('Exception: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetFieldDescriptors() {
        System.runAs(getUser()) {
            String objectApiName = 'TREX1__Contract_and_Form__c';

            Test.startTest();
            fieldDescriptors = ContractTemplateEditorController.getFieldDescriptors(objectApiName, null);
            Test.stopTest();

            System.Assert.isFalse(fieldDescriptors.isEmpty(), 'Should have received field descriptors for the Contract and Form object');

            for (ContractTemplateEditorController.FieldDescriptor descriptor : fieldDescriptors) {
                System.Assert.isNotNull(descriptor.label, 'Label should not be null');
                System.Assert.isNotNull(descriptor.apiName, 'API Name should not be null');

                // If it's a relationship, validate extra fields
                if (descriptor.isRelationship) {
                    System.Assert.isNotNull(descriptor.relationshipName, 'Relationship name should not be null');
                    System.Assert.isNotNull(descriptor.targetObjectApiName, 'Target object API name should not be null');
                }
            }
        }
    }

    @IsTest
    static void testGetFieldDescriptorsForRelationshipPath() {
        System.runAs(getUser()) {
            String objectApiName = 'TREX1__Membership__c';
            String relationshipPath = 'TREX1__Membership__r';
            
            Test.startTest();
            fieldDescriptors = ContractTemplateEditorController.getFieldDescriptors(objectApiName, relationshipPath);
            Test.stopTest();

            System.Assert.isFalse(fieldDescriptors.isEmpty(), 'Should have received field descriptors for the Membership object');

            for (ContractTemplateEditorController.FieldDescriptor descriptor : fieldDescriptors) {
                System.Assert.isTrue(descriptor.apiName.startsWith(relationshipPath), 'Field path should start with the provided relationship path');
                System.Assert.isNotNull(descriptor.label, 'Label should not be null');
                System.Assert.isNotNull(descriptor.apiName, 'API Name should not be null');

                // If it's a relationship, validate extra fields
                if (descriptor.isRelationship) {
                    System.Assert.isNotNull(descriptor.relationshipName, 'Relationship name should not be null');
                    System.Assert.isNotNull(descriptor.targetObjectApiName, 'Target object API name should not be null');
                }
            }
        }
    }

    @IsTest
    static void testGetFieldDescriptorsForInvalidObject() {
        String objectApiName = 'Ruhroh';
        
        Test.startTest();
        try {
            fieldDescriptors = ContractTemplateEditorController.getFieldDescriptors(objectApiName, null);
            System.Assert.fail('Should have received an exception for the invalid object name');
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
}