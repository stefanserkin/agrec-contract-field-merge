@IsTest
@NamespaceAccessible
public class CFM_TestDataFactory {

    /**
     * Accounts
     */
    @NamespaceAccessible
    public static List<Account> createAccounts(Integer numberOfRecords) {
        List<Account> records = new List<Account>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            records.add(
                new Account(Name = 'Test account ' + String.valueOf(i))
            );
        }
        return records;
    }

    /**
     * Contacts
     */
    @NamespaceAccessible
    public static List<Contact> createContacts(Integer numberOfRecords) {
        List<Contact> records = new List<Contact>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            records.add(
                new Contact(
                    FirstName = 'Tester' + String.valueOf(i),
                    LastName = 'Testeroo' + String.valueOf(i),
                    Email = 'testeroodle' + String.valueOf(i) + '@example.com'
                )
            );
        }
        return records;
    }
    
    /**
     * Content Document Links
     */
    @NamespaceAccessible
    public static List<ContentDocumentLink> createReceipts(List<SObject> linkedEntities) {
        ContentVersion cv = new ContentVersion();
        cv.title = 'receipt-012345';
        cv.PathOnClient ='test';
        cv.VersionData = Blob.valueOf('Test File Body');
        insert cv;

        ContentVersion cvRefreshed = [SELECT Id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];

        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (SObject sobj : linkedEntities) {
            Id linkedEntityId = (Id) sobj.get('Id');
            cdls.add( createContentDocumentLink(linkedEntityId, cvRefreshed.ContentDocumentId) );
        }
        return cdls;
    }

    @NamespaceAccessible
    public static ContentDocumentLink createContentDocumentLink(Id linkedEntityId, Id contentDocumentId) {
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = linkedEntityId;
        cdl.ContentDocumentId = contentDocumentId;
        cdl.ShareType = 'I';
        cdl.Visibility = 'AllUsers';
        return cdl;
    }

    /**
     * Contract and Form
     */
    @NamespaceAccessible
    public static TREX1__Contract_and_Form__c createContractScenario() {
        Account acc = createAccounts(1).get(0);
        insert acc;

        Contact ct = createContacts(1).get(0);
        ct.AccountId = acc.Id;
        insert ct;

        return createContract(acc.Id, ct.Id);
    }

    @NamespaceAccessible
    public static TREX1__Contract_and_Form__c createContract(Id accountId, Id contactId) {
        TREX1__Contract_and_Form__c contract = new TREX1__Contract_and_Form__c(
            Name = 'Test Contract',
            TREX1__Account__c = accountId,
            TREX1__Contact__c = contactId,
            TREX1__Contract_Expiry_Policy__c = 'Always Required',
            TREX1__Valid_For__c = 'Account',
            TREX1__Type__c = 'Waiver Form',
            TREX1__Status__c = 'Draft',
            TREX1__Waiver_Text__c = 'Hello {!TREX1__Contact__r.FirstName}, your account is {!TREX1__Account__r.Name}.' +
                                    '\nAdd-Ons:\n{!tableStart:addOns}- {!Name} (Status: {!TREX1__Status__c}){!tableEnd}'
        );
        return contract;
    }

    /**
     * Registration (TREX1)
     */
    @NamespaceAccessible
    public static TREX1__Registration__c createRegistrationWithAddOns(Id accountId, Id contactId) {
        TREX1__Registration__c reg = new TREX1__Registration__c();
        reg.TREX1__Account__c = accountId;
        reg.TREX1__Contact__c = contactId;
        insert reg;

        List<TREX1__Add_On__c> addOns = new List<TREX1__Add_On__c>{
            new TREX1__Add_On__c(Name = 'Locker Rental', TREX1__Status__c = 'Draft', TREX1__Registration__c = reg.Id),
            new TREX1__Add_On__c(Name = 'Swim Goggles', TREX1__Status__c = 'Draft', TREX1__Registration__c = reg.Id)
        };
        insert addOns;

        return reg;
    }

    /**
     * Transaction (TREX1)
     */
    @NamespaceAccessible
    public static TREX1__Transaction__c createTransaction(Id contactId) {
        Id recordTypeId = Schema.SObjectType.TREX1__Transaction__c.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
        TREX1__Transaction__c trx = new TREX1__Transaction__c();
        trx.RecordTypeId = recordTypeId;
        trx.TREX1__Status__c = 'Draft';
        trx.TREX1__Contact__c = contactId;
        return trx;
    }

}