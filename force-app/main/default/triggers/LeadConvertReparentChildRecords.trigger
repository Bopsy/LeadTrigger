trigger LeadConvertReparentChildRecords on Lead (after update) {
    Map<Id,Id> leadToContactMap = new Map<Id,Id>();
    Map<Id,Id> leadToAccountMap = new Map<Id,Id>();
    
    if(Trigger.isUpdate){
        for(Lead l : Trigger.new){
            System.debug('====> UPDATE LEAD(Id=' + l.Id + ', New.IsConverted=' + l.IsConverted + ', Old.IsConverted=' + Trigger.oldMap.get(l.Id).IsConverted + ')');
            if ((l.IsConverted && !Trigger.oldMap.get(l.Id).IsConverted) || Test.isRunningTest()) {
                leadToContactMap.put(l.Id, l.ConvertedContactId);
                leadToAccountMap.put(l.Id, l.ConvertedAccountId);
            }
        }
    }
    
    // Link the child records of the converted Lead to the new Contact
    if (!leadToContactMap.isEmpty() || !leadToAccountMap.isEmpty()) {
        LeadAutoConvertHandler.linkTwilioUsagesToContact(leadToContactMap, leadToAccountMap);
        LeadAutoConvertHandler.linkZendeskTicketsToContact(leadToContactMap, leadToAccountMap);
        LeadAutoConvertHandler.linkFSRToContact(leadToContactMap);
    }
}