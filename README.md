Improved Salesforce Opportunity Trigger Logic
1. Project Overview

This project demonstrates an improved Salesforce Apex Trigger implementation for automatically managing Opportunity Contact Roles (OCRs).

The solution automatically creates Opportunity Contact Roles for Contacts associated with an Opportunity's Account.

It also handles Account changes by removing Contact Roles associated with the previous Account and creating new Contact Roles for Contacts belonging to the updated Account.

The implementation focuses on bulkification, duplicate prevention, Primary Contact Role assignment, and efficient use of Salesforce Governor Limits.

2. Business Requirement

The objective is to automate Opportunity Contact Role management through Apex Triggers.

Whenever an Opportunity is inserted or updated:

Retrieve all Contacts associated with the Opportunity's Account.
Create Opportunity Contact Roles for the related Contacts.
Prevent duplicate Contact Roles for the same Opportunity and Contact combination.
Check whether an existing Primary Contact Role is already assigned.
If no Primary Contact Role exists, assign the first newly created Contact Role as Primary.
If the Opportunity's Account changes:
Identify the previous Account using Trigger.oldMap.
Remove existing Contact Roles associated with the previous Account.
Create Contact Roles for Contacts associated with the new Account.
Perform database operations in bulk.
3. Salesforce Components
Apex Trigger: AddContactRoles

The trigger executes on:

After Insert
After Update

It delegates the business logic to the OpportunityTriggerHandler class.

This keeps the trigger lightweight and separates trigger execution from business logic.

Apex Handler: OpportunityTriggerHandler

The handler contains the core business logic for managing Opportunity Contact Roles.

It performs the following operations:

1. Account ID Collection

Collects Account IDs from incoming Opportunities.
Uses a Set to eliminate duplicate Account IDs.
Identifies Opportunities whose Account IDs have changed.

2. Account Change Detection

Uses Trigger.oldMap to compare previous and current Account IDs.
Identifies Opportunities requiring Contact Role cleanup.

3. Existing Contact Role Cleanup

Retrieves existing Opportunity Contact Roles for Opportunities whose Accounts have changed.
Checks the Account associated with each Contact.
Deletes Contact Roles associated with the previous Account.

4. Related Contact Retrieval

Retrieves Contacts associated with the current Opportunity Accounts.
Stores Contacts in a Map using Account ID as the key.

5. Duplicate Prevention

Retrieves existing Opportunity Contact Roles.
Uses a Map of Opportunity IDs and Sets of Contact IDs.
Prevents duplicate Contact Role creation.

6. Primary Contact Role Assignment

Checks whether an Opportunity already has a Primary Contact Role.
If one exists, newly created Contact Roles remain non-primary.
If none exists, the first newly created Contact Role is assigned as Primary.

7. Bulk DML Operations

Collects new Contact Roles in a List.
Performs a single bulk insert operation.
4. Key Features and Optimizations
Feature	Implementation
Trigger Handler Pattern	Separates trigger execution and business logic
Bulkification	Processes multiple Opportunities in one transaction
SOQL Optimization	Uses collection-based queries outside loops
DML Optimization	Uses bulk delete and insert operations
Duplicate Prevention	Uses Sets and Maps
Primary Contact Management	Assigns Primary status when required
Account Change Handling	Removes old Account-related Contact Roles
Reusability	Keeps business logic inside a separate Apex class
Governor Limit Awareness	Minimizes SOQL and DML statements
5. Data Structures Used

The implementation uses Apex collections for efficient processing.

Collection	Purpose
Set<Id> accountIds	Stores unique Account IDs
Set<Id> changedOpportunityIds	Tracks Opportunities with Account changes
Map<Id, List<Contact>> accIdVsContacts	Maps Account IDs to related Contacts
Set<Id> opportunityPrimaryContactRoleExists	Tracks Opportunities with an existing Primary Contact Role
Map<Id, Set<Id>> existingOpportunityContactRoles	Tracks existing Contact IDs for each Opportunity
List<OpportunityContactRole> listToInsert	Stores new Contact Roles for bulk insertion
List<OpportunityContactRole> rolesToDelete	Stores old Contact Roles for bulk deletion
6. Execution Flow
text
Opportunity Insert / Update
          |
          v
AddContactRoles Trigger
          |
          v
OpportunityTriggerHandler
          |
          v
Collect Account IDs
          |
          v
Detect Account Changes
          |
          v
Delete Previous Account Contact Roles
          |
          v
Retrieve Contacts for Current Accounts
          |
          v
Retrieve Existing Contact Roles
          |
          v
Prevent Duplicate Contact Roles
          |
          v
Check Primary Contact Role
          |
          v
Prepare New Contact Roles
          |
          v
Bulk Insert Contact Roles

7. Testing Scenarios

The following scenarios should be validated through Apex test classes:

Opportunity insertion with multiple related Contacts.
Opportunity insertion with an Account having no Contacts.
Opportunity update without duplicate Contact Role creation.
Opportunity Account change from one Account to another.
Removal of Contact Roles associated with the previous Account.
Creation of Contact Roles associated with the new Account.
Preservation of an existing Primary Contact Role when the Account does not change.
Assignment of a new Primary Contact Role after an Account change.
Opportunity Account changed to null.
Bulk processing of multiple Opportunities.
Multiple Opportunities associated with the same Account.
8. Technology Stack
Salesforce Platform
Apex Programming Language
Apex Triggers
Trigger Handler Pattern
SOQL and DML
Salesforce DX (SFDX)
Visual Studio Code
9. Deployment Instructions
Prerequisites
Salesforce CLI installed.
Visual Studio Code with Salesforce Extensions.
Salesforce Developer Org or Sandbox.
Appropriate deployment permissions.
Deployment Command
bash
sf project deploy start --source-dir force-app


After deployment, execute the relevant Apex test classes to validate the implementation.

10. Conclusion

This project demonstrates an improved approach to Salesforce Opportunity Contact Role automation.

The implementation addresses bulk processing, duplicate prevention, Primary Contact Role assignment, and Account change handling through a structured Trigger Handler architecture.

It demonstrates practical Apex development skills, effective use of Salesforce collections, and awareness of Salesforce Governor Limits.

Project: Improved Salesforce Opportunity Trigger Logic

Platform: Salesforce

Language: Apex

Architecture: Trigger Handler Pattern

Development Environment: Salesforce DX / Visual Studio Code