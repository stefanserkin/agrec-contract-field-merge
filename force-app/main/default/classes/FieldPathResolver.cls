/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 *
 * @description
 * Utility class for resolving field paths across relationships
 *
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class FieldPathResolver {
    
    public class ResolutionResult {
        public String apiName;
        public String label;
        public String objectApiName;
        public Boolean isRelationship;
        public String relationshipName;
        public Schema.DescribeFieldResult fieldDescribe;
    }

    /**
     * Resolves a nested field path (e.g., "Contact.Account.Industry") from a base SObjectType.
     * 
     * @param baseType The starting SObjectType (e.g., Schema.Case.sObjectType)
     * @param fieldPath The dot-notation field path to resolve
     * @return A ResolutionResult with label, API name, object name, etc.
     */
    public static ResolutionResult resolveFieldPath(Schema.SObjectType baseType, String fieldPath) {
        ResolutionResult result = new ResolutionResult();
        result.apiName = fieldPath;
        result.label = null;
        result.objectApiName = baseType.getDescribe().getName();
        result.isRelationship = false;
        result.relationshipName = null;

        try {
            List<String> segments = fieldPath.split('\\.');
            Schema.SObjectType currentType = baseType;

            for (Integer i = 0; i < segments.size(); i++) {
                String segment = segments[i];
                Schema.DescribeSObjectResult describe = currentType.getDescribe();
                Map<String, Schema.SObjectField> fieldMap = describe.fields.getMap();

                Schema.DescribeFieldResult fieldDescribe = null;

                // Match directly first
                if (fieldMap.containsKey(segment)) {
                    fieldDescribe = fieldMap.get(segment).getDescribe();
                } else {
                    // Fallback: match by relationship name
                    for (Schema.SObjectField field : fieldMap.values()) {
                        Schema.DescribeFieldResult d = field.getDescribe();
                        if (d.getRelationshipName() != null && d.getRelationshipName().equalsIgnoreCase(segment)) {
                            fieldDescribe = d;
                            break;
                        }
                    }
                }

                if (fieldDescribe == null) {
                    return result; // Field not found
                }

                if (i == segments.size() - 1) {
                    result.label = fieldDescribe.getLabel();
                    result.objectApiName = currentType.getDescribe().getName();
                    result.isRelationship = (segments.size() > 1);
                    result.relationshipName = (segments.size() > 1) ? segments[i - 1] : null;
                    result.fieldDescribe = fieldDescribe;
                    return result;
                }

                // Traverse relationship
                if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                    List<Schema.SObjectType> refTypes = fieldDescribe.getReferenceTo();
                    if (!refTypes.isEmpty()) {
                        currentType = refTypes[0];
                    } else {
                        return result;
                    }
                } else {
                    return result; // Can't traverse non-relationship
                }
            }
        } catch (Exception e) {
            System.debug('FieldPathResolver error: ' + e.getMessage());
        }

        return result;
    }


}