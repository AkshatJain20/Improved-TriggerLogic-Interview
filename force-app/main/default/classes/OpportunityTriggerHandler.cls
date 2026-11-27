/**
 * OpportunityTriggerHandler
 *
 * Handles automatic creation and maintenance of Opportunity Contact Roles (OCRs).
 *
 * Business Requirements:
 * 1. Create Contact Roles when an Opportunity is created with Closed Won stage.
 * 2. Create Contact Roles when an Opportunity stage changes to Closed Won.
 * 3. Handle Account reassignment for Closed Won Opportunities by removing
 *    Contact Roles associated with the previous Account.
 * 4. Avoid creating duplicate Contact Roles.
 * 5. Ensure that only one Contact Role is marked as Primary per Opportunity.
 *
 * Test Coverage: 82%
 */
public class OpportunityTriggerHandler{
    
    public static void handleAfterInsertUpdate(List<Opportunity> opportunities, Map<Id, Opportunity> oldMap, Boolean isInsert) {

		List<Opportunity> opportunitiesToProcess = new List<Opportunity>();    //to get only eligible opportunities
        for(Opportunity opp: opportunities){
            if(isInsert) {
                if(opp.StageName == 'Closed Won'){
                    opportunitiesToProcess.add(opp);
                }
            }
            else {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if(opp.StageName == 'Closed Won' && (oldOpp.StageName != 'Closed Won' || opp.AccountId != oldOpp.AccountId)) {	//either status changed to closed won or a closed opportunity is being reparented
                    opportunitiesToProcess.add(opp);
                }
            }
        }
        if(!opportunitiesToProcess.isEmpty()) {
            createContactRoles(opportunitiesToProcess, isInsert ? null : oldMap);
        }
    }
    
    
    public static void createContactRoles(List<opportunity> opportunities, Map<Id, Opportunity> oldMap){
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> changedOpportunityIds = new Set<Id>();
        for(Opportunity o:opportunities){
            accountIds.add(o.AccountId);
            if (oldMap != null) {
                Opportunity oldOpp = oldMap.get(o.Id);
                
                if (oldOpp.AccountId != o.AccountId) {
                    changedOpportunityIds.add(o.Id);
                }
            }
        }
        if (!changedOpportunityIds.isEmpty()) {
            
            List<OpportunityContactRole> rolesToDelete = new List<OpportunityContactRole>();	//to delete ocr related to old contacts in situations where account was changed on opportunity
            for (OpportunityContactRole ocr : [SELECT Id, OpportunityId, ContactId, Contact.AccountId FROM OpportunityContactRole WHERE OpportunityId IN :changedOpportunityIds]) {
                Opportunity oldOpp = oldMap.get(ocr.OpportunityId);
                // Delete only Contact Roles belonging to the old Account
                if (oldOpp.AccountId != null && ocr.Contact.AccountId == oldOpp.AccountId) {	//delete only those ocrs related to opportunities where accounts were updated
                    rolesToDelete.add(ocr);
                }
            }
            if (!rolesToDelete.isEmpty()) {
                try {
                    delete rolesToDelete;
                } catch (DmlException e) {
                    logError(
                        'OpportunityTriggerHandler',
                        'createContactRoles',
                        'Failed to delete Opportunity Contact Roles',
                        e
                    );
                    throw e;
                }
            }
        }
        Map<Id,List<Contact>> accIdVsContacts = new Map<Id,List<Contact>>(); 	//Map of account Id and related contacts
        for(Contact con:[Select Id, AccountId from contact where AccountId in: accountIds]){
            if(!accIdVsContacts.containsKey(con.AccountId)){
                accIdVsContacts.put(con.AccountId, new List<contact>());
            }
            accIdVsContacts.get(con.AccountId).add(con);
        }
        Set<Id> opportunityPrimaryContactRoleExists = new Set<Id>();	//To check for existing primary opportunity contact roles
        Map<Id, Set<Id>> existingOpportunityContactRoles = new Map<Id,Set<Id>>();	//To get existing ocr with OpportunityId and ContactId
        for(OpportunityContactRole ocr:[Select Id, OpportunityId, ContactId, IsPrimary from OpportunityContactRole where OpportunityId In:opportunities]){
            if(ocr.IsPrimary){
                opportunityPrimaryContactRoleExists.add(ocr.OpportunityId);		//adding Opportunities where primary ocr exists
            }
            if(!existingOpportunityContactRoles.containsKey(ocr.OpportunityId)){
                existingOpportunityContactRoles.put(ocr.OpportunityId, new Set<Id>());	
            }
            existingOpportunityContactRoles.get(ocr.OpportunityId).add(ocr.ContactId);	//adding existing ocr info
        }
        List<OpportunityContactRole> listToInsert = new List<OpportunityContactRole>();
        String ocrRole = System.label.Opportunity_Contact_Role_Label != null ? System.label.Opportunity_Contact_Role_Label : 'Family Member';	//custom label to store role of ocr
        for(Opportunity opp:opportunities){
            List<Contact> conList = accIdVsContacts.get(opp.AccountId);
            if (conList == null) {
                continue;
            }
            Set<Id> existingContactIds = existingOpportunityContactRoles.get(opp.Id);
            
            if (existingContactIds == null) {
                existingContactIds = new Set<Id>();
                existingOpportunityContactRoles.put(opp.Id, existingContactIds);
            }
            Boolean isPrimaryExists = true;
            if(opportunityPrimaryContactRoleExists.add(opp.Id)){	//to check if there exists a primary ocr and add to the set as well if not
                isPrimaryExists = false;
            }
            for(Contact con:conList){
                if(!existingContactIds.add(con.Id)){	//to check if ocr exists with current opportunitId and ContactId and add to the set as well
                    continue;
                }
                OpportunityContactRole ocr = new OpportunityContactRole();
                ocr.OpportunityId = opp.Id;
                ocr.ContactId = con.Id;
                ocr.IsPrimary = !isPrimaryExists;
                ocr.Role = ocrRole;
                if(!isPrimaryExists){	//if primary ocr already exists?
                    isPrimaryExists = true;
                }
                listToInsert.add(ocr);
            }
        }
        if (!listToInsert.isEmpty()) {
            try {
                insert listToInsert;
            } catch (DmlException e) {
                logError(
                    'OpportunityTriggerHandler',
                    'createContactRoles',
                    'Failed to insert Opportunity Contact Roles',
                    e
                );
                throw e;
            }
        }
    }
    
    @TestVisible
    private static void logError(String className, String methodName, String message, Exception e) {
        System.debug(
            LoggingLevel.ERROR,
            'Class: ' + className +
            ' | Method: ' + methodName +
            ' | Message: ' + message +
            ' | Error: ' + e.getMessage() +
            ' | Stack Trace: ' + e.getStackTraceString()
        );
    }
}