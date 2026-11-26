@isTest
public class ContactTriggerHandlerTest {

    @testSetup
    static void setupData() {

        // Create Accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Account A'),
            new Account(Name = 'Account B')
        };
        insert accounts;

        // Create Opportunities
        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(
                Name = 'Opportunity A1',
                AccountId = accounts[0].Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ),
            new Opportunity(
                Name = 'Opportunity A2',
                AccountId = accounts[0].Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ),
            new Opportunity(
                Name = 'Opportunity B1',
                AccountId = accounts[1].Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            )
        };
        insert opportunities;
    }

    // Test Contact insertion
    @isTest
    static void testContactInsert() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Test.startTest();

        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId, IsPrimary, Role
            FROM OpportunityContactRole
            WHERE ContactId = :con.Id
        ];

        System.assertEquals(2, roles.size(),
            'Two OCRs should be created for Account A opportunities.');

        Integer primaryCount = 0;

        for(OpportunityContactRole ocr : roles) {
            if(ocr.IsPrimary) {
                primaryCount++;
            }

            System.assertEquals('Family Member', ocr.Role);
        }

        System.assertEquals(2, primaryCount, 'Each Opportunity should have exactly one primary OCR.');
    }

    // Test Contact Account change
    @isTest
    static void testContactAccountChange() {

        Account accA = [
            SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1
        ];

        Account accB = [
            SELECT Id FROM Account WHERE Name = 'Account B' LIMIT 1
        ];

        Contact con = new Contact(
            LastName = 'Moving Contact',
            AccountId = accA.Id
        );
        insert con;

        Test.startTest();

        con.AccountId = accB.Id;
        update con;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, Opportunity.AccountId, ContactId
            FROM OpportunityContactRole
            WHERE ContactId = :con.Id
        ];

        System.assertEquals(1, roles.size(),
            'Only one OCR should exist after moving to Account B.');

        System.assertEquals(accB.Id, roles[0].Opportunity.AccountId,
            'OCR should belong to Account B opportunity.');
    }

    // Test duplicate prevention
    @isTest
    static void testDuplicatePrevention() {

        Account acc = [
            SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1
        ];

        Contact con = new Contact(
            LastName = 'Duplicate Test',
            AccountId = acc.Id
        );
        insert con;

        Integer countBefore = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE ContactId = :con.Id
        ];

        Test.startTest();

        // Update a field without changing AccountId
        con.Title = 'Updated Title';
        update con;

        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE ContactId = :con.Id
        ];

        System.assertEquals(countBefore, countAfter,
            'Updating Contact without changing Account should not create duplicates.');
    }

    // Test bulk Contact insertion
    @isTest
    static void testBulkContactInsert() {

        Account acc = [
            SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1
        ];

        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i < 20; i++) {
            contacts.add(new Contact(
                LastName = 'Bulk Contact ' + i,
                AccountId = acc.Id
            ));
        }

        Test.startTest();

        insert contacts;

        Test.stopTest();

        Set<Id> contactIds = new Map<Id, Contact>(contacts).keySet();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE ContactId IN :contactIds
        ];

        System.assertEquals(40, roleCount,
            '20 Contacts should generate 40 OCRs for two Opportunities.');
    }

    // Test Contact Account removal
    @isTest
    static void testContactAccountRemoval() {

        Account acc = [
            SELECT Id FROM Account WHERE Name = 'Account A' LIMIT 1
        ];

        Contact con = new Contact(
            LastName = 'Account Removal',
            AccountId = acc.Id
        );
        insert con;

        Test.startTest();

        con.AccountId = null;
        update con;

        Test.stopTest();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE ContactId = :con.Id
        ];

        System.assertEquals(0, roleCount,
            'OCRs associated with the old Account should be deleted.');
    }
}