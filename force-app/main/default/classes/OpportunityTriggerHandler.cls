public class OpportunityTriggerHandler{

	public static void createContactRoles(List<opportunity> opportunities){
		
		Set<Id> accountIds = new Set<Id>();
		for(Opportunity o:opportunities){
    			accountIds.add(o.AccountId);
		}
		if (accountIds.isEmpty()) {
            		return;
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
				opportunityPrimaryContactRoleExists.add(ocr.OpportunityId);
			}
			if(!existingOpportunityContactRoles.containsKey(ocr.OpportunityId)){
				existingOpportunityContactRoles.put(ocr.OpportunityId, new Set<Id>());
			}
			existingOpportunityContactRoles.get(ocr.OpportunityId).add(ocr.ContactId);
		}
		List<OpportunityContactRole> listToInsert = new List<OpportunityContactRole>();
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
				if(!isPrimaryExists){
					isPrimaryExists = true;
				}
				listToInsert.add(ocr);
			}
		}
		if(!listToInsert.isEmpty()){
			insert listToInsert;	
		}
	}
	
}