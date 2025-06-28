/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description 
 * Invocable utility to refresh Contract and Form Waiver Text values
 * 
 * @date 2025
 * @author
 * Asphalt Green Data and Information Systems
 ***********************************************************************/
global with sharing class ContractFieldMergeListInvocable {

    @InvocableMethod(
        label='Refresh Contract Collection Merge Fields'
        description='Refreshes Waiver Text by recalculating merge fields for a collection of Contract and Form records'
        category='agrec'
        iconName='resource:agrec__agGlyph:Layer_1'
    )
    global static List<Result> refreshContracts(List<Request> requests) {
        List<Result> results = new List<Result>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<Id> contractIds = new Set<Id>();
        for (Request request : requests) {
            for (TREX1__Contract_and_Form__c ct : request.contracts) {
                contractIds.add(ct.Id);
            }
        }

        Map<Id, TREX1__Contract_and_Form__c> resolvedContracts = ContractMergeFieldService.mergeById(contractIds);
        updateContracts(requests, resolvedContracts);

        for (Request request : requests) {
            Result result = new Result();

            List<TREX1__Contract_and_Form__c> contractsToReturn = new List<TREX1__Contract_and_Form__c>();
            for (TREX1__Contract_and_Form__c ct : request.contracts) {
                if (resolvedContracts.containsKey(ct.Id)) {
                    contractsToReturn.add( resolvedContracts.get(ct.Id) );
                }
            }

            result.updatedContracts = contractsToReturn;
            results.add(result);
        }

        return results;
    }

    private static void updateContracts(List<Request> requests, Map<Id, TREX1__Contract_and_Form__c> resolvedContracts) {
        Map<Id, TREX1__Contract_and_Form__c> contractsToUpdate = new Map<Id, TREX1__Contract_and_Form__c>();
        for (Request request : requests) {
            if (request.saveChanges) {
                for (TREX1__Contract_and_Form__c contract : request.contracts) {
                    contractsToUpdate.put(contract.Id, resolvedContracts.get(contract.Id));
                }
            }
        }

        if (!contractsToUpdate.isEmpty()) {
            ContractMergeFieldService.updateContracts(contractsToUpdate.values());
        }
    }

    global class Request {
        @InvocableVariable(label='Contract and Form Records' required=true)
        global List<TREX1__Contract_and_Form__c> contracts;

        @InvocableVariable(label='Save Changes')
        global Boolean saveChanges;
    }

    global class Result {
        @InvocableVariable(label='Updated Contract and Forms')
        global List<TREX1__Contract_and_Form__c> updatedContracts;
    }

}