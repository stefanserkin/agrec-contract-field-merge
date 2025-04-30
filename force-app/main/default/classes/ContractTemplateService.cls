/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Caches templates and associated queries for re-use
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractTemplateService {

    private static Map<Id, TREX1__Contract_or_Form_Template__c> templateMap = new Map<Id, TREX1__Contract_or_Form_Template__c>();
    private static Map<String, String> contractQueriesByKeys = new Map<String, String>();

    public static Map<Id, TREX1__Contract_or_Form_Template__c> getTemplates() {
        return templateMap;
    }

    public static Map<String, String> getContractQueriesByKeys() {
        return contractQueriesByKeys;
    }

    public static void addTemplates(Set<Id> templateIds) {
        Set<Id> templateIdsToAdd = new Set<Id>();
        for (Id templateId : templateIds) {
            if (!templateMap.containsKey(templateId)) {
                templateIdsToAdd.add(templateId);
            }
        }
        loadTemplates(templateIdsToAdd);
    }

    private static void loadTemplates(Set<Id> templateIdsToAdd) {
        for (List<TREX1__Contract_or_Form_Template__c> templates : [
            SELECT Id, TREX1__Waiver_Text__c,
                   (SELECT Contract_and_Form_Query__r.Key__c, Contract_and_Form_Query__r.SOQL_Query__c
                      FROM Contract_and_Form_Template_Queries__r)
              FROM TREX1__Contract_or_Form_Template__c
             WHERE Id IN :templateIdsToAdd
              WITH USER_MODE
        ]) {
            for (TREX1__Contract_or_Form_Template__c template : templates) {
                templateMap.put(template.Id, template);
                
                for (Contract_and_Form_Template_Query__c templateQuery : template.Contract_and_Form_Template_Queries__r) {
                    contractQueriesByKeys.put(
                        templateQuery.Contract_and_Form_Query__r.Key__c, 
                        templateQuery.Contract_and_Form_Query__r.SOQL_Query__c
                    );
                }
            }
        }
    }

}