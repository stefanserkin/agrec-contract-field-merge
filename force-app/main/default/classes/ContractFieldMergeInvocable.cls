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

        List<TREX1__Contract_and_Form__c> contracts = getContractsFromRequests(requests);
        List<TREX1__Contract_and_Form__c> updatedContracts = new ContractFieldMerge(contracts).populateMergeFields();

        Map<Id, TREX1__Contract_and_Form__c> updatedContractMap = new Map<Id, TREX1__Contract_and_Form__c>(updatedContracts);
        for (Request request : requests) {
            Result res = new Result();

            TREX1__Contract_and_Form__c updatedContract = updatedContractMap.get(request.contract.Id);
            request.contract.TREX1__Waiver_Text__c = updatedContract.TREX1__Waiver_Text__c;
            res.updatedContract = request.contract;
            results.add(res);
        }

        return results;
    }

    private static List<TREX1__Contract_and_Form__c> getContractsFromRequests(List<Request> requests) {
        Set<Id> contractIds = new Set<Id>();
        for (Request req : requests) {
            contractIds.add(req.contract.Id);
        }

        return [
            SELECT Id, TREX1__caf_Template__c, TREX1__Status__c, TREX1__Type__c
              FROM TREX1__Contract_and_Form__c
             WHERE Id IN :contractIds
              WITH USER_MODE
        ];
    }

    global class Request {
        @InvocableVariable(label='Contract and Form Record' required=true)
        global TREX1__Contract_and_Form__c contract;
    }

    global class Result {
        @InvocableVariable(label='Updated Contract and Form')
        global TREX1__Contract_and_Form__c updatedContract;
    }

}