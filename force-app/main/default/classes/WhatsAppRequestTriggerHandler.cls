/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           WhatsAppRequestTriggerHandler
*
* @description    Service class for WhatsAppRequestTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-08-12
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class WhatsAppRequestTriggerHandler {
    
    public static void onInsertCampaignMembers(List<CampaignMember> newList) {
        List<CampaignMember> newList1 = new List<CampaignMember>();
        for(CampaignMember objCampaignMember: newList){
            if(objCampaignMember.Description__c!=null){
                newList1.add(objCampaignMember);
            }
        }
        if(newList1.size()>0){
            createWhatsappRecords(newList1);
        }
    }
    
    public static void onUpdateCampaignMembers(List<CampaignMember> newList, Map<Id,CampaignMember> oldMap) {
        List<CampaignMember> newList1 = new List<CampaignMember>();
        for(CampaignMember objCampaignMember: newList){
            if(objCampaignMember.Description__c!=null && objCampaignMember.Description__c!=oldMap.get(objCampaignMember.Id).Description__c){
                newList1.add(objCampaignMember);
            }
        }
        if(newList1.size()>0){
            createWhatsappRecords(newList1);
        }
    }
    
    public static void createWhatsappRecords(List<CampaignMember> newList) {
        List<CampaignMember> lstCampaignMembersToConsider = new List<CampaignMember>();
        Set<Id> setCampaignIds = new Set<Id>();
        Map<Id,List<String>> mapCampaignMemIdWithDesc = new Map<Id,List<String>>();
        List<WhatsApp_Request__c> lstWhatsapp = new List<WhatsApp_Request__c>();
        
        for(Campaigns_for_Whatsapp_Request__c setting : Campaigns_for_Whatsapp_Request__c.getAll().values()){
            setCampaignIds.add((Id) setting.name);
        }
        for(CampaignMember objCampaignMember: newList){
            if(setCampaignIds.contains(String.valueOf(objCampaignMember.CampaignId).substring(0, 15))){
                lstCampaignMembersToConsider.add(objCampaignMember);
                //split description into multiple lines and add it to List of strings
                //map campaign member id with these List of strings
                if(objCampaignMember.Description__c!=null){
                    List<String> lstDescription = new List<String>();
                    system.debug('++spli '+objCampaignMember.Description__c);
                    lstDescription.addAll(objCampaignMember.Description__c.split('::'));
                    mapCampaignMemIdWithDesc.put(objCampaignMember.Id, lstDescription);
                }
            }
        }
        
        if(lstCampaignMembersToConsider.size()>0){
            for(CampaignMember objCampaignmember: lstCampaignMembersToConsider){
                WhatsApp_Request__c objWhatsapp = new WhatsApp_Request__c();
                if(mapCampaignMemIdWithDesc!=null & mapCampaignMemIdWithDesc.get(objCampaignmember.id)!=null){
                    //map description field to whatsapp request fields
                    for(Integer i=0;i<mapCampaignMemIdWithDesc.get(objCampaignmember.id).size();i++){
                        String key = 'Description Line ' + (i+1);
                        if(mapCampaignMemIdWithDesc.get(objCampaignmember.id).get(i)!=null && Campaign_member_to_Whatsapp_mappings__c.getInstance(key).Whatsapp_Request_API__c!=null){
                            objWhatsapp.put(Campaign_member_to_Whatsapp_mappings__c.getInstance(key).Whatsapp_Request_API__c,
                                            mapCampaignMemIdWithDesc.get(objCampaignmember.id).get(i));
                        }
                    }
                }
                //map other fields to whatsapp request fields
                for(Campaign_member_to_Whatsapp_mappings__c setting: Campaign_member_to_Whatsapp_mappings__c.getAll().values()){
                    if(setting.Campaign_member_API__c !=null && setting.Whatsapp_Request_API__c!=null){
                        if(!setting.name.containsignorecase('Description')){
                            objWhatsapp.put(setting.Whatsapp_Request_API__c,objCampaignmember.get(setting.Campaign_member_API__c));
                        }
                    }
                }
                system.debug('+++objWhatsapp '+objWhatsapp);
                lstWhatsapp.add(objWhatsapp);
            }
        }
        insert lstWhatsapp;
    }
    
    public static void updateMQLOnInsert(List<WhatsApp_Request__c> newList) {
        List<WhatsApp_Request__c> validMQLList = new List<WhatsApp_Request__c>();
        List<WhatsApp_Request__c> validAccountList = new List<WhatsApp_Request__c>();
        List<WhatsApp_Request__c> validAccountSIDList = new List<WhatsApp_Request__c>();
        Set<Id> setLeadIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setCampaignIds = new Set<Id>();
        for(WhatsApp_Request__c objWA: newList){
            if(objWA.Lead__c!=null || objWA.Contact__c!=null){
                setCampaignIds.add(objWA.Campaign__c);
                validMQLList.add(objWA);
            }
            if(objWA.Lead__c!=null){
                setLeadIds.add(objWA.Lead__c);
            }
            if(objWA.Contact__c!=null){
                validAccountList.add(objWA);
                setContactIds.add(objWA.Contact__c);
            }
            if(objWA.Account_SID_text__c!=null){
                validAccountSIDList.add(objWA);
            }
        }
        if(validMQLList.size()>0){
            assignMQL(validMQLList,setLeadIds,setContactIds,setCampaignIds);
        }
        if(validAccountList.size()>0){
            assignAccount(validAccountList);
        }
        if(validAccountSIDList.size()>0){
            assignAccountSid(validAccountSIDList);
        }
    }
    
    public static void updateMQLOnUpdate(Map<Id,WhatsApp_Request__c> oldMap, List<WhatsApp_Request__c> newList) {
        List<WhatsApp_Request__c> validMQLList = new List<WhatsApp_Request__c>();
        List<WhatsApp_Request__c> validAccountList = new List<WhatsApp_Request__c>();
        List<WhatsApp_Request__c> validAccountSIDList = new List<WhatsApp_Request__c>();
        Set<Id> setLeadIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setCampaignIds = new Set<Id>();
        for(WhatsApp_Request__c objWA: newList){
            if((objWA.Lead__c!=null && oldMap.get(objWA.id).Lead__c!=objWA.Lead__c) || (objWA.Contact__c!=null && oldMap.get(objWA.id).Contact__c!=objWA.Contact__c)){
                setCampaignIds.add(objWA.Campaign__c);
                validMQLList.add(objWA);
            }else if((oldMap.get(objWA.id).Lead__c!=null && objWA.Lead__c==null) || (oldMap.get(objWA.id).Contact__c!=null && objWA.Contact__c==null)){
                objWA.MQL__c = null;
            }
            
            if((objWA.Lead__c!=null && oldMap.get(objWA.id).Lead__c!=objWA.Lead__c)){
                setLeadIds.add(objWA.Lead__c);
            }
            
            if(objWA.Contact__c!=null && oldMap.get(objWA.id).Contact__c!=objWA.Contact__c){
                setContactIds.add(objWA.Contact__c);
                validAccountList.add(objWA);
            }else if(oldMap.get(objWA.id).Contact__c!=null && objWA.Contact__c==null){
                objWA.Account__c = null;
            }
            
            if(objWA.Account_SID_text__c!=null && oldMap.get(objWA.id).Account_SID_text__c!=objWA.Account_SID_text__c){
                validAccountSIDList.add(objWA);
            }else if(oldMap.get(objWA.id).Account_SID_text__c!=null && objWA.Account_SID_text__c==null){
                objWA.Account_SID__c = null;
            }
        }
        if(validMQLList.size()>0){
            assignMQL(validMQLList,setLeadIds,setContactIds,setCampaignIds);
        }
        if(validAccountList.size()>0){
            assignAccount(validAccountList);
        }
        if(validAccountSIDList.size()>0){
            assignAccountSid(validAccountSIDList);
        }
    }
    
    public static void assignMQL(List<WhatsApp_Request__c> newList, Set<Id> setLeadIds,Set<Id> setContactIds,Set<Id> setCampaignIds) {
        if(setLeadIds!=null && setLeadIds.size()>0){
            List<FSR__c> lstMQLs = [Select Id,Campaign__c, Lead__c  from FSR__c where Lead__c IN: setLeadIds and Campaign__c IN: setCampaignIds and contact__c=null order by createddate desc];
            if(lstMQLs!=null && lstMQLs.size()>0){
                for(WhatsApp_Request__c objWA: newList){
                    for(FSR__c objMql: lstMQLs){
                        if(objMql.Lead__c!=null && objWA.lead__c!=null && objWA.Campaign__c==objMql.Campaign__c && objWA.Lead__c==objMql.Lead__c){
                            objWA.MQL__c = objMql.id;
                        }
                    }
                }
            }
        }
        if(setContactIds!=null && setContactIds.size()>0){
            List<FSR__c> lstMQLs = [Select Id,Campaign__c, contact__c  from FSR__c where Contact__c IN: setContactIds and Campaign__c IN: setCampaignIds and lead__c=null order by createddate desc];
            if(lstMQLs!=null && lstMQLs.size()>0){
                for(WhatsApp_Request__c objWA: newList){
                    for(FSR__c objMql: lstMQLs){
                        if(objMql.Contact__c!=null && objWA.Contact__c!=null && objWA.Campaign__c==objMql.Campaign__c && objWA.Contact__c==objMql.Contact__c){
                            objWA.MQL__c = objMql.id;
                        }
                    }
                }
            }
        }
        
    }
    
    public static void assignAccount(List<WhatsApp_Request__c> newList){
        Set<Id> setContactIds = new Set<Id>();
        for(WhatsApp_Request__c objWA: newList){
            setContactIds.add(objWA.Contact__c);
            objWA.Account__c=null;
        }
        Map<Id,Contact> mapContact = new Map<Id,Contact>([Select Id, AccountId from Contact where Id IN:setContactIds]);
        for(WhatsApp_Request__c objWA: newList){
            objWA.Account__c = mapContact.get(objWA.Contact__c).AccountId;
        }
    }
    
    public static void assignAccountSid(List<WhatsApp_Request__c> newList){
        Set<String> setSIds = new Set<String>();
        for(WhatsApp_Request__c objWA: newList){
            setSIds.add(objWA.Account_SID_text__c);
            objWA.Account_SID__c=null;
        }
        List<Account_SID__c> lstAcntSid = [Select Id, Account_SID__c from Account_SID__c where Account_SID__c IN:setSIds order by createddate desc];
        if(lstAcntSid!=null && lstAcntSid.size()>0){
            for(WhatsApp_Request__c objWA: newList){
                for(Account_SID__c objAcntSid: lstAcntSid){
                    if(objWA.Account_SID_text__c==objAcntSid.Account_SID__c){
                        objWA.Account_SID__c=objAcntSid.Id;
                    }
            	}
            }
        }
    }
}