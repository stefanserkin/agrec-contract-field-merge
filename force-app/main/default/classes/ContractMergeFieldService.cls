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
public with sharing class ContractMergeFieldService {

    public static Map<Id, TREX1__Contract_and_Form__c> mergeById(Set<Id> contractIds) {
        if (contractIds == null || contractIds.isEmpty()) return new Map<Id, TREX1__Contract_and_Form__c>();

        List<TREX1__Contract_and_Form__c> contracts = fetchContractsById(contractIds);
        List<TREX1__Contract_and_Form__c> updated = new ContractFieldMerge(contracts).resolveMergeFields();
        return new Map<Id, TREX1__Contract_and_Form__c>(updated);
    }

    private static List<TREX1__Contract_and_Form__c> fetchContractsById(Set<Id> contractIds) {
        return [
            SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c
              FROM TREX1__Contract_and_Form__c
             WHERE Id IN :contractIds
              WITH USER_MODE
        ];
    }

    public static void updateContracts(List<TREX1__Contract_and_Form__c> contractsToUpdate) {
        Database.update(contractsToUpdate, AccessLevel.SYSTEM_MODE);
    }

}