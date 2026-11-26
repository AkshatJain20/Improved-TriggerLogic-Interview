Improved Salesforce Trigger Logic – Interview Project
Project Overview

This project demonstrates optimized Salesforce Apex trigger implementations using best practices for bulkification, code reusability, maintainability, and governor limit management.

The objective is to implement real-world Salesforce business requirements using Apex Triggers, Handler Classes, and Test Classes.

Technologies Used
Salesforce CRM
Apex Programming
Apex Triggers
SOQL and DML
Salesforce DX (SFDX)
Visual Studio Code
Salesforce CLI
Project Structure

All Salesforce metadata is maintained inside the force-app/main/default directory.

text
force-app/
└── main/
    └── default/
        ├── classes/
        │   ├── OpportunityTriggerHandler.cls
        │   ├── ContactTriggerHandler.cls
        │   └── Test Classes
        └── triggers/
            ├── OpportunityTrigger.trigger
            └── ContactTrigger.trigger

Implemented Business Logic
1. Automatic Opportunity Contact Role Creation

Automatically creates Opportunity Contact Roles for Contacts associated with an Opportunity's Account.

Functionality:

Creates Contact Roles when a new Opportunity is created.
Associates existing Account Contacts with the Opportunity.
Prevents duplicate Opportunity Contact Roles.
Assigns the first available Contact Role as Primary when no primary Contact Role exists.
2. Opportunity Account Change Handling

Handles changes to the Account associated with an Opportunity.

Functionality:

Identifies Opportunities whose Account has changed.
Deletes Contact Roles associated with Contacts belonging to the previous Account.
Creates Contact Roles for Contacts belonging to the new Account.
Preserves unrelated Contact Roles.
3. Contact Trigger Automation

Automatically maintains Opportunity Contact Roles when Contacts are created or updated.

Functionality:

Creates Opportunity Contact Roles when a new Contact is associated with an Account that has existing Opportunities.
Detects Contact Account changes.
Deletes Contact Roles associated with the previous Account's Opportunities.
Creates Contact Roles for Opportunities belonging to the new Account.
Handles Account removal from a Contact.
Prevents duplicate Contact Role creation.
4. Primary Opportunity Contact Role Management
Tracks existing primary Contact Roles using Opportunity IDs.
Assigns Primary status when an Opportunity does not already have a primary Contact Role.
Ensures newly generated Contact Roles do not introduce multiple primary Contact Roles for an Opportunity.
Apex Best Practices

This project focuses on the following Salesforce development best practices:

Bulkified Apex Triggers.
Separation of Trigger and Handler logic.
Collection-based processing using Lists, Sets, and Maps.
Avoiding SOQL and DML statements inside loops.
Duplicate record prevention.
Efficient SOQL queries.
Null handling.
Governor limit optimization.
Reusable and maintainable Apex code.
Test Coverage

Test classes are designed to validate:

Opportunity Contact Role creation.
Contact insertion.
Contact Account changes.
Opportunity Account changes.
Duplicate prevention.
Primary Contact Role assignment.
Bulk record processing.
Account removal scenarios.
Deployment

The project can be deployed using Salesforce CLI.

Clone the repository:
bash
git clone https://github.com/AkshatJain20/Improved-TriggerLogic-Interview.git

Open the project in Visual Studio Code.
Authenticate with your Salesforce org:
bash
sf org login web

Deploy the source:
bash
sf project deploy start --source-dir force-app

Run Apex tests:
bash
sf apex run test --test-level RunLocalTests --wait 30

Project Objective

The main objective is to demonstrate practical Salesforce Apex development skills through real-world trigger scenarios, with an emphasis on optimized code, scalability, and maintainability.

Author

Akshat Jain

Salesforce Developer
