
@isTest
private class OpportunityTriggerHandlerTest {

    // Create reusable test data
    @testSetup
    static void setupData() {

        List<Account> accounts = new List<Account>{
            new Account(Name = 'Old Account'),
            new Account(Name = 'New Account')
        };
        insert accounts;

        List<Contact> contacts = new List<Contact>();

        // Two Contacts for Old Account
        contacts.add(new Contact(
            LastName = 'Old Contact 1',
            AccountId = accounts[0].Id
        ));

        contacts.add(new Contact(
            LastName = 'Old Contact 2',
            AccountId = accounts[0].Id
        ));

        // Two Contacts for New Account
        contacts.add(new Contact(
            LastName = 'New Contact 1',
            AccountId = accounts[1].Id
        ));

        contacts.add(new Contact(
            LastName = 'New Contact 2',
            AccountId = accounts[1].Id
        ));

        insert contacts;
    }

    // Helper method to create Opportunities
    private static Opportunity createOpportunity(Id accountId) {

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        return opp;
    }

    // Test 1: Create Contact Roles when Opportunity is inserted
    @isTest
    static void testContactRoleCreation() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Old Account'
            LIMIT 1
        ];

        Test.startTest();

        Opportunity opp = createOpportunity(acc.Id);
        insert opp;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, ContactId, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roles.size(),
            'Two Contact Roles should be created.'
        );

        Integer primaryCount = 0;

        for (OpportunityContactRole ocr : roles) {
            if (ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'Exactly one Contact Role should be Primary.'
        );
    }

    // Test 2: No duplicate Contact Roles on Opportunity update
    @isTest
    static void testDuplicatePrevention() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Old Account'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(acc.Id);
        insert opp;

        Test.startTest();

        opp.Name = 'Updated Opportunity';
        update opp;

        Test.stopTest();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roleCount,
            'Existing Contact Roles should not be duplicated.'
        );
    }

    // Test 3: Remove old Contact Roles and create new ones
    // when Opportunity Account changes
    @isTest
    static void testAccountChange() {

        Account oldAccount = [
            SELECT Id FROM Account
            WHERE Name = 'Old Account'
            LIMIT 1
        ];

        Account newAccount = [
            SELECT Id FROM Account
            WHERE Name = 'New Account'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(oldAccount.Id);
        insert opp;

        Test.startTest();

        opp.AccountId = newAccount.Id;
        update opp;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, ContactId, IsPrimary,
                   Contact.AccountId
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            2,
            roles.size(),
            'Only two new Account Contact Roles should exist.'
        );

        Integer primaryCount = 0;

        for (OpportunityContactRole ocr : roles) {

            System.assertEquals(
                newAccount.Id,
                ocr.Contact.AccountId,
                'Contact Role should belong to the new Account.'
            );

            if (ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'One new Contact Role should be Primary.'
        );
    }

    // Test 4: Remove Contact Roles when Account becomes null
    @isTest
    static void testAccountRemoval() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Old Account'
            LIMIT 1
        ];

        Opportunity opp = createOpportunity(acc.Id);
        insert opp;

        Test.startTest();

        opp.AccountId = null;
        update opp;

        Test.stopTest();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            0,
            roleCount,
            'Old Account Contact Roles should be removed.'
        );
    }

    // Test 5: Bulk Opportunity creation
    @isTest
    static void testBulkOpportunityCreation() {

        Account acc = [
            SELECT Id FROM Account
            WHERE Name = 'Old Account'
            LIMIT 1
        ];

        List<Opportunity> opportunities =
            new List<Opportunity>();

        for (Integer i = 0; i < 5; i++) {
            opportunities.add(
                new Opportunity(
                    Name = 'Bulk Opportunity ' + i,
                    AccountId = acc.Id,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30)
                )
            );
        }

        Test.startTest();

        insert opportunities;

        Test.stopTest();

        Set<Id> opportunityIds = new Map<Id, Opportunity>(
            opportunities
        ).keySet();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds
        ];

        System.assertEquals(
            10,
            roleCount,
            'Five Opportunities should create ten Contact Roles.'
        );
    }

    // Test 6: Opportunity without an Account
    @isTest
    static void testOpportunityWithoutAccount() {

        Opportunity opp = createOpportunity(null);

        Test.startTest();

        insert opp;

        Test.stopTest();

        Integer roleCount = [
            SELECT COUNT()
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];

        System.assertEquals(
            0,
            roleCount,
            'No Contact Roles should be created without an Account.'
        );
    }
}
