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

    private static final String STATUS_DRAFT = 'Draft';
    private static final String TYPE_WAIVER = 'Waiver Form';

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
                TREX1__Waiver_Text__c = template.TREX1__Waiver_Text__c,
                TREX1__Status__c = STATUS_DRAFT,
                TREX1__Type__c = TYPE_WAIVER
            );

            ContractFieldMerge fieldMerge = new ContractFieldMerge( new List<TREX1__Contract_and_Form__c>{contract} );
            TREX1__Contract_and_Form__c updatedForm = fieldMerge.populateMergeFields().get(0);
            return updatedForm.TREX1__Waiver_Text__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    @AuraEnabled(cacheable=true)
    public static List<TemplateQuery> getTemplateQueries(String templateId) {
        List<TemplateQuery> templateQueries = new List<TemplateQuery>();

        try {
            Id tId = Id.valueOf(templateId);
            for (List<Contract_and_Form_Template_Query__c> sobjs : [
                SELECT Contract_and_Form_Query__r.Key__c, Contract_and_Form_Query__r.Name, Contract_and_Form_Query__r.SOQL_Query__c
                  FROM Contract_and_Form_Template_Query__c
                 WHERE Contract_or_Form_Template__c = :tId
            ]) {
                for (Contract_and_Form_Template_Query__c sobj : sobjs) {
                    TemplateQuery tq = new TemplateQuery();
                    tq.key = sobj.Contract_and_Form_Query__r.Key__c;
                    tq.name = sobj.Contract_and_Form_Query__r.Name;
                    tq.fields = new List<FieldDescriptor>();

                    List<String> selectedFields = sobj.Contract_and_Form_Query__r.SOQL_Query__c
                        .substringBetween('SELECT', 'FROM')
                        .deleteWhitespace()
                        .split(',');

                    for (String selectedField : selectedFields) {
                        FieldDescriptor fd = new FieldDescriptor();
                        fd.apiName = selectedField;
                        tq.fields.add(fd);
                    }

                    templateQueries.add(tq);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return templateQueries;
    }
        */

    @AuraEnabled(cacheable=true)
    public static List<TemplateQuery> getTemplateQueries(String templateId) {
        List<TemplateQuery> templateQueries = new List<TemplateQuery>();

        try {
            Id tId = Id.valueOf(templateId);

            for (List<Contract_and_Form_Template_Query__c> sobjs : [
                SELECT Contract_and_Form_Query__r.Key__c, Contract_and_Form_Query__r.Name, Contract_and_Form_Query__r.SOQL_Query__c
                  FROM Contract_and_Form_Template_Query__c
                 WHERE Contract_or_Form_Template__c = :tId
            ]) {
                for (Contract_and_Form_Template_Query__c sobj : sobjs) {
                    Contract_and_Form_Query__c query = sobj.Contract_and_Form_Query__r;

                    TemplateQuery tq = new TemplateQuery();
                    tq.key = query.Key__c;
                    tq.name = query.Name;
                    tq.fields = new List<FieldDescriptor>();

                    // Parse SELECT clause
                    List<String> selectedFields = query.SOQL_Query__c
                        .substringBetween('SELECT', 'FROM')
                        .deleteWhitespace()
                        .split(',');

                    String baseObjectName = query.SOQL_Query__c
                        .substringBetween('FROM', 'WHERE')
                        .deleteWhitespace();
                        
                    Schema.SObjectType baseType = Schema.getGlobalDescribe().get(baseObjectName);
                    if (baseType == null) {
                        throw new AuraHandledException('Could not resolve base object for field introspection');
                    }

                    for (String fieldPath : selectedFields) {
                        FieldPathResolver.ResolutionResult res = FieldPathResolver.resolveFieldPath(baseType, fieldPath);
                        FieldDescriptor fd = new FieldDescriptor();
                        fd.apiName = res.apiName;
                        fd.label = res.label;
                        fd.targetObjectApiName = res.objectApiName;
                        fd.isRelationship = res.isRelationship;
                        fd.relationshipName = res.relationshipName;

                        tq.fields.add(fd);
                    }

                    templateQueries.add(tq);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate template queries: ' + e.getMessage());
        }

        return templateQueries;
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

    public class TemplateQuery {
        @AuraEnabled public String key;
        @AuraEnabled public String name;
        @AuraEnabled public List<FieldDescriptor> fields;
    }

    public class FieldDescriptor {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean isRelationship;
        @AuraEnabled public String relationshipName;
        @AuraEnabled public String targetObjectApiName;
    }

}