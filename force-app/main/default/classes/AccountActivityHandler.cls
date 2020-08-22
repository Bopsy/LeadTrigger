//----------------------------------------------------------------------------------------------------------
// Utility class AccountActivityHandler 
//----------------------------------------------------------------------------------------------------------
public without sharing class AccountActivityHandler {

    public static List<Account> getAccounts(Set<Id> accountIds) {
    	return [
            SELECT Id, Last_SDR_Activity_Lookup__c, (
                SELECT CreatedDate, OwnerId, Owner.IsActive, SDR_Assigned__c
                FROM OpenActivities
                WHERE Owner.UserRole.Name LIKE '%SDR%'
                OR Owner.UserRole.Name LIKE '%EMEA BDR%'
                OR Owner.UserRole.Name LIKE '%APAC BDR%'
                ORDER BY CreatedDate desc LIMIT 1
            ), (
                SELECT CreatedDate, OwnerId, Owner.IsActive, SDR_Assigned__c
                FROM ActivityHistories
                WHERE Owner.UserRole.Name LIKE '%SDR%'
                OR Owner.UserRole.Name LIKE '%EMEA BDR%'
                OR Owner.UserRole.Name LIKE '%APAC BDR%'
                ORDER BY CreatedDate desc LIMIT 1
            )
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    // Set Account.Last_SDR_Activity_Lookup__c with the Activity.Owner_ID__c when the most
    // recent Activity (Task or Event) record on the Account has Activity.SDR_Assigned__c = True.
    // If the most recent activity is not owned by an SDR (Activity.SDR_Assigned__c = False) then
    // leave value as is. 
    public static void setLastSDRActivity(Set<Id> accountIds) {
    	if (accountIds.isEmpty()) { return; }
        setLastSDRActivity(getAccounts(accountIds));
    }

    public static void setLastSDRActivity(List<Account> accounts) {
    	if (accounts.isEmpty()) { return; }

        List<Account> accountsToUpdate = new List<Account>();
        for (Account a : accounts) {
            Datetime d;
            Id oid;
            Boolean sdrAssigned = false;
            
            System.debug('Processing Account ' + a.Id);

            for (OpenActivity o : a.getSObjects('OpenActivities')) {
                System.debug('OPEN Account(' + a.Id + ') ActivityHistory(' + o.Id + ') CreatedDate(' + o.CreatedDate + ') SDR_Assigned__c(' + o.SDR_Assigned__c + ') OwnerId(' + o.OwnerId + ') Owner.IsActive(' + o.Owner.IsActive + ')');
                if (o.Owner.IsActive) {
                	d = o.CreatedDate;
                	oid = o.OwnerId;
                	sdrAssigned = o.SDR_Assigned__c;
                }
            }

            for (ActivityHistory h : a.getSObjects('ActivityHistories')) {
                if (h.Owner.IsActive && (d == null || h.CreatedDate > d)) {
                    System.debug('HISTORY Account(' + a.Id + ') ActivityHistory(' + h.Id + ') CreatedDate(' + h.CreatedDate + ') SDR_Assigned__c(' + h.SDR_Assigned__c + ') OwnerId(' + h.OwnerId + ') Owner.IsActive(' + h.Owner.IsActive + ')');
                    d = h.CreatedDate;
                    oid = h.OwnerId;
	                sdrAssigned = h.SDR_Assigned__c;
                }
            }

            if (d != null && oid != a.Last_SDR_Activity_Lookup__c && sdrAssigned != false) {
                System.debug('Updating Last_SDR_Activity_Lookup__c(' + oid + ') for Account(' + a.Id + ')');
                accountsToUpdate.add(new Account(Id = a.Id, Last_SDR_Activity_Lookup__c = oid));
            }
        }
        
        update accountsToUpdate;
    }
}