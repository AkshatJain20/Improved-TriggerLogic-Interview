trigger ContactTrigger on Contact (after insert, after update) {

    ContactTriggerHandler.createOpportunityContactRoles(
            Trigger.new,
        	Trigger.isUpdate ? Trigger.oldMap : null
        );
}