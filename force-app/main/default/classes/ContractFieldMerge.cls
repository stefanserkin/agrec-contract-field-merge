/***********************************************************************
 * @license
 * MIT License
 * Copyright (c) 2025 Asphalt Green, Inc.
 * See the LICENSE file in the project root for full license text.
 * 
 * @description Service to prepare Contract and Form records by merging
 *              field-level and table-level data.
 * @date 2025
 * @author
 * Asphalt Green Data Systems Team
 ***********************************************************************/
public with sharing class ContractFieldMerge {

    private static final String WAIVER_TEXT_FIELD = 'TREX1__Waiver_Text__c';

    private List<TREX1__Contract_and_Form__c> contracts;

    public ContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = Database.query(getQuery());
        
        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            String waiverText = contract.TREX1__Waiver_Text__c;
            if (String.isBlank(waiverText)) {
                continue;
            }
            
            // Prepare child data in bulk for this contract
            Map<String, List<SObject>> tableData = ContractAndFormQueryService.prepareChildData(contract, waiverText);
            
            // First expand tables
            waiverText = expandTables(contract, waiverText, tableData);
            
            // Then expand regular merge fields
            waiverText = ContractMergeFieldService.replaceMergeFieldsWithValues(waiverText, contract);
            
            // Save back
            contract.TREX1__Waiver_Text__c = waiverText;
        }
        
        return contractsWithMergeInfo;
    }

    private String getQuery() {
        List<String> mergeFields = getMergeFields();
        String query = 'SELECT ' + String.join(mergeFields, ', ') +
                       ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
        return query;
    }

    private List<String> getMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{
            FieldPathManager.normalize(WAIVER_TEXT_FIELD)
        };
        for (TREX1__Contract_and_Form__c contract : contracts) {
            uniqueMergeFields.addAll(ContractMergeFieldService.getMergeFieldsFromString(contract.TREX1__Waiver_Text__c));
        }
        return new List<String>(uniqueMergeFields);
    }

    private static String expandTables(SObject contract, String waiverText, Map<String, List<SObject>> preloadedData) {
        String result = waiverText;
        
        Pattern pattern = Pattern.compile('\\{!tableStart:([a-zA-Z0-9_]+)\\}([\\s\\S]+?)\\{!tableEnd\\}');
        Matcher matcher = pattern.matcher(result);

        while (matcher.find()) {
            String queryKey = matcher.group(1);
            String rowTemplate = matcher.group(2);
            
            List<SObject> childRecords = preloadedData.get(queryKey);
            
            String renderedRows = '';
            if (childRecords != null) {
                for (SObject child : childRecords) {
                    String rowContent = ContractMergeFieldService.replaceMergeFieldsWithValues(rowTemplate, child);
                    renderedRows += rowContent;
                }
            }
            
            result = result.replace(matcher.group(0), renderedRows);
        }
        
        return result;
    }

}
