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
global with sharing class ContractFieldMergeInvocable {

    @InvocableMethod(
        label='Refresh Contract Merge Fields'
        description='Refreshes Waiver Text by recalculating merge fields for a Contract and Form record.'
        category='agrec'
        iconName='resource:agrec__agGlyph:Layer_1'
    )
    global static List<Result> refreshContracts(List<Request> requests) {
        List<Result> results = new List<Result>();

        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<Id> contractIds = new Set<Id>();
        for (Request req : requests) {
            contractIds.add(req.contract.Id);
        }

        Map<Id, TREX1__Contract_and_Form__c> resolvedContracts = ContractMergeFieldService.mergeById(contractIds);
        updateContracts(requests, resolvedContracts);

        for (Request request : requests) {
            Result res = new Result();
            res.updatedContract = resolvedContracts.get(request.contract.Id);
            results.add(res);
        }

        return results;
    }

    private static void updateContracts(List<Request> requests, Map<Id, TREX1__Contract_and_Form__c> resolvedContracts) {
        Map<Id, TREX1__Contract_and_Form__c> contractsToUpdate = new Map<Id, TREX1__Contract_and_Form__c>();
        for (Request request : requests) {
            if (request.updateRecord) {
                Id contractId = request.contract.Id;
                contractsToUpdate.put(contractId, resolvedContracts.get(contractId));
            }
        }

        if (!contractsToUpdate.isEmpty()) {
            ContractMergeFieldService.updateContracts(contractsToUpdate.values());
        }
    }

    global class Request {
        @InvocableVariable(label='Contract and Form Record')
        global TREX1__Contract_and_Form__c contract;

        @InvocableVariable(label='Update Record')
        global Boolean updateRecord;
    }

    global class Result {
        @InvocableVariable(label='Updated Contract and Form')
        global TREX1__Contract_and_Form__c updatedContract;
    }

}