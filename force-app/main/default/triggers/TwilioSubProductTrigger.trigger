trigger TwilioSubProductTrigger on Twilio_Sub_Product__c (after insert, before insert, before update, before delete) {
    static Map<String, String> prpIdMap {
        get{
            if(prpIdMap == null){
                prpIdMap = new Map<String, String>();
                for(SendGrid_PRP_ID_Mapping__c setting: SendGrid_PRP_ID_Mapping__c.getAll().values()){
                    prpIdMap.put(setting.Product_Name__c, setting.PRP_ID__c);
                }
            }
            return prpIdMap;
        }
        set;
    }
    if(trigger.isAfter){
        if(trigger.isInsert){
            List<SendGrid_Price_Concession__c> concessions = new List<SendGrid_Price_Concession__c>();
            for(Twilio_Sub_Product__c subProd: trigger.new){
                if(subProd.SendGrid_Product__c){
                    SendGrid_Price_Concession__c concession = new SendGrid_Price_Concession__c(Opportunity__c = subProd.Opportunity_Id__c, Twilio_Sub_Product__c = subProd.Id);
                    concessions.add(concession);
                }
            }
            insert concessions;
        }
        
    }
    else if(trigger.isBefore){
        if(trigger.isInsert || trigger.isUpdate){
            for(Twilio_Sub_Product__c subProd: trigger.new){
                String keyString = subProd.Twilio_Product_Name__c + '-' + subProd.Name;
                if(subProd.SendGrid_Package_Size__c != null) keyString += ' ' + subProd.SendGrid_Package_Size__c;
                subProd.SendGrid_PRP_Id__c = prpIdMap.get(keyString);
            }
        }
        if(trigger.isDelete){
            List<SendGrid_Price_Concession__c> deleteConcessions = [SELECT Id FROM SendGrid_Price_Concession__c WHERE Twilio_Sub_Product__c =: trigger.old];
            //system.assert(false, deleteConcessions);
            delete deleteConcessions;
        }
    }
}