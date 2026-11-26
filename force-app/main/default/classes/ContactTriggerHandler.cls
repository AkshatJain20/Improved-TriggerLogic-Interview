public class ContactTriggerHandler {
    
    public static void createOpportunityContactRoles(List<Contact> contacts, Map<Id, Contact> oldMap) {
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> changedContactIds = new Set<Id>();
        // Collect Account IDs and Contact IDs
        for(Contact con : contacts) {
            accountIds.add(con.AccountId);
            if(oldMap != null) {
                Contact oldCon = oldMap.get(con.Id);
                if(oldCon.AccountId != con.AccountId) {
                    changedContactIds.add(con.Id);
                }
            }
        }
        // Delete OCRs associated with the old Account
        if(!changedContactIds.isEmpty()) {
            List<OpportunityContactRole> rolesToDelete = new List<OpportunityContactRole>();
            for(OpportunityContactRole ocr : [SELECT Id, OpportunityId, ContactId, Opportunity.AccountId FROM OpportunityContactRole WHERE ContactId IN :changedContactIds]) {
                Contact oldCon = oldMap.get(ocr.ContactId);
                if(oldCon.AccountId != null && ocr.Opportunity.AccountId == oldCon.AccountId) {
                    rolesToDelete.add(ocr);
                }
            }
            
            if(!rolesToDelete.isEmpty()) {
                delete rolesToDelete;
            }
        }
        // Get Opportunities related to current Accounts
        Map<Id, List<Opportunity>> accIdVsOpps = new Map<Id, List<Opportunity>>();
        Set<Id> opportunityIds = new Set<Id>();
        for(Opportunity opp : [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :accountIds]) {
            if(!accIdVsOpps.containsKey(opp.AccountId)) {
                accIdVsOpps.put(opp.AccountId, new List<Opportunity>());
            }
            accIdVsOpps.get(opp.AccountId).add(opp);
            opportunityIds.add(opp.Id);
        }
        if(opportunityIds.isEmpty()) {
            return;
        }
        // Track existing OCRs and primary OCRs
        Set<Id> opportunityPrimaryContactRoleExists = new Set<Id>();
        Map<Id, Set<Id>> existingOpportunityContactRoles = new Map<Id, Set<Id>>();
        for(OpportunityContactRole ocr : [SELECT Id, OpportunityId, ContactId, IsPrimary FROM OpportunityContactRole WHERE OpportunityId IN :opportunityIds AND ContactId IN :contacts]) {
            
            // Primary OCR is tracked by Opportunity ID
            if(ocr.IsPrimary) {
                opportunityPrimaryContactRoleExists.add(ocr.OpportunityId);
            }
            if(!existingOpportunityContactRoles.containsKey(ocr.ContactId)) {
                existingOpportunityContactRoles.put(ocr.ContactId, new Set<Id>());
            }
            existingOpportunityContactRoles.get(ocr.ContactId).add(ocr.OpportunityId);
        }
        
        // Prepare OCR records for insertion
        List<OpportunityContactRole> listToInsert = new List<OpportunityContactRole>();
        String ocrRole = System.label.Opportunity_Contact_Role_Label != null ? System.label.Opportunity_Contact_Role_Label : 'Family Member';
        for(Contact con : contacts) {
            List<Opportunity> oppList = accIdVsOpps.get(con.AccountId);
            if(oppList == null) {
                continue;
            }
            Set<Id> existingOppIds = existingOpportunityContactRoles.get(con.Id);
            if(existingOppIds == null) {
                existingOppIds = new Set<Id>();
                existingOpportunityContactRoles.put(con.Id, existingOppIds);
            }
            for(Opportunity opp : oppList) {
                // Skip if OCR already exists
                if(!existingOppIds.add(opp.Id)) {
                    continue;
                }
                OpportunityContactRole ocr = new OpportunityContactRole();
                ocr.OpportunityId = opp.Id;
                ocr.ContactId = con.Id;
                ocr.Role = ocrRole;
                // Make primary only if Opportunity has no primary OCR
                if(opportunityPrimaryContactRoleExists.add(opp.Id)) {
                    ocr.IsPrimary = true;
                } else {
                    ocr.IsPrimary = false;
                }
                listToInsert.add(ocr);
            }
        }
        if(!listToInsert.isEmpty()) {
            insert listToInsert;
        }
    }
}