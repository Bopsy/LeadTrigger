//Created by: Nitish 3/3/2020
//Last Modified: Nitish 3/3/2020
//
//Description: 
//Trigger that use to update the Builder Certified field
//whenever PartnerCertification inserted or updated.
//
// Hanlder : - PartnerCertificationHandler 
/**********************************************************/
trigger PartnerCertification on Partner_Certification__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    PartnerCertificationHandler handler = new PartnerCertificationHandler(Trigger.new,Trigger.oldMap);
    try{
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handler.updateAccountOnPartnerCertification();
            }
            
            if (Trigger.isUpdate) {
                handler.updateAccountOnPartnerCertification();            
            }
            
            if (Trigger.isDelete) {
                handler.updateAccountOnPartnerCertification();
            }
            
            if (Trigger.isUndelete) {
                handler.updateAccountOnPartnerCertification();
            }
        }
    }
    catch(Exception ex){
       System.debug(ex.getMessage());
       System.debug(ex.getStackTraceString ());
       throw ex;
    }
}