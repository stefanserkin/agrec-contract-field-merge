@IsTest
private class ContractTemplateService_Test {

    @TestSetup
    static void makeData() {
        Contract_and_Form_Query__c query = new Contract_and_Form_Query__c(
            Key__c = 'addOns',
            SOQL_Query__c = 'SELECT Name, TREX1__Status__c FROM TREX1__Add_On__c WHERE TREX1__Registration__c = \'{!TREX1__Registration__c}\''
        );
        insert query;

        TREX1__Contract_or_Form_Template__c template = agrec.TestDataFactory.createContractTemplate();
        insert template;

        Contract_and_Form_Template_Query__c link = new Contract_and_Form_Template_Query__c();
        link.Contract_and_Form_Query__c = query.Id;
        link.Contract_or_Form_Template__c = template.Id;
        insert link;
    }

    @IsTest
    static void testAddTemplatesToCache() {
        Id templateId = [SELECT Id FROM TREX1__Contract_or_Form_Template__c LIMIT 1].Id;

        Test.startTest();
        ContractTemplateService.addTemplates(new Set<Id>{ templateId });
        Test.stopTest();

        Map<Id, TREX1__Contract_or_Form_Template__c> cachedTemplates = ContractTemplateService.getTemplates();
        System.assert(cachedTemplates.containsKey(templateId), 'Template should be cached');

        Map<String, String> queriesByKey = ContractTemplateService.getContractQueriesByKeys();
        System.assert(queriesByKey.containsKey('addOns'), 'Query key addOns should be cached');
        System.assert(queriesByKey.get('addOns').contains('SELECT Name, TREX1__Status__c'), 'SOQL query should match expected');
    }

    @IsTest
    static void testDoesNotReloadAlreadyCachedTemplates() {
        Id templateId = [SELECT Id FROM TREX1__Contract_or_Form_Template__c LIMIT 1].Id;
        ContractTemplateService.addTemplates(new Set<Id>{ templateId });

        Test.startTest();
        ContractTemplateService.addTemplates(new Set<Id>{ templateId });
        Test.stopTest();

        System.assertEquals(1, ContractTemplateService.getTemplates().size(), 'Should not duplicate cached templates');
    }

    @IsTest
    static void testMissingQueryRelationship() {
        TREX1__Contract_or_Form_Template__c lonelyTemplate = agrec.TestDataFactory.createContractTemplate();
        insert lonelyTemplate;

        Test.startTest();
        ContractTemplateService.addTemplates(new Set<Id>{ lonelyTemplate.Id });
        Test.stopTest();

        Map<Id, TREX1__Contract_or_Form_Template__c> cached = ContractTemplateService.getTemplates();
        System.assert(cached.containsKey(lonelyTemplate.Id), 'Template with no queries should still be cached');

        Map<String, String> queriesByKey = ContractTemplateService.getContractQueriesByKeys();
        System.assertEquals(0, queriesByKey.size(), 'No query keys should be cached');
    }
    
}