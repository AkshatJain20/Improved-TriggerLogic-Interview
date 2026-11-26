trigger OpportunityTrigger on Opportunity (after insert, after update){

	OpportunityTriggerHandler.createContactRoles(Trigger.new);
}