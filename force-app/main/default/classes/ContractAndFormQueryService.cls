/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Service to retrieve related child data for Contract and Form merge tables.
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractAndFormQueryService {

    private static final String TABLE_PATTERN = '\\{!tableStart:([a-zA-Z0-9_]+)\\}';

    public static Map<String, List<SObject>> prepareChildData(SObject contract, String waiverText) {
        Set<String> neededKeys = getNeededQueryKeys(waiverText);
        
        if (neededKeys.isEmpty()) {
            return new Map<String, List<SObject>>();
        }
        
        List<Contract_and_Form_Query__c> queryRecords = [
            SELECT Key__c, SOQL_Query__c
              FROM Contract_and_Form_Query__c
             WHERE Key__c IN :neededKeys
        ];
        
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();
        
        for (Contract_and_Form_Query__c queryRec : queryRecords) {
            String finalQuery = ContractMergeFieldService.replaceMergeFieldsWithValues(queryRec.SOQL_Query__c, contract);
            List<SObject> childRecords = Database.query(finalQuery);
            result.put(FieldPathManager.normalize(queryRec.Key__c), childRecords);
        }
        
        return result;
    }

    private static Set<String> getNeededQueryKeys(String waiverText) {
        Set<String> keys = new Set<String>();
        
        Pattern pattern = Pattern.compile(TABLE_PATTERN);
        Matcher matcher = pattern.matcher(waiverText);
        
        while (matcher.find()) {
            String queryKey = matcher.group(1);
            keys.add(FieldPathManager.normalize(queryKey));
        }
        
        return keys;
    }

}
