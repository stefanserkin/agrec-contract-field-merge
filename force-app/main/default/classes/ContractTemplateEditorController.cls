/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description
 * Gathers field metadata for merging into contract templates
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractTemplateEditorController {

    public class FieldDescriptor {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean isRelationship;
        @AuraEnabled public String relationshipName;
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldDescriptor> getFieldDescriptors(String objectApiName) {
        return getFieldDescriptorsForPath(objectApiName, null);
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldDescriptor> getFieldDescriptorsForPath(String objectApiName, String relationshipPath) {
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
                results.add(descriptor);
            }

            // Add special handling for known child relationships (e.g. Contract Items)
            if (objectApiName == 'TREX1__Contract_and_Form__c') {
                FieldDescriptor tableStub = new FieldDescriptor();
                tableStub.label = 'Contract Items Table';
                tableStub.apiName = 'table:contractItems';
                tableStub.isRelationship = true;
                results.add(tableStub);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error describing fields for ' + objectApiName + ': ' + ex.getMessage());
        }

        return results;
    }

}