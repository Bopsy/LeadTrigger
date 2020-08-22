//----------------------------------------------------------------------------------------------------------
// Utility class MQLActivitiesController 
//----------------------------------------------------------------------------------------------------------
public without sharing class MQLActivitiesController {

    public Integer maxSearchResults = 50;

    public FSR__c mql;
    public List<ActivityRecord> activities {get;set;}
    public Boolean relatedToLead { get { return (mql!=null && mql.Lead__c!=null); }}
    public Boolean relatedToContact { get { return (mql!=null && mql.Contact__c!=null); }}

    // Constructor    
    public MQLActivitiesController(ApexPages.StandardController controller) {  
        // Need to add all of the fields so that they will be needed from the MQL (FSR__c) record
        List<String> fieldList = new List<String>();
        fieldList.add('Contact__c');
        fieldList.add('Lead__c');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
       
        mql = (FSR__c)controller.getRecord();
        System.debug('MQL: ' + mql);

        activities = new List<ActivityRecord>();

        if (relatedToContact || relatedToLead) {
            SObject obj = relatedToContact ? (SObject)getContactActivities(mql.Contact__c) : (SObject)getLeadActivities(mql.Lead__c);

            if (obj != null) {
                for (OpenActivity o : obj.getSObjects('OpenActivities')) {
                    System.debug('OPEN ObjectId(' + obj.Id + ') OpenActivities(' + o + ')');
                    activities.add(new ActivityRecord(o));
                }
            
                for (ActivityHistory h : obj.getSObjects('ActivityHistories')) {
                    System.debug('HISTORY ObjectId(' + obj.Id + ') ActivityHistory(' + h + ')');
                    activities.add(new ActivityRecord(h));
                }

                activities.sort();
            }
        }
    }

    public Contact getContactActivities(Id contactId) {
        List<Contact> c = [
            SELECT Id, (
                SELECT Id, ActivityDate, Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                FROM OpenActivities
                ORDER BY CreatedDate desc LIMIT :maxSearchResults
            ), (
                SELECT Id, ActivityDate, Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                FROM ActivityHistories
                ORDER BY CreatedDate desc LIMIT :maxSearchResults
            )
            FROM Contact
            WHERE Id = :contactId
        ];
        return c.isEmpty() ? null : c[0];
    }

    public Lead getLeadActivities(Id leadId) {
        List<Lead> l = [
            SELECT Id, (
                SELECT Id, ActivityDate, Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                FROM OpenActivities
                ORDER BY CreatedDate desc LIMIT :maxSearchResults
            ), (
                SELECT Id, ActivityDate, Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                FROM ActivityHistories
                ORDER BY CreatedDate desc LIMIT :maxSearchResults
            )
            FROM Lead
            WHERE Id = :leadId
        ];
        return l.isEmpty() ? null : l[0];
    }
}