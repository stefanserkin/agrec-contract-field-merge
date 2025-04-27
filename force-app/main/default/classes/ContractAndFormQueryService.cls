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

    private static Map<String, Contract_and_Form_Query__c> cachedQueries = new Map<String, Contract_and_Form_Query__c>();

    public static void loadQueriesFromContracts(List<TREX1__Contract_and_Form__c> contracts) {
        Set<String> neededKeys = new Set<String>();

        for (TREX1__Contract_and_Form__c contract : contracts) {
            if (String.isNotBlank(contract.TREX1__Waiver_Text__c)) {
                neededKeys.addAll(detectNeededQueryKeys(contract.TREX1__Waiver_Text__c));
            }
        }

        if (!neededKeys.isEmpty()) {
            List<Contract_and_Form_Query__c> queryRecords = [
                SELECT Key__c, SOQL_Query__c
                FROM Contract_and_Form_Query__c
                WHERE Key__c IN :neededKeys
            ];

            for (Contract_and_Form_Query__c record : queryRecords) {
                cachedQueries.put(CFM_FieldPathManager.normalize(record.Key__c), record);
            }
        }
    }

    public static Map<String, Contract_and_Form_Query__c> getCachedQueries() {
        return cachedQueries;
    }

    public static void clearCache() {
        cachedQueries.clear();
    }

    public static Set<String> detectNeededQueryKeys(String waiverText) {
        Set<String> keys = new Set<String>();

        if (String.isBlank(waiverText)) {
            return keys;
        }

        Pattern pattern = Pattern.compile('\\{!tableStart:([a-zA-Z0-9_]+)\\}');
        Matcher matcher = pattern.matcher(waiverText);

        while (matcher.find()) {
            String key = matcher.group(1);
            if (String.isNotBlank(key)) {
                keys.add(CFM_FieldPathManager.normalize(key));
            }
        }

        return keys;
    }

}
