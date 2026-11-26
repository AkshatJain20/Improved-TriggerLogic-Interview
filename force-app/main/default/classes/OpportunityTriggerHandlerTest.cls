@isTest
public class OpportunityTriggerHandlerTest {

    @testSetup
    static void setupData() {

        // Create Accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Account A'),
            new Account(Name = 'Account B'),
            new Account(Name = 'Account C')
        };
        insert accounts;

        // Create Contacts before Opportunities
        // This ensures Contact Trigger does not create OCRs yet
        List<Contact> contacts = new List<Contact>();

        for(Integer i = 1; i <= 2; i++) {
            contacts.add(new Contact(
                LastName = 'AccountA Contact ' + i,
                AccountId = accounts[0].Id
            ));

            contacts.add(new Contact(
                LastName = 'AccountB Contact ' + i,
                AccountId = accounts[1].Id
            ));

            contacts.add(new Contact(
                LastName = 'AccountC Contact ' + i,
                AccountId = accounts[2].Id
            ));
        }

        insert contacts;
    }

    // Helper method to create Opportunity
    private static Opportunity createOpportunity(
        Id accountId,
        String stageName
    ) {

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = stageName,
            CloseDate = Date.today().addDays(30)
        );

        insert opp;

        return opp;
    }

    // Test 1: Create Opportunity directly as Closed Won
    @isTest
    static void testClosedWonOpportunityInsert() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Test.startTest();

        Opportunity opp = createOpportunity(
            acc.Id,
            'Closed Won'
        );

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId, IsPrimary, Role
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roles.size(),
            'OCRs should be created for all Account Contacts.'
        );

        Integer primaryCount = 0;

        for(OpportunityContactRole ocr : roles) {
            if(ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'Exactly one OCR should be primary.'
        );
    }
    
    @isTest
    static void testPrimaryOcrsCheck() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Test.startTest();

        Opportunity opp = createOpportunity(
            acc.Id,
            'Prospecting'
        );
		Contact con = [Select id from Contact where AccountId = :acc.Id Limit 1];
        OpportunityContactRole orc = new OpportunityContactRole();
        orc.OpportunityId = opp.Id;
        orc.ContactId = con.Id;
        orc.IsPrimary = true;
        insert orc;
        Test.stopTest();
		opp.StageName = 'Closed Won';
        update opp;
        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId, IsPrimary, Role
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roles.size(),
            'OCRs should be created for all Account Contacts.'
        );

        Integer primaryCount = 0;

        for(OpportunityContactRole ocr : roles) {
            if(ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'Exactly one OCR should be primary.'
        );
    }

    // Test 2: Opportunity created as Prospecting
    @isTest
    static void testNonClosedWonOpportunityInsert() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Test.startTest();

        Opportunity opp = createOpportunity(
            acc.Id,
            'Prospecting'
        );

        Test.stopTest();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            0,
            roleCount,
            'OCRs should not be created for non-Closed Won Opportunities.'
        );
    }

    // Test 3: Change Opportunity stage from Prospecting to Closed Won
    @isTest
    static void testOpportunityStageChangeToClosedWon() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(
            acc.Id,
            'Prospecting'
        );

        Test.startTest();

        opp.StageName = 'Closed Won';
        update opp;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roles.size(),
            'OCRs should be created when Opportunity becomes Closed Won.'
        );

        Integer primaryCount = 0;

        for(OpportunityContactRole ocr : roles) {
            if(ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'Exactly one OCR should be primary.'
        );
    }

    // Test 4: Change Account on Closed Won Opportunity
    @isTest
    static void testOpportunityAccountChange() {

        Account accA = [
            SELECT Id FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Account accB = [
            SELECT Id FROM Account
            WHERE Name = 'Account B'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(
            accA.Id,
            'Closed Won'
        );

        Test.startTest();

        opp.AccountId = accB.Id;
        update opp;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId,
                   Contact.AccountId, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roles.size(),
            'Old Account OCRs should be deleted and new Account OCRs created.'
        );

        Integer primaryCount = 0;

        for(OpportunityContactRole ocr : roles) {

            System.assertEquals(
                accB.Id,
                ocr.Contact.AccountId,
                'Only Contacts belonging to the new Account should remain.'
            );

            if(ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'New Account should have exactly one primary OCR.'
        );
    }

    // Test 5: Update unrelated Opportunity field
    @isTest
    static void testUnrelatedOpportunityUpdate() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(
            acc.Id,
            'Closed Won'
        );

        Integer countBefore = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        Test.startTest();

        opp.Amount = 50000;
        update opp;

        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            countBefore,
            countAfter,
            'Updating Amount should not create additional OCRs.'
        );
    }

    // Test 6: Change Opportunity from Closed Won to Closed Lost
    @isTest
    static void testClosedWonToClosedLost() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(
            acc.Id,
            'Closed Won'
        );

        Integer countBefore = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        Test.startTest();

        opp.StageName = 'Closed Lost';
        update opp;

        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            countBefore,
            countAfter,
            'Existing OCRs should remain when Opportunity moves to Closed Lost.'
        );
    }

    // Test 7: Bulk Opportunity insertion
    @isTest
    static void testBulkOpportunityInsert() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Account A'
            LIMIT 1
        ];

        List<Opportunity> opportunities = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++) {

            opportunities.add(new Opportunity(
                Name = 'Bulk Opportunity ' + i,
                AccountId = acc.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(30)
            ));
        }

        Test.startTest();

        insert opportunities;

        Test.stopTest();

        Set<Id> opportunityIds =
            new Map<Id, Opportunity>(opportunities).keySet();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds
        ];

        System.assertEquals(
            20,
            roleCount,
            '10 Opportunities with 2 Contacts each should create 20 OCRs.'
        );
    }
}