trigger MQLTrigger on FSR__c (after insert, after update, before insert, before update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        List<FSR__c> mqls = new List<FSR__c>();
        for(FSR__c n: Trigger.new){
            if(!n.Bypass_Trigger__c){
                mqls.add(n);
            }
        }
        MQLHandler.linkShortCodesByLeadOrContact(mqls);
    }

    if(Trigger.isBefore){
        Map<String, String> countryMap = new Map<String, String>();
        for(MQL_Country_to_Region__c setting: MQL_Country_to_Region__c.getAll().values()){
            countryMap.put(setting.Country__c, setting.Region__c);
        }
        for(FSR__c mql: trigger.new){
            if(mql.Lead__c != null && mql.Contact__c == null && mql.ConvertedContactId__c != null){
                mql.Lead__c = null;
                mql.Contact__c = mql.ConvertedContactId__c;
            }
            mql.Marketing_Region__c = countryMap.get(mql.Country__c);
            mql.Pipeline_Region__c = countryMap.get(mql.Pipeline_Country__c);
        }
    }
    
    
    // When an MQL that has a Short Code Application is set to rejected with one of the following reasons,
    // set the related Short Code Application to “Archive”:
    //     Incomplete Record/Email Bounce
    //     No Response
    //     Fraud
    //     Does not want to talk/Unsubscribed
    //     No Clear Project
    //     If the MQL is only related to a Lead, no further action needed.
    //     If the MQL is related to a Contact, notify the Contact's Account Owner of MQL/Short Code Application being rejected.
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<FSR__c> mqlList = new List<FSR__c>();
        
        for (FSR__c n : Trigger.new) {
            FSR__c o = Trigger.oldMap.get(n.Id);
            if (!n.Bypass_Trigger__c && (n.MQL_Status__c != o.MQL_Status__c || n.Rejected_Reason__c != o.Rejected_Reason__c)) {
                mqlList.add(n);
            }
        }
        
        if (!mqlList.isEmpty()) {
            //MQLHandler.archiveShortCode(mqlList);
        }
    }
    
//    if (Trigger.isAfter && (Trigger.isInsert && Trigger.isUpdate)) {
//    	TimeUtils.setInferredTimezoneSidKey(Trigger.new);
//    }
}