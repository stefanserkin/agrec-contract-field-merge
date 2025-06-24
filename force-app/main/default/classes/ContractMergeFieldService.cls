/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Utilities for merge field substitution for an SObject:
 *  - Normalize and validate field paths
 *  - Replace merge fields with values
 *  - Expand dynamic tables
 *  - Remove table blocks from waiver text
 * 
 * @date 2025
 * @author 
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public inherited sharing class ContractMergeFieldService {

    private static final String MERGE_FIELD_REGEX = '\\{!([a-zA-Z0-9_.]+)(?:,\\s*(?:"(.*?)"|&quot;(.*?)&quot;))?\\}';
    private static final String TABLE_BLOCK_REMOVE_REGEX = '\\{!tableStart:[^}]+\\}([\\s\\S]*?)\\{!tableEnd\\}';
    private static final String TABLE_BLOCK_PARSE_REGEX  = '\\{!tableStart:([a-zA-Z0-9_]+)\\}([\\s\\S]+?)\\{!tableEnd\\}';
    
    /****************************************************
     * @description Returns a set of field api names for merge fields in the input
     * @param input String containing merge fields
     * @return Set<String> Merge fields
     ****************************************************/
    public static Set<String> getMergeFieldsFromString(String input) {
        Set<String> mergeFields = new Set<String>();
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(input);
        while (m.find()) {
            String rawFieldPath = m.group(1);
            String normalizedFieldPath = agrec.FieldPathManager.normalize(rawFieldPath);
            if (!isNonFieldCommand(normalizedFieldPath) && agrec.FieldPathManager.isValid(normalizedFieldPath)) {
                mergeFields.add(normalizedFieldPath);
            }
        }
        return mergeFields;
    }

    /****************************************************
     * @description Replaces standard field-level merge fields with actual field values
     * @param input String containing merge fields to be replaced
     * @param obj The sobject record
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
    
            result = result.replace(m.group(0), formattedValue);
        }
        return result;
    }

    /****************************************************
     * @description Removes all table blocks (from {!tableStart:key} to {!tableEnd}) from the input
     * @param input Original string with table blocks
     * @return String Updated string with table blocks removed
     ****************************************************/
    public static String removeTableBlocks(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        Pattern tablePattern = Pattern.compile(TABLE_BLOCK_REMOVE_REGEX);
        Matcher matcher = tablePattern.matcher(input);
        return matcher.replaceAll('');
    }

    /****************************************************
     * @description Expands table blocks for related data based on a preloaded map
     * Handles {!tableStart:key}...{!tableEnd} syntax
     * @param contract
     * @param waiverText
     * @param tableQueryMap
     * @return String
     ****************************************************/
    public static Map<String, List<SObject>> prepareChildData(SObject contract, String waiverText) {
        Map<String, String> tableQueryMap = ContractTemplateService.getContractQueriesByKeys();

        Map<String, List<SObject>> result = new Map<String, List<SObject>>();

        for (String key : tableQueryMap.keySet()) {
            String templateQuery = tableQueryMap.get(key);
            String finalQuery = ContractMergeFieldService.replaceMergeFieldsWithValues(templateQuery, contract);
            List<SObject> childRecords = Database.query(finalQuery);
            result.put(agrec.FieldPathManager.normalize(key), childRecords);
        }

        return result;
    }

    /****************************************************
     * @description Expands table blocks for related data based on a preloaded map
     * Handles {!tableStart:key}...{!tableEnd} syntax
     * @param contract
     * @param waiverText
     * @param tableData
     * @return String
     ****************************************************/
    public static String expandTables(String waiverText, Map<String, List<SObject>> tableData) {
        String result = waiverText;

        Pattern pattern = Pattern.compile(TABLE_BLOCK_PARSE_REGEX);
        Matcher matcher = Pattern.matcher(result);

        while (matcher.find()) {
            String queryKey = matcher.group(1);
            String rowTemplate = matcher.group(2);
            
            List<SObject> childRecords = tableData.get(agrec.FieldPathManager.normalize(queryKey));
            
            String renderedRows = '';
            if (childRecords != null) {
                for (SObject child : childRecords) {
                    String rowContent = replaceMergeFieldsWithValues(rowTemplate, child);
                    renderedRows += rowContent;
                }
            }
            
            result = result.replace(matcher.group(0), renderedRows);
        }

        return result;
    }

    /****************************************************
     * @description Determines if a merge token is a non-field command
     * @param fieldPath
     * @return Boolean True if fieldPath is a non-field command
     ****************************************************/
    private static Boolean isNonFieldCommand(String fieldPath) {
        String lowerFieldPath = fieldPath.toLowerCase();
        return lowerFieldPath.startsWith('tablestart:') || lowerFieldPath == 'tableend';
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
     * @return Schema.DescribeFieldResult for the last field in the path
     ****************************************************/
    @TestVisible
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