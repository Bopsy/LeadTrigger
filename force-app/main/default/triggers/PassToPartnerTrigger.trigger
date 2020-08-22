trigger PassToPartnerTrigger on Pass_to_Partner__c (before insert, before update, after insert, after update, after delete, after undelete) {
    if(Trigger.isBefore) {
        
        // Unset fields if the Partner_Status__c is set to an ending status
        PassToPartnerTriggerHandler.unsetFieldsOnEndingStatus(Trigger.new);
        
        // Copy the fields specified by the Opportunity_to_PTP_Mappings__c custom setting from the
        // Pass_To_Partner__c.Opportunity__c to the Pass_To_Partner__c record.
        if (Trigger.isInsert) {
            PassToPartnerTriggerHandler.copyFieldsFromOpportunity(Trigger.new);
        } else if (Trigger.isUpdate) {
            // Copy only occurs if the Pass_To_Partner__c.Opportunity__c is being changed.
            PassToPartnerTriggerHandler.copyFieldsFromOpportunity(Trigger.oldMap, Trigger.newMap);
        }
    } else if (Trigger.isAfter) {
        if(trigger.isInsert){
            /*  List<Pass_To_Partner__Share> ptpShrs  = new List<Pass_To_Partner__Share>();
for(Pass_To_Partner__c ptp: trigger.new){
for(User u: [SELECT Id FROM User WHERE Contact.AccountId = :ptp.Create_User_Account_ID__c AND Contact.AccountId != null AND IsActive = true]){
Pass_To_Partner__Share shr = new Pass_To_Partner__Share();
shr.ParentId = ptp.Id;
shr.UserOrGroupId = u.Id;
shr.RowCause = Schema.Pass_To_Partner__Share.RowCause.Creator__c;
shr.AccessLevel = 'edit';

ptpShrs.add(shr);
}
}
insert ptpShrs;
*/
            //calling  the method from the handler to create the 
            //sharing the pass_to_partner withe all the community users.
            PassToPartnerTriggerHandler.createSharingForCommunityUser(Trigger.new);
            
        } else if(Trigger.isUpdate) {
            //PassToPartnerTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        // Update Opportunity.Active_Pass_to_Partner__c lookup field
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            PassToPartnerTriggerHandler.setOpportunityActivePassToPartner(Trigger.newMap);
        }
        
    }
}