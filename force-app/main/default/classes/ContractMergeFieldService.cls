/***********************************************************************
 * @description Utilities for merge field substitution for an sobject
 *              - Get merge fields from string
 *              - Replace merge fields with values
 * @date 2025
 ***********************************************************************/
public inherited sharing class ContractMergeFieldService {

    private static final String MERGE_FIELD_REGEX = '\\{!([a-zA-Z0-9_.]+)(?:,\\s*(?:"(.*?)"|&quot;(.*?)&quot;))?\\}';
    
    /****************************************************
     * @description Returns a set of field api names for merge fields in the input
     * @param String String containing merge fields
     * @return Set<String> Merge fields
     ****************************************************/
    public static Set<String> getMergeFieldsFromString(String input) {
        Set<String> mergeFields = new Set<String>();
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(input);
        while(m.find()) {
            String fieldApiPath = m.group(1);
            mergeFields.add(fieldApiPath);
        }
        return mergeFields;
    }

    /****************************************************
     * @description Returns the original string with merge fields substituted for their values
     * @param String String containing merge fields to be replaced
     * @param SObject The api name of the sObject type
     * @return String String with merge fields replaced
     ****************************************************/
    public static String replaceMergeFieldsWithValues(String input, SObject obj) {
        String result = input;
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(result);
    
        while (m.find()) {
            String fieldApiPath = m.group(1);
            String defaultValue = m.group(2) != null ? m.group(2) : m.group(3);
    
            Object fieldValue = getFieldValue(obj, fieldApiPath);
            String formattedValue;
            if (fieldValue != null) {
                Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(obj, fieldApiPath);
                formattedValue = formatFieldValue(fieldValue, fieldDescribe);
            } else {
                formattedValue = defaultValue ?? '';
            }
    
            // Replace merge field with resolved value
            result = result.replace(m.group(0), formattedValue);
        }
        return result;
    }

    /****************************************************
     * @description Gets the value of a field from an SObject dynamically, supporting nested relationships.
     *              Assumes that the field exists on the SObject.
     * @param record The SObject to retrieve the field value from
     * @param fieldPath The dot-separated field path (e.g., 'MyObj__r.ParentObj__r.Name')
     * @return The field value as a generic object
     ****************************************************/
    private static Object getFieldValue(SObject record, String fieldPath) {
        Object result;
        List<String> fieldParts = fieldPath.split('\\.');
        SObject currentRecord = record;

        // Iterate through field path parts
        for (Integer i = 0; i < fieldParts.size(); i++) {
            String field = fieldParts[i];

            // If it's the last field in the path, return the field value
            if (i == fieldParts.size() - 1) {
                result = currentRecord.get(field);
                break;
            }

            // Otherwise, traverse the relationship
            currentRecord = currentRecord.getSObject(field);
            if (currentRecord == null) {
                return null;
            }
        }
        return result;
    }

    /****************************************************
     * @description Gets the DescribeFieldResult for a given field path on an SObject.
     *              Supports traversing relationship fields.
     * 
     * @param record The SObject to describe
     * @param fieldPath The dot-separated field path (e.g., 'TREX1__Registration__r.TREX1__Contact__r.Account.Name')
     * @return The Schema.DescribeFieldResult for the last field in the path
     ****************************************************/
    private static Schema.DescribeFieldResult getFieldDescribe(SObject record, String fieldPath) {
        List<String> fieldParts = fieldPath.split('\\.');
        Schema.SObjectType currentSObjectType = record.getSObjectType();

        for (Integer i = 0; i < fieldParts.size(); i++) {
            String fieldName = fieldParts[i];
            Map<String, Schema.SObjectField> fieldMap = currentSObjectType.getDescribe().fields.getMap();

            // Handle relationship field resolution
            if (!fieldMap.containsKey(fieldName)) {
                String lookupFieldName = fieldName.endsWith('__r') ? fieldName.replace('__r', '__c') : fieldName + 'Id';
                if (!fieldMap.containsKey(lookupFieldName)) {
                    return null;
                }
                fieldName = lookupFieldName;
            }

            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // If this is the last field in the path, return its describe result
            if (i == fieldParts.size() - 1) {
                return fieldDescribe;
            }

            // If it's a relationship, update currentSObjectType to the related SObject type
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                if (!referenceTo.isEmpty()) {
                    // Assume single reference type
                    currentSObjectType = referenceTo[0];
                } else {
                    return null;
                }
            } else {
                // If a non-relationship field appears before the last, return null
                return null;
            }
        }

        return null;
    }

    /****************************************************
     * Format field values based on data type
     * @param Object The field value
     * @param Schema.DescribeFieldResult field describe for the provided field
     * @return String Formatted field value
     ****************************************************/
    @TestVisible
    private static String formatFieldValue(Object fieldValue, Schema.DescribeFieldResult fieldDescribe) {
        if (fieldValue == null) {
            return '';
        }

        Schema.DisplayType fieldType = fieldDescribe.getType();

        if (fieldType == Schema.DisplayType.DATE) {
            Date dateValue = (Date) fieldValue;
            return dateValue.format();
        } else if (fieldType == Schema.DisplayType.DATETIME) {
            Datetime datetimeValue = (Datetime) fieldValue;
            return datetimeValue.format();
        } else if (fieldType == Schema.DisplayType.CURRENCY) {
            Decimal currencyValue = (Decimal) fieldValue;
            return '$' + currencyValue.format();
        } else {
            return String.valueOf(fieldValue);
        }
    }

}