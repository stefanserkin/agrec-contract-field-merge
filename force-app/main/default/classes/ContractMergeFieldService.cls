/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Service layer for initiating merge field population on Contract and Form records.
 * 
 * This utility class exposes static methods for resolving and optionally updating
 * waiver text on Contract and Form (`TREX1__Contract_and_Form__c`) records. It serves 
 * as a shared entry point for invocable methods and other process automation that 
 * require merge field substitution.
 * 
 * Responsibilities:
 * - Return fully populated waiver text values for a set of record ids
 * - Provide a safe update operation (in system mode) to persist those changes
 * 
 * This class delegates merge logic to the ContractFieldMerge domain class.
 * 
 * @date 2025
 * @author 
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
public with sharing class ContractMergeFieldService {

    public static Map<Id, TREX1__Contract_and_Form__c> mergeById(Set<Id> contractIds) {
        if (contractIds == null || contractIds.isEmpty()) return new Map<Id, TREX1__Contract_and_Form__c>();

        List<TREX1__Contract_and_Form__c> contracts = fetchContractsById(contractIds);
        List<TREX1__Contract_and_Form__c> updatedContract = new ContractFieldMerge(contracts).resolveMergeFields();
        return new Map<Id, TREX1__Contract_and_Form__c>(updatedContract);
    }

    public static void updateContracts(List<TREX1__Contract_and_Form__c> contractsToUpdate) {
        Database.update(contractsToUpdate, AccessLevel.SYSTEM_MODE);
    }

    private static List<TREX1__Contract_and_Form__c> fetchContractsById(Set<Id> contractIds) {
        return [
            SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c
              FROM TREX1__Contract_and_Form__c
             WHERE Id IN :contractIds
              WITH USER_MODE
        ];
    }

}