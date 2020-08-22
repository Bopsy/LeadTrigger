//Created by: Gram Bischof 02/13/2020
//Last Modified: Gram Bischof 20/02/2020
//
//Description: 
//this class is used to change the status of Event_Certification__c
/**********************************************************/

public class EventCertificationController extends TriggerHandlar{
    
    private final List<Event_Certification__c> newEventCertificationList;
    private final Map<Id, Event_Certification__c> newEventCertificationMap;
    
    // constructor
    public EventCertificationController(List<Event_Certification__c> newEventCertificationList, Map<Id, Event_Certification__c> newEventCertificationMap) {
        super();
        this.newEventCertificationList = (List<Event_Certification__c>) newEventCertificationList;
        this.newEventCertificationMap = (Map<Id, Event_Certification__c>)newEventCertificationMap;
    }
    
    
    public override void executeBeforeInsert(){    
        try{
            set<id> eventIds = new set<id>();       //set of event ids.
            
            for(Event_Certification__c objCertification : newEventCertificationList){   
                if(objCertification.Event_ID__c !=null){
                    eventIds.add(objCertification.Event_ID__c); 
                }
            }
            
            Map <id,string> eventMap = new Map <id,string>();    //Map of event ids and event type    
            
            List <event> eventList = new List <event>();
            
            eventList = [select id,type from event where id in : eventIds];        
            for(event objEvent : eventList){
                if(objEvent.id !=null && objEvent.type !=null){
                    eventMap.put(objEvent.id,objEvent.type);                
                }            
            }
            
            // Here we itrate over Event_Certification__c and if parent event type is webinar then assign status = 'Enrolled'
            
            for(Event_Certification__c objCertification : newEventCertificationList){
                if(objCertification.Event_ID__c !=null){
                    string eventType = eventMap.get(objCertification.Event_ID__c).toLowerCase();
                    if(eventType == 'webinar'){
                        objCertification.Status__c = 'Enrolled';                 
                    }
                }
            }
        }catch(Exception e){
            system.debug('error--'+e.getMessage() + 'at line number------'+e.getLineNumber());
        }
    }
    
    public override void updatePartnerInfluencer (){
    }
    
    public static void UpdateCertificationStageAndCertificationDate(List<Event_Certification__c> theECList) {
        
        List<Id> thePCIds = new List<Id>();
        List<Partner_Certification__c> thePCUpdateList = new List<Partner_Certification__c>();
        for(Event_Certification__c theEC : theECList) {
            thePCIds.add(theEC.Partner_Certification__c);
        }
        
        List<Partner_Certification__c> thePCList = [SELECT Id, Certification_Stage__c, Certification_Date__c, (SELECT Id, Status__c FROM Event_Certifications__r) FROM Partner_Certification__c WHERE Id IN: thePCIds];
        
        for(Partner_Certification__c thePC : thePCList) {
            for(Event_Certification__c theEC : thePC.Event_Certifications__r) {
                if(theEC.Status__c == 'Enrolled' && thePC.Certification_Stage__c != 'Enrolled') {
                    thePC.Certification_Stage__c = theEC.Status__c;
                }else if(theEC.Status__c == 'Pending Approval' && thePC.Certification_Stage__c != 'Pending Approval') {
                    thePC.Certification_Stage__c = theEC.Status__c;
                }else if(theEC.Status__c == 'Rejected' && thePC.Certification_Stage__c != 'Rejected') {
                    thePC.Certification_Stage__c = theEC.Status__c;
                }  
            }
            thePCUpdateList.add(thePC);  
        }
        if(thePCUpdateList.size() > 0) {
            update thePCUpdateList;
        }
    }
   
}