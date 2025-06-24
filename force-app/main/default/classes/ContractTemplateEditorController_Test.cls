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

    private static List<ContractTemplateEditorController.TemplateQuery> templateQueries;
    private static List<ContractTemplateEditorController.FieldDescriptor> fieldDescriptors;

    private static User getUser() {
        return agrec.TestDataFactory.getUser(adminPermissionSetNames);
    }

    private static TREX1__Contract_or_Form_Template__c createTemplateWithQueries() {
        TREX1__Contract_or_Form_Template__c template = agrec.TestDataFactory.createContractTemplate();
        insert template;

        Contract_and_Form_Query__c query = new Contract_and_Form_Query__c(
            Key__c = 'addOns',
            SOQL_Query__c = 'SELECT Name, TREX1__Status__c FROM TREX1__Add_On__c WHERE TREX1__Registration__c = \'{!TREX1__Registration__c}\''
        );
        insert query;

        Contract_and_Form_Template_Query__c link = new Contract_and_Form_Template_Query__c();
        link.Contract_and_Form_Query__c = query.Id;
        link.Contract_or_Form_Template__c = template.Id;
        insert link;

        return template;
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
    static void testGetTemplateQueries() {
        System.runAs(getUser()) {
            TREX1__Contract_or_Form_Template__c template = createTemplateWithQueries();

            Test.startTest();
            templateQueries = ContractTemplateEditorController.getTemplateQueries(template.Id);
            Test.stopTest();

            List<Contract_and_Form_Query__c> expectedQueries = [
                SELECT Key__c, SOQL_Query__c
                  FROM Contract_and_Form_Query__c
                 WHERE Id IN (SELECT Contract_and_Form_Query__c
                                FROM Contract_and_Form_Template_Query__c
                               WHERE Contract_or_Form_Template__c = :template.Id)
            ];

            System.Assert.areEqual(1, templateQueries.size(), 'Should have received a single query associated with the template');
            System.Assert.areEqual(expectedQueries[0].Key__c, templateQueries[0].key, 'Received unexpected template query key');

            List<String> expectedSelectFields = expectedQueries[0].SOQL_Query__c
                                            .substringBetween('SELECT', 'FROM')
                                            .deleteWhitespace()
                                            .split(',');

            System.Assert.areEqual(expectedSelectFields.size(), templateQueries[0].fields.size(), 'Should have received a field for each field in the select statement');
        }
    }

    @IsTest
    static void testGetTemplateQueriesWithInvalidId() {
        String invalidId = 'ruhroh';
        System.runAs(getUser()) {
            Test.startTest();
            try {
                ContractTemplateEditorController.getTemplateQueries(invalidId);
                System.Assert.fail('Should have received an exception for the invalid id');
            } catch (Exception e) {
                System.debug(e.getMessage());
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