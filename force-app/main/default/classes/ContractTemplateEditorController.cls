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
        @AuraEnabled public String targetObjectApiName;
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
                System.debug(':::: ready to append relationshipPath (' + relationshipPath + ') and qualifiedName (' + qualifiedName + ')');
                if (String.isNotBlank(relationshipPath)) {
                    System.debug('::::: relationshipPath is not blank');
                    qualifiedName = relationshipPath + '.' + qualifiedName;
                }
                descriptor.apiName = qualifiedName;
                System.debug('::: set apiName --> ' + descriptor.apiName);

                descriptor.isRelationship = fieldDescribe.getType() == Schema.DisplayType.REFERENCE;
                descriptor.relationshipName = descriptor.isRelationship ? fieldDescribe.getRelationshipName() : null;
                
                if (descriptor.isRelationship) {
                    System.debug('::: evaluating relationship --> ' + descriptor);
                    List<Schema.SObjectType> relatedTypes = fieldDescribe.getReferenceTo();
                    System.debug('::: relatedTypes --> ' + relatedTypes);
                    if (!relatedTypes.isEmpty()) {
                        descriptor.targetObjectApiName = relatedTypes[0].getDescribe().getName();
                        System.debug('::: targetObjectApiName --> ' + descriptor.targetObjectApiName);
                    }
                }

                results.add(descriptor);
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Error describing fields for ' + objectApiName + ': ' + ex.getMessage());
        }

        return results;
    }

}