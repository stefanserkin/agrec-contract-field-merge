/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Controller for the contractTemplateEditor component and child components
 *  - Get waiver text with merge field value substitution
 *  - Gather field metadata for merging into a contract template
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractTemplateEditorController {

    @AuraEnabled(cacheable=true)
    public static String getPreviewWaiverText(String templateId, String contractId) {
        try {
            TREX1__Contract_or_Form_Template__c template = [
                SELECT Id, TREX1__Waiver_Text__c
                  FROM TREX1__Contract_or_Form_Template__c
                 WHERE Id = :templateId
                 LIMIT 1
            ];

            TREX1__Contract_and_Form__c contract = new TREX1__Contract_and_Form__c(
                Id = contractId,
                TREX1__caf_Template__c = template.Id,
                TREX1__Waiver_Text__c = template.TREX1__Waiver_Text__c
            );

            ContractFieldMerge fieldMerge = new ContractFieldMerge( new List<TREX1__Contract_and_Form__c>{contract} );
            TREX1__Contract_and_Form__c updatedForm = fieldMerge.populateMergeFields().get(0);
            return updatedForm.TREX1__Waiver_Text__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldDescriptor> getFieldDescriptors(String objectApiName, String relationshipPath) {
        List<FieldDescriptor> results = new List<FieldDescriptor>();

        try {
            DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
            Map<String, SObjectField> fieldsMap = describeResult.fields.getMap();

            for (String fieldName : fieldsMap.keySet()) {
                DescribeFieldResult fieldDescribe = fieldsMap.get(fieldName).getDescribe();
                FieldDescriptor descriptor = new FieldDescriptor();
                descriptor.label = fieldDescribe.getLabel();

                String qualifiedName = fieldDescribe.getName();
                if (String.isNotBlank(relationshipPath)) {
                    qualifiedName = relationshipPath + '.' + qualifiedName;
                }
                descriptor.apiName = qualifiedName;

                descriptor.isRelationship = fieldDescribe.getType() == Schema.DisplayType.REFERENCE;
                descriptor.relationshipName = descriptor.isRelationship ? fieldDescribe.getRelationshipName() : null;
                
                if (descriptor.isRelationship) {
                    List<Schema.SObjectType> relatedTypes = fieldDescribe.getReferenceTo();
                    if (!relatedTypes.isEmpty()) {
                        descriptor.targetObjectApiName = relatedTypes[0].getDescribe().getName();
                    }
                }

                results.add(descriptor);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error describing fields for ' + objectApiName + ': ' + ex.getMessage());
        }

        return results;
    }

    public class FieldDescriptor {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean isRelationship;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public String targetObjectApiName;
    }

}