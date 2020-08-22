/**********************************************************/
//Created by: Gram Bischof 03/12/2020
//Last Modified: Gram Bischof 03/13/2020
//Description: This class is used to Display Event Related List.
//Test Class : 
/**********************************************************/
public class EventCertificationRelatedListContr {
    
    @AuraEnabled
    public static List<EventCertificationWrapper> getRelatedListRecord(String RecordId) {
        List<EventCertificationWrapper> theWrapperList = new List<EventCertificationWrapper>();
        List<Event_Certification__c> theEventCertifiList = [SELECT Id, Name, Partner_Certification__r.Account__r.Name, Partner_Certification__r.Certification_Stage__c, Partner_Certification__r.Contact__r.Name, Partner_Certification__r.Contact__r.Email FROM Event_Certification__c WHERE Event_ID__c =: RecordId];
        if(theEventCertifiList.size() > 0) {
            for(Event_Certification__c theEC : theEventCertifiList) {
                EventCertificationWrapper theWrapper = new EventCertificationWrapper();
                if(theEC.Partner_Certification__r.Account__r.Name != null) {
                    theWrapper.theAccntName = theEC.Partner_Certification__r.Account__r.Name;
                }
                if(theEC.Partner_Certification__r.Contact__r.Name != null) {
                    theWrapper.theContactName = theEC.Partner_Certification__r.Contact__r.Name;
                }
                if(theEC.Partner_Certification__r.Contact__r.Email != null) {
                    theWrapper.theContactEmail = theEC.Partner_Certification__r.Contact__r.Email;
                }
                if(theEC.Partner_Certification__r.Certification_Stage__c != null) {
                    theWrapper.thePartnerCertStage = theEC.Partner_Certification__r.Certification_Stage__c;
                }
                if(theEC.Id != null) {
                    theWrapper.theEventCertID = theEC.Id;
                }
                if(theEC.Name != null) {
                    theWrapper.theEventCert = theEC.Name;
                }
                theWrapperList.add(theWrapper);
            }
        }
        return theWrapperList;
    }
    
    public class EventCertificationWrapper{
        
        @AuraEnabled
        public String theAccntName{get;set;}
        @AuraEnabled
        public String theContactName{get;set;}
        @AuraEnabled
        public String theContactEmail{get;set;}
        @AuraEnabled
        public String thePartnerCertStage{get;set;}
        @AuraEnabled
        public String theEventCertID{get;set;}
        @AuraEnabled
        public String theEventCert{get;set;}
    }
}