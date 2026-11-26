
@isTest
public class OpportunityTriggerHandlerTest {

    // Test data creation
    @testSetup
    static void setupTestData() {

        // Create Accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1'),
            new Account(Name = 'Test Account 2'),
            new Account(Name = 'Test Account 3')
        };

        insert accounts;

        // Create Contacts
        List<Contact> contacts = new List<Contact>{
            new Contact(
                FirstName = 'John',
                LastName = 'One',
                AccountId = accounts[0].Id
            ),
            new Contact(
                FirstName = 'Jane',
                LastName = 'Two',
                AccountId = accounts[0].Id
            ),
            new Contact(
                FirstName = 'Mike',
                LastName = 'Three',
                AccountId = accounts[1].Id
            ),
            new Contact(
                FirstName = 'Sarah',
                LastName = 'Four',
                AccountId = accounts[1].Id
            )
        };

        insert contacts;
    }

    // Test 1: Contact Roles should be created after Opportunity insert
    @isTest
    static void testContactRoleCreation() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        Test.startTest();

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

        insert opp;

        Test.stopTest();

        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId, Role, IsPrimary
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

            System.assertEquals(
                'Family Member',
                ocr.Role,
                'Role should be Family Member.'
            );

            if (ocr.IsPrimary) {
                primaryCount++;
            }
        }

        System.assertEquals(
            1,
            primaryCount,
            'Exactly one Contact Role should be primary.'
        );
    }

    // Test 2: No duplicate Contact Roles on Opportunity update
    @isTest
    static void testDuplicatePrevention() {

        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        Opportunity opp = new Opportunity(
            Name = 'Duplicate Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

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
            'Duplicate Contact Roles should not be created.'
        );
    }

    // Test 3: Bulk Opportunity insert
    @isTest
    static void testBulkOpportunityInsert() {

        Account acc1 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        Account acc2 = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 2'
            LIMIT 1
        ];

        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i = 0; i < 100; i++) {

            opportunities.add(
                new Opportunity(
                    Name = 'Bulk Opportunity ' + i,
                    AccountId = (i < 50) ? acc1.Id : acc2.Id,
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

        List<OpportunityContactRole> roles = [
            SELECT Id, OpportunityId, ContactId, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunityIds
        ];

        System.assertEquals(
            200,
            roles.size(),
            'Each Opportunity should have two Contact Roles.'
        );

        Map<Id, Integer> primaryCountByOpportunity =
            new Map<Id, Integer>();

        for (OpportunityContactRole ocr : roles) {

            if (ocr.IsPrimary) {

                Integer count = primaryCountByOpportunity.containsKey(
                    ocr.OpportunityId
                ) ? primaryCountByOpportunity.get(ocr.OpportunityId) : 0;

                primaryCountByOpportunity.put(
                    ocr.OpportunityId,
                    count + 1
                );
            }
        }

        System.assertEquals(
            100,
            primaryCountByOpportunity.size(),
            'Every Opportunity should have a primary Contact.'
        );

        for (Integer count : primaryCountByOpportunity.values()) {
            System.assertEquals(
                1,
                count,
                'Each Opportunity should have exactly one primary Contact.'
            );
        }
    }

    // Test 4: Opportunity without Account
    @isTest
    static void testOpportunityWithoutAccount() {

        Opportunity opp = new Opportunity(
            Name = 'No Account Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

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

    // Test 5: Opportunity with Account but no Contacts
    @isTest
    static void testAccountWithoutContacts() {

        Account acc = new Account(
            Name = 'Account Without Contacts'
        );

        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'No Contacts Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );

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
            'No Contact Roles should be created when Account has no Contacts.'
        );
    }
}
