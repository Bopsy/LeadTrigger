/** * * * * * * * * * * * *
 *
 *  Class Name:   BatchLinkLeadToAccountSID
 *  Purpose:      This class link Lead with AccountSid object's records.
 *                OwnerUser_Email_Address__c field on AccountSid object is used to link Lead. On Lead Email field is used for match
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly
 *  Created Date: 11-Feb-2016
 *  Changes:      none
 *  Type:         Batch class
 *
** * * * * * * * * * * * */

public with sharing class BatchLinkLeadToAccountSID implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    public String query;
    public List<String> errors;

    public BatchLinkLeadToAccountSID()
    {
        query = 'SELECT Id, Email, OwnerUser_SID__c, LastModifiedDate' +
                ' FROM Lead' +
                ' WHERE Email != NULL AND IsConverted = FALSE' +
                ' ORDER BY LastModifiedDate ASC';
        this.errors = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext info, List<sObject> scope)
    {
        // although the features are unrelated, updating Leads may modify Opportunities,
        //  which may fire off future methods, so this flag is needed
        FieldSalesForecast.disableFuture = true;

        Map<Id,Lead> leadToUpdateMap = new Map<Id,Lead>();
        Map<String,Lead> emailWithLead = new Map<String,Lead>();

        for(Lead leadRecord : (List<Lead>)scope)
        {
            emailWithLead.put(leadRecord.email,leadRecord);
        }

        List<Account_Sid_Mapping__c> asidMapping = [SELECT Object_API_Name__c, Source_Field_API_Name__c, Target_Field_API_Name__c
        											FROM Account_Sid_Mapping__c
        											WHERE Object_API_Name__c = 'Lead'];

        Set<String> emailAddresses = emailWithLead.keyset();

        // Clear Lead__c field which have Email Id mismatch
        List<Account_SID__c> accountSIDClearList = new List<Account_SID__c>();
        List<Account_SID__c> matchingSIDs = [ SELECT Id, OwnerUser_Email_Address__c, Lead__r.Email
                                                FROM Account_SID__c
                                                WHERE Lead__r.Email IN :emailAddresses
                                                ORDER BY Lead__r.LastModifiedDate ASC ];
        for(Account_SID__c aSID : matchingSIDs )
        {
        	// OwnerUser_Email_Address__c should not be empty in this case
        	String ownerUserToLowerCase = aSID.OwnerUser_Email_Address__c.toLowerCase();
        	if(ownerUserToLowerCase != aSID.Lead__r.Email)
        	{
        		aSID.Lead__c = null;
        		accountSIDClearList.add(aSID);
        	}
        }

        List<Database.SaveResult> clearSIDUpdateResults = Database.update(accountSIDClearList, false);
        for(Integer index = 0; index < clearSIDUpdateResults.size(); index++ )
        {
            if(!clearSIDUpdateResults[index].isSuccess())
            {
                for(Database.Error anError : clearSIDUpdateResults[index].getErrors())
                {
                    this.errors.add(accountSIDClearList[index].Id + ': ' + anError.getMessage());
                }
            }
        }

        // Link matched AccountSids
        List<Account_SID__c> accountSIDList = new List<Account_SID__c>();
        for(Account_SID__c aSID : Database.query('SELECT '+buildQuery(asidMapping)+
        						   				 ' FROM Account_SID__c '+
        						   				 ' WHERE OwnerUser_Email_Address__c IN:emailAddresses'+
        						   				 ' ORDER BY Lead__r.LastModifiedDate ASC') )
        {
        	// OwnerUser_Email_Address__c should not be empty in this case
        	String ownerUserToLowerCase = aSID.OwnerUser_Email_Address__c.toLowerCase();
            if(emailWithLead.containskey(ownerUserToLowerCase))
            {
            	Lead matchingLead = emailWithLead.get(ownerUserToLowerCase);

                //Case 1: Match found
                if(aSID.Lead__c == null)
	            {
	                aSID.Lead__c = matchingLead.id;
	                accountSIDList.add(aSID);
	            }
                // Case 2: New match found
	            else if(aSID.Lead__c != null &&
                        (aSID.Lead__r.LastModifiedDate <= matchingLead.LastmodifiedDate ||
                        aSID.Lead__r.Email != matchingLead.Email) )
	            {
	            	aSID.Lead__c = matchingLead.id;
	            	accountSIDList.add(aSID);
	            }

	            if(aSID.Lead__c == matchingLead.id)
	            {
	            	for(Account_Sid_Mapping__c asm : asidMapping)
	            	{

		            	if(matchingLead.get(asm.Target_Field_API_Name__c) == null)
		            	{
			            	matchingLead.put(asm.Target_Field_API_Name__c,aSID.get(asm.Source_Field_API_Name__c));
		            	}
	            	}
	            	// prevent duplicate element in list
                    leadToUpdateMap.put(matchingLead.id,matchingLead);
	            }
            }
            else // Case 4: No match exist based on email
            {
            	aSID.Lead__c = null;
                accountSIDList.add(aSID);
            }
        }

        List<Database.SaveResult> accountSIDUpdateResults = Database.update(accountSIDList, false);
        for(Integer index = 0; index < accountSIDUpdateResults.size(); index++ )
        {
            if(!accountSIDUpdateResults[index].isSuccess())
            {
                for(Database.Error anError : accountSIDUpdateResults[index].getErrors())
                {
                    this.errors.add(accountSIDList[index].Id + ': ' + anError.getMessage());
                }
            }
        }

        List<Lead> leadsToUpdate = leadToUpdateMap.values();
        List<Database.SaveResult> leadUpdateResults = Database.update(leadsToUpdate, false);
        for(Integer index = 0; index < leadUpdateResults.size(); index++ )
        {
            if(!leadUpdateResults[index].isSuccess())
            {
                for(Database.Error anError : leadUpdateResults[index].getErrors())
                {
                    this.errors.add(leadsToUpdate[index].Id + ': ' + anError.getMessage());
                }
            }
        }

    }

    public void finish(Database.BatchableContext bc)
    {
        if(!this.errors.isEmpty())
        {
            // Get the ID of the AsyncApexJob representing this batch job
            // from Database.BatchableContext.
            // Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors,
                                    JobItemsProcessed, ExtendedStatus, TotalJobItems
                                FROM AsyncApexJob WHERE Id = :BC.getJobId()];
            // Send an email to the Apex job's submitter notifying of job has error.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {System.Label.Batch_Default_Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Batch Link Lead To AccountSID ' + a.Status);
            mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
                ' batch(es) with ' + a.NumberOfErrors +
                ' failures.\n\nError Description:\n ' + a.ExtendedStatus +
                ' \nErrors:\n' + String.join(this.errors, '\n'));

        	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	    }
    }

    // Schedulable Interface Method
    public void execute(SchedulableContext context)
    {
        BatchLinkLeadToAccountSID bat = new BatchLinkLeadToAccountSID();
        database.executebatch(bat);
    }

    /*
     * Used to populate addition field from Account Sid to Lead record
     *	@param: Account_Sid_Mapping__c custom setting records
     *	@return: field API name join by , (comma)
    **/
    private String buildQuery(List<Account_Sid_Mapping__c> asidMapping)
    {
    	// Defaul fields.
    	Set<String> asidFields = new Set<String>{'id',
    											 'OwnerUser_SID__c',
    											 'Lead__c',
    											 'Lead__r.LastModifiedDate',
            									 'Lead__r.Email',
    											 'OwnerUser_Email_Address__c'
    											 };

  		for(Account_Sid_Mapping__c asm : asidMapping)
  		{
  			asidFields.add(asm.Source_Field_API_Name__c);
  		}

  		return String.join(new List<String>(asidFields),', ');
    }

}