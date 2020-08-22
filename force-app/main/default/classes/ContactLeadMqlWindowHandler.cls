/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           ContactLeadMqlWindowHandler
*
* @description    Service class that contains methods that handle MQL window record creation logic.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-10-07
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class ContactLeadMqlWindowHandler {




    public static void afterDeleteLead(List<Lead> newRecs, Map<Id, Lead> oldMap){
        List<Lead> filteredLeads = new List<Lead>();
        for(Lead l: newRecs){
        }
    }
    
    public static void afterDeleteContact(List<Contact> newRecs, Map<Id, Contact> oldMap){
        
    }
    
    
    public static void onInsertContact(List<Contact> lstContact){
        List<Contact> lstContact1= new List<Contact>();
        for(Contact objCont: lstContact){
            if(objCont.Engagement_Score__c !=null){
                lstContact1.add(objCont);
            }
        }
        if(lstContact1.size()>0){
            createUpdateMqlWindow(lstContact1,null);
        }
    }
    
    public static void onUpdateContact(List<Contact> lstContact, Map<Id,Contact> oldMap){
        List<Contact> lstContact1= new List<Contact>();
        for(Contact objCont: lstContact){
            if(objCont.Is_currently_MQL__c!=oldMap.get(objCont.id).Is_currently_MQL__c){
                lstContact1.add(objCont);
            }
        }
        if(lstContact1.size()>0){
            createUpdateMqlWindow(lstContact1,null);
        }
    }
    
    public static void onInsertLead(List<Lead> lstLead){
        List<Lead> lstLead1 = new List<Lead>();
        for(Lead objLead: lstLead){
            if(objLead.Engagement_Score__c !=null){
                lstLead1.add(objLead);
            }
        }
        if(lstLead1.size()>0){
            createUpdateMqlWindow(null,lstLead1);
        }
    }
        
    public static void onUpdateLead(List<Lead> lstLead, Map<Id,Lead> oldMap){
        List<Lead> lstLead1 = new List<Lead>();
        List<Lead> lstConvLead1 = new List<Lead>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setLeadIds = new Set<Id>();
        for(Lead objLead: lstLead){
            if(objLead.Is_currently_MQL__c!=oldMap.get(objLead.id).Is_currently_MQL__c){
                lstLead1.add(objLead);
            }
            if(objLead.IsConverted==true && oldMap.get(objLead.id).IsConverted==false){
                lstConvLead1.add(objLead);
                setContactIds.add(objLead.ConvertedContactId);
                setLeadIds.add(objLead.Id);
                TriggerRunOnceUtility.ContactLeadMqlWindowHandler=true;
            }
        }
        if(lstLead1.size()>0){
            createUpdateMqlWindow(null,lstLead1);
        }
        if(lstConvLead1.size()>0){
            //moveMqlWindows(lstConvLead1,setContactIds);
            moveMqlWindows(setLeadIds,setContactIds);
        }
    }
    
    
    //public static void moveMqlWindows(List<Lead> lstLead,Set<Id> setContactIds){
    @future
    public static void moveMqlWindows(Set<Id> lstLeadIds,Set<Id> setContactIds){
    
       List<Lead> lstLead = [select id, ConvertedContactId, Engagement_Score__c, Profile_Score__c, Is_currently_MQL__c from Lead where id in :lstLeadIds];
        if(lstLead!=null && lstLead.size()>0){
            List<MQL_Window__c> lstMqlWinForUpdate = new List<MQL_Window__c>();
            List<MQL_Window__c> lstMqlWin = [Select Id,Contact__c,lead__c,createdDate,MQL_Window_Status__c,
                                             Engagement_score_at_Close_Stamp__c,Profile_Score_at_Close_Stamp__c,
                                             MQL_Window_Close_Date__c, MQL_Window_Open_Date__c from MQL_Window__c 
                                             where Lead__c IN: lstLead order by lastmodifieddate desc];
            //Map<Id, List<MQL_Window__c>> mapLeadIdWithMqlWin = new Map<Id, List<MQL_Window__c>>();
            Map<Id,Contact> mapIdWithContact = new Map<Id,Contact>([Select Id,Is_currently_MQL__c , Engagement_Score__c ,Lead_Score_sum__c,Profile_Score__c,
                                                                    (Select Id,MQL_Window_Status__c,createdDate,Engagement_score_at_Close_Stamp__c,Profile_Score_at_Close_Stamp__c,
                                                                     MQL_Window_Close_Date__c, MQL_Window_Open_Date__c from MQL_Windows__r where MQL_Window_Status__c='Open')
                                                                     from Contact where Id IN:setContactIds]);
            System.debug('ListMQLWin ---> ' + lstMqlWin);
            //*************************************
            //JASON ADDED THIS 11-12-19
            /*for(MQL_Window__c mqlWin : lstMqlWin){
                if(mqlWin.Contact__c == null){
                    List<MQL_Window__c> tempMQLWindows = new List<MQL_Window__c>();
                    if(mapLeadIdWithMqlWin.get(mqlWin.Lead__c) == null){
                        tempMQLWindows.add(mqlWin);
                    } else {
                        tempMQLWindows = mapLeadIdWithMqlWin.get(mqlWin.Lead__c);
                        tempMQLWindows.add(mqlWin); 
                    }
                    mapLeadIdWithMqlWin.put(mqlWin.Lead__c, tempMQLWindows);
                }
            }*/
            //*************************************
            if(mapIdWithContact.size()>0){
                for(Lead objLead: lstLead){
                    if(mapIdWithContact.containsKey(objLead.ConvertedContactId)){
                        if(mapIdWithContact.get(objLead.ConvertedContactId).Engagement_Score__c!=null && objLead.Engagement_Score__c!=null){
                            mapIdWithContact.get(objLead.ConvertedContactId).Engagement_Score__c += objLead.Engagement_Score__c;
                        }else{
                            mapIdWithContact.get(objLead.ConvertedContactId).Engagement_Score__c = objLead.Engagement_Score__c;
                        }
                        if(mapIdWithContact.get(objLead.ConvertedContactId).Profile_Score__c!=null && objLead.Profile_Score__c!=null){
                            if(objLead.Profile_Score__c > mapIdWithContact.get(objLead.ConvertedContactId).Profile_Score__c){
                                mapIdWithContact.get(objLead.ConvertedContactId).Profile_Score__c = objLead.Profile_Score__c;
                            }
                        }else{
                            mapIdWithContact.get(objLead.ConvertedContactId).Profile_Score__c = objLead.Profile_Score__c;
                        }
                        
                        if(lstMqlWin!=null && lstMqlWin.size()>0){
                            for(MQL_Window__c objMqlWin: lstMqlWin){
                                objMqlWin.Contact__c = objLead.ConvertedContactId;
                                objMqlWin.Lead__c = null; //Jason added 11-13-20
                                if(objMqlWin.MQL_Window_Status__c=='Open' && mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r.size()>0){
                                    if(objMqlWin.MQL_Window_Open_Date__c/*CreatedDate*/ >= mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0].MQL_Window_Open_Date__c/*CreatedDate*/){
                                        objMqlWin.MQL_Window_Status__c ='Merged and Closed';
                                        objMqlWin.Engagement_score_at_Close_Stamp__c=objLead.Engagement_Score__c;
                                        objMqlWin.Profile_Score_at_Close_Stamp__c = objLead.Profile_Score__c;
                                        objMqlWin.MQL_Window_Close_Date__c=DateTime.now();
                                        lstMqlWinForUpdate.add(objMqlWin);
                                    }else{
                                        mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0].MQL_Window_Status__c ='Merged and Closed';
                                        mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0].Engagement_score_at_Close_Stamp__c=mapIdWithContact.get(objLead.ConvertedContactId).Engagement_Score__c;
                                        mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0].Profile_Score_at_Close_Stamp__c = mapIdWithContact.get(objLead.ConvertedContactId).Profile_Score__c;
                                        mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0].MQL_Window_Close_Date__c=DateTime.now();
                                        //lstMqlWin.add(mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0]);
                                        //lstMqlWinForUpdate.add(mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r[0]);
                                    }
                                //***Jason added this 11-13-20
                                } else if (objMqlWin.MQL_Window_Status__c=='Open'/* && mapIdWithContact.get(objLead.ConvertedContactId).MQL_Windows__r.size()==0*/){
                                    lstMqlWinForUpdate.add(objMqlWin);
                                }
                            }
                        }
                    }
                }
                if(mapIdWithContact.size()>0){
                    update(mapIdWithContact.values());
                }
                /*
                if(lstMqlWin!=null && lstMqlWin.size()>0){
                    update(lstMqlWin);
                }
                */
                System.debug('*** MQL Windows for Update ---> ' + lstMqlWinForUpdate);
                if(lstMqlWinForUpdate!=null && lstMqlWinForUpdate.size()>0){
                    update(lstMqlWinForUpdate);
                }
                if(mapIdWithContact.size()>0){
                    Map<Id,Contact> mapIdWithContact1 = new Map<Id,Contact>([Select Id,Is_currently_MQL__c, Engagement_Score__c,Lead_Score_sum__c,Profile_Score__c
                                                                             from Contact where Id IN:setContactIds]);
                    createUpdateMqlWindow(mapIdWithContact1.values(),null);
                }
            }
        }
    }
    
    public static void createUpdateMqlWindow(List<Contact> lstContact, List<Lead> lstLead){
        List<MQL_Window__c> lstMqlWinToUpsert = new List<MQL_Window__c>();
        if(lstContact!=null && lstContact.size()>0){
            Map<Id,MQL_Window__c> mapContIdWithMqlWin = new Map<Id,MQL_Window__c>();
            List<MQL_Window__c> lstMqlWin = [Select Id,Contact__c,MQL_Window_Close_Date__c,MQL_Window_Open_Date__c,MQL_Window_Status__c,
                                             Engagement_score_at_Close_Stamp__c,Engagement_score_at_Open_Stamp__c, Profile_Score_at_Close_Stamp__c ,Profile_Score_at_Open_Stamp__c     
                                             from MQL_Window__c where Contact__c IN: lstContact and MQL_Window_Status__c='Open' order by lastmodifieddate desc];
            for(MQL_Window__c objMqlWin: lstMqlWin){
                mapContIdWithMqlWin.put(objMqlWin.Contact__c,objMqlWin);
            }
            for(Contact objCnt: lstContact){
                if(objCnt.Is_currently_MQL__c==true){
                    if(!mapContIdWithMqlWin.containskey(objCnt.id)){
                        MQL_Window__c newMqlWin = new MQL_Window__c(Contact__c=objCnt.id,MQL_Window_Status__c='Open',
                                                                    Engagement_score_at_Open_Stamp__c=objCnt.Engagement_Score__c,
                                                                    Profile_Score_at_Open_Stamp__c = objCnt.Profile_Score__c,
                                                                    MQL_Window_Open_Date__c=DateTime.now());
                        lstMqlWinToUpsert.add(newMqlWin);
                    }
                }
                if(objCnt.Is_currently_MQL__c==false){
                    if(mapContIdWithMqlWin.size()>0){
                        if(mapContIdWithMqlWin.containskey(objCnt.id)){
                            MQL_Window__c newMqlWin = new MQL_Window__c(Id=mapContIdWithMqlWin.get(objCnt.id).Id,
                                                                        Contact__c=objCnt.id,MQL_Window_Status__c='Closed',
                                                                        Engagement_score_at_Close_Stamp__c=objCnt.Engagement_Score__c,
                                                                        Profile_Score_at_Close_Stamp__c = objCnt.Profile_Score__c,
                                                                        MQL_Window_Close_Date__c=DateTime.now());
                            lstMqlWinToUpsert.add(newMqlWin);
                        }
                    }
                }
            }
        }
        if(lstLead!=null && lstLead.size()>0){
            Map<Id,MQL_Window__c> mapLeadIdWithMqlWin = new Map<Id,MQL_Window__c>();
            List<MQL_Window__c> lstMqlWin = [Select Id,Lead__c,MQL_Window_Close_Date__c,MQL_Window_Open_Date__c,MQL_Window_Status__c,
                                             Engagement_score_at_Close_Stamp__c,Engagement_score_at_Open_Stamp__c, Profile_Score_at_Close_Stamp__c ,Profile_Score_at_Open_Stamp__c
                                             from MQL_Window__c where Lead__c IN: lstLead and MQL_Window_Status__c='Open' order by lastmodifieddate desc];
            for(MQL_Window__c objMqlWin: lstMqlWin){
                mapLeadIdWithMqlWin.put(objMqlWin.Lead__c,objMqlWin);
            }
            for(Lead objLead: lstLead){
                if(objLead.Is_currently_MQL__c==true){
                    if(!mapLeadIdWithMqlWin.containskey(objLead.id)){
                        MQL_Window__c newMqlWin = new MQL_Window__c(Lead__c=objLead.id,MQL_Window_Status__c='Open',
                                                                    Engagement_score_at_Open_Stamp__c=objLead.Engagement_Score__c,
                                                                    Profile_Score_at_Open_Stamp__c = objLead.Profile_Score__c,
                                                                    MQL_Window_Open_Date__c=DateTime.now());
                        lstMqlWinToUpsert.add(newMqlWin);
                    }
                }
                if(objLead.Is_currently_MQL__c==false){
                    if(mapLeadIdWithMqlWin.size()>0){
                        if(mapLeadIdWithMqlWin.containskey(objLead.id)){
                            MQL_Window__c newMqlWin = new MQL_Window__c(Id=mapLeadIdWithMqlWin.get(objLead.id).Id,
                                                                        Lead__c=objLead.id,MQL_Window_Status__c='Closed',
                                                                        Engagement_score_at_Close_Stamp__c=objLead.Engagement_Score__c,
                                                                        Profile_Score_at_Close_Stamp__c = objLead.Profile_Score__c,
                                                                        MQL_Window_Close_Date__c=DateTime.now());
                            lstMqlWinToUpsert.add(newMqlWin);
                        }
                    }
                }
            }
        }
        if(lstMqlWinToUpsert.size()>0){
            upsert lstMqlWinToUpsert;
        }
    }
}