trigger ContactTrigger on Contact (after insert, after update) {

    if(Trigger.isInsert){
        ContactTriggerHandler.createOpportunityContactRoles(Trigger.new, null);
    }else if(Trigger.isUpdate){
        List<Contact> changedContacts = new List<Contact>();
        for(Contact con : Trigger.new) {
            Contact oldCon = Trigger.oldMap.get(con.Id);
            if(con.AccountId != oldCon.AccountId) {
                changedContacts.add(con);
            }
        }
        if(!changedContacts.isEmpty()) {
            ContactTriggerHandler.createOpportunityContactRoles(changedContacts, Trigger.oldMap);
        }
    }
}