//----------------------------------------------------------------------------------------------------------
// Utility class CallToActionHandler 
//----------------------------------------------------------------------------------------------------------
public without sharing class CallToActionHandler {
    public static String jbcxmPickListClosedLabel = 'Event - Closed Complete';
    public static String jbcxmPickListOpenLabel = 'Event - Open';

/*
    This trigger will fire when a task get insert/update.
    When a task.Type = "Call" AND Activity Type = "Call" AND Status = "Completed"
    Grab the ActivityDate of this task
    Check and get Task.WhoId and this should be a Contact Id.
    Query back Contact.Account.Number_of_Use_Cases__c, if this value > 0, go to next step, if not, do nothing.
    Query back all Account related Call To Action (API Name: JBCXM__CTA__c) with Status(API Name: JBCXM__Stage__r.Name) IN ['Open', 'Event - Open', 'Event - Working'] AND JBCXM__CreatedDate__c <= Task.ActivityDate
    Set all these Call To Action's Status to 'Event - Closed Complete' (**)
*/
    public static void setStatus(Map<Id,Task> taskMap) {
        System.debug('Processing Tasks: ' + taskMap.keySet());

        // Re-query the tasks to only work on the ones that meet the criteria
        //    Task.Type = "Call" AND Activity Type = "Call" AND Status = "Completed"
        //    Task.Who must be a Contact
        //    Contact.Account.Number_of_Use_Cases__c > 0
        Map<Id,Task> tasks = new Map<Id,Task>();
        Set<Id> contactIds = new Set<Id>();
        for (Task t : taskMap.values()) {
            if (t.Status == 'Completed'
                && t.Type == 'Call'
                //&& t.Activity_Type_del__c == 'Call'
                && t.WhoId != NULL
                && t.whoId.getSObjectType().getDescribe().getName() == 'Contact'
            ) {
                tasks.put(t.Id, t);
                contactIds.add(t.WhoId);
            }
        }
        System.debug('Matching Contact IDs: ' + contactIds);
        
        // If no Task records returned then no further processing required
        if (tasks.isEmpty()) return;
        
        // Create a list of all related Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Contact c : [
            SELECT Id, AccountId, Account.Number_of_Use_Cases__c
            FROM Contact
            WHERE Id IN :contactIds
            AND Account.Number_of_Use_Cases__c > 0
        ]) {
            accountIds.add(c.AccountId);
            System.debug('Account ' + c.AccountId + ' number of Use Cases: ' + c.Account.Number_of_Use_Cases__c);
        }
        System.debug('Matching Account IDs: ' + accountIds);
        
        // If no Account records found then no further processing required
        if (accountIds.isEmpty()) return;

        // Query related Call To Action records by Task.Contact.Account that meet the criteria
        //    Call To Action Status (API Name: JBCXM__Stage__r.Name) IN ['Open', 'Event - Open', 'Event - Working']
        List<JBCXM__CTA__c> callToActions = [
            SELECT Id, JBCXM__Account__r.Id, JBCXM__Account__r.OwnerId, JBCXM__Stage__c, JBCXM__CreatedDate__c
            FROM JBCXM__CTA__c
            WHERE JBCXM__Account__r.Id IN :accountIds
            AND JBCXM__IsClosed__c = false
            AND JBCXM__Playbook__r.Name = 'New Managed Customer - No Email'
        ];
        System.debug('Matching CTA records: ' + callToActions);

        // If no Call To Action records returned then no further processing required
        if (callToActions.isEmpty()) return;

        // Lookup up the 'Event - Closed Complete' picklist value so that it can be used to set
        // the Call To Action Status.
        JBCXM__PickList__c pickListValue;
        try {
            pickListValue = [ SELECT Id FROM JBCXM__PickList__c WHERE Name = :jbcxmPickListClosedLabel LIMIT 1];
        } catch (Exception e) {
            // If the picklist value is not found then report the error
            for (Task t : tasks.values()) {
                t.addError('Missing picklist value from JBCXM__PickList__c:  Needed \'' + jbcxmPickListClosedLabel + '\'');
            }
            return;
        }
        System.debug('JBCXM__PickList__c Event Closed record: ' + pickListValue);

        //  If JBCXM__CreatedDate__c <= Task.ActivityDate then set the Status on the Call To Action
        //  records to 'Event - Closed Complete'
        Set<JBCXM__CTA__c> ctaToUpdate = new Set<JBCXM__CTA__c>();
        for (JBCXM__CTA__c cta : callToActions) {
            for (Task t : tasks.values()) {
                if (cta.JBCXM__CreatedDate__c <= t.ActivityDate) {
                    cta.JBCXM__Stage__c = pickListValue.Id;
                    cta.JBCXM__Assignee__c = cta.JBCXM__Account__r.OwnerId;
                    ctaToUpdate.add(cta);
                }
            }
        }
        System.debug('Update CTA records: ' + ctaToUpdate);
        
        update new List<JBCXM__CTA__c>(ctaToUpdate);
    }

/*
    This trigger will fire when a Use Case get insert
    No special entry criteria, just fire it on insertion
    Query back the UseCase.Account related Tasks (From Account related Contacts)
    Get the most recent one Task.ActivityDate with Type = "Call" AND Activity Type = "Call" AND Status = "Completed".
    If we have this task, go to next step, if not, do nothing
    Query back all Account related Call To Action (API Name: JBCXM__CTA__c) with Status(API Name: JBCXM__Stage__r.Name) IN ['Open', 'Event - Open', 'Event - Working'] AND JBCXM__CreatedDate__c <= Task.ActivityDate
    Set all these Call To Action's Status to 'Event - Closed Complete' (**)
*/
    public static void setStatus(Map<Id,Use_Case__c> useCaseMap) {
        System.debug('Processing Use Cases: ' + useCaseMap.keySet());
        
        // Create a set of the Accounts related to the Use Cases
        Set<Id> accountIds = new Set<Id>();
        for (Use_Case__c uc : useCaseMap.values()) {
            accountIds.add(uc.Account__c);
        }

        // Create a list of Contacts related to the Account IDs
        Map<Id,Contact> contacts = new Map<Id,Contact>([
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ]);
        System.debug('Matching Contact IDs: ' + contacts.keySet());     

        Map<Id,Task> tasks = new Map<Id,Task>([
            SELECT Id, ActivityDate, WhoId
            FROM Task
            WHERE WhoId IN :contacts.keySet()
                AND Status = 'Completed'
                AND Type = 'Call'
                //AND Activity_Type_del__c = 'Call'
        ]);

        // If not Task records returned then no further processing required
        if (tasks.isEmpty()) return;

        // Get the latest ActivityDate for each Account
        Map<Id,Datetime> accountIdToMaxActivityDate = new Map<Id,Datetime>();
        for (Task t : tasks.values()) {
            Id accountId = contacts.get(t.WhoId).AccountId;
            if (accountIdToMaxActivityDate.containsKey(accountId)) {
                Datetime d = accountIdToMaxActivityDate.get(accountId);
                accountIdToMaxActivityDate.put(accountId, (t.ActivityDate > d) ? t.ActivityDate : d );
            } else {
                accountIdToMaxActivityDate.put(accountId, t.ActivityDate);
            }
        }
        
        // If no Account records found then no further processing required
        if (accountIdToMaxActivityDate.isEmpty()) return;
        
        // Query related Call To Action records by Task.Contact.Account that meet the criteria
        //    Call To Action Status (API Name: JBCXM__Stage__r.Name) IN ['Open', 'Event - Open', 'Event - Working']
        List<JBCXM__CTA__c> callToActions = [
            SELECT Id, JBCXM__Account__r.Id, JBCXM__Account__r.OwnerId, JBCXM__Stage__c, JBCXM__CreatedDate__c
            FROM JBCXM__CTA__c
            WHERE JBCXM__Account__r.Id IN :accountIdToMaxActivityDate.keySet()
            AND JBCXM__IsClosed__c = false
            AND JBCXM__Playbook__r.Name = 'New Managed Customer - No Email'
        ];

        // If not Call To Action records returned then no further processing required
        if (callToActions.isEmpty()) return;

        // Lookup up the 'Event - Closed Complete' picklist value so that it can be used to set
        // the Call To Action Status.
        JBCXM__PickList__c pickListValue;
        try {
            pickListValue = [ SELECT Id FROM JBCXM__PickList__c WHERE Name = :jbcxmPickListClosedLabel LIMIT 1];
        } catch (Exception e) {
            // If the picklist value is not found then report the error
            for (Use_Case__c u : useCaseMap.values()) {
                u.addError('Missing picklist value from JBCXM__PickList__c:  Needed \'' + jbcxmPickListClosedLabel + '\'');
            }
            return;
        }

        //  If JBCXM__CreatedDate__c <= Task.ActivityDate then set the Status on the Call To Action
        //  records to 'Event - Closed Complete'
        Set<JBCXM__CTA__c> ctaToUpdate = new Set<JBCXM__CTA__c>();
        for (JBCXM__CTA__c cta : callToActions) {
            for (Contact c : contacts.values()) {
                if (cta.JBCXM__Account__r.Id == c.AccountId && cta.JBCXM__CreatedDate__c <= accountIdToMaxActivityDate.get(c.AccountId)) {
                    cta.JBCXM__Stage__c = pickListValue.Id;
                    cta.JBCXM__Assignee__c = cta.JBCXM__Account__r.OwnerId;
                    ctaToUpdate.add(cta);
                }
            }
        }
        
        update new List<JBCXM__CTA__c>(ctaToUpdate);
    }
}