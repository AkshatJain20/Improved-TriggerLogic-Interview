trigger OpportunityTrigger on Opportunity (after insert, after update){

    if(Trigger.isInsert) {
        OpportunityTriggerHandler.createContactRoles(Trigger.new, null);
    }else if(Trigger.isUpdate){
        List<Opportunity> changedOpportunities = new List<Opportunity>();
        for(Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            if(opp.AccountId != oldOpp.AccountId) {
                changedOpportunities.add(opp);
            }
        }
        if(!changedOpportunities.isEmpty()) {
            OpportunityTriggerHandler.createContactRoles(changedOpportunities, Trigger.oldMap);
        }
    }
	
}