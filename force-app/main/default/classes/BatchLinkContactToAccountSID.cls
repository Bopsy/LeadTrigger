/** * * * * * * * * * * * *
 * 
 *  Class Name:   BatchLinkContactToAccountSID
 *  Purpose:      This class link Contact with AccountSid object's records.
 *                OwnerUser_Email_Address__c field on AccountSid object is used to Link Contact. 
 *  Author:       Ashwani Soni
 *  Company:      GoNimbly, Ian and Zack
 *  Created Date: 12-Nov-2015
 *  Changes:      31-December-2015 : Made the class schedulable, Ashwani
 				  09-February-2016 : Logic changed completely as per new specification in "Twilio Multi-User Code Update Project v2.1", Ashwani
				  25-February-2016 : Logic changed completely as per new specification in "Twilio Multi-User Code Update Project v2.1",
                                     Do not overwrite Account on Account Sid. by Ashwani
 *  Type:         Batch class
 *
** * * * * * * * * * * * */

public with sharing class BatchLinkContactToAccountSID implements Database.Batchable<sObject>, Schedulable
{
    
    public String query;
    
    // Default Constructor         
    public BatchLinkContactToAccountSID()
    {
    	query = 'SELECT '+
                        'Id, '+
                        'Email, '+
                        'Accountid, '+
                        'LastModifiedDate, '+
                        'OwnerUser_SID__c '+
                'FROM Contact '+
                'WHERE Email != null '+
                'Order by LastModifiedDate ASC';
    }
    
    // Batch method
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        return Database.getQueryLocator(this.query);        
    }
    
    // Batch Method
    // Populate Contact and Account to AccountSid. Only in case if there if Contact__c is null
    // or if there are duplicate most recent contact will be linked.
    public void execute(Database.BatchableContext info, List<sObject> scope) 
    {
    	// Map Contact with Contact's email
        Map<String,Contact> emailWithContact = new Map<String,Contact>();
        
        for(contact con : (List<contact>)scope)
        {
            emailWithContact.put(con.email,con);
        }
        
        List<Account_SID__c> accountSIDList = new List<Account_SID__c>();
        Map<Id,Contact> conToUpdate = new Map<Id,Contact>();
        
        // Get mappings from custom setting
        List<Account_Sid_Mapping__c> asidMapping = [SELECT Object_API_Name__c, Source_Field_API_Name__c, Target_Field_API_Name__c
        											FROM Account_Sid_Mapping__c
        											WHERE Object_API_Name__c = 'Contact'];
        
        // Collect all email addresses
        Set<String> emailAddresses = emailWithContact.keyset();
        
        // Query AccountSid records via collected email address
        // Is uses custome setting to query desired numner of fields.
        for(Account_SID__c aSID : Database.query('SELECT '+buildQuery(asidMapping)+
        						   				 ' FROM Account_SID__c '+
        						   				 ' WHERE OwnerUser_Email_Address__c IN:emailAddresses '+
        						   				 ' ORDER BY Contact__r.LastModifiedDate ASC') )
        {
        	// OwnerUser_Email_Address__c should not be empty in this case
        	String ownerUserToLowerCase = aSID.OwnerUser_Email_Address__c.toLowerCase();
            if(emailWithContact.containskey(ownerUserToLowerCase))
            {
            	Contact matchingContact = emailWithContact.get(ownerUserToLowerCase);
            	
            	// Case #1 when Account/Contact is null. It is ok if Contact has no Account.
                if(aSID.Contact__c == null || aSID.Account__c == null)
	            {   
	                aSID.Contact__c = matchingContact.id;
	                aSID.Account__c = aSID.Account__c == null ? matchingContact.AccountId : aSID.Account__c;
	                accountSIDList.add(aSID);
	            }
	            //Case #2 Contact exist in record. And matching records is newer than existing contact id. Relpace the lookup field od Contact and Account
	            else if(aSID.Contact__c != null && 
	            		( aSID.Contact__r.LastModifiedDate <= matchingContact.LastmodifiedDate) ||
	            		aSID.Contact__r.Email != matchingContact.Email)
	            {
	            	// Overwrite the contact. Asid.Account would be filled otherwise it makes the Case #1
	            	aSID.Contact__c = matchingContact.id;
	                accountSIDList.add(aSID);
	            }
	            
	            // Update fields in Account_Sid_Mapping__c setting into contact by matching the Id of both Accountsid Contact and matching Contact 
	            if(aSID.Contact__c == matchingContact.id)
	            {
	            	for(Account_Sid_Mapping__c asm : asidMapping)
	            	{
		            	if(matchingContact.get(asm.Target_Field_API_Name__c) == null)
		            	{
			            	matchingContact.put(asm.Target_Field_API_Name__c,aSID.get(asm.Source_Field_API_Name__c));
			            	conToUpdate.put(matchingContact.id,matchingContact);
		            	}
	            	}
	            }
            }
        }
        
        // Update Account Sid
        update accountSIDList;
        
        // Update populated values from their Account Sid
        update conToUpdate.values();
    }
    
    public void finish(Database.BatchableContext bc)
    {
    	// Get the ID of the AsyncApexJob representing this batch job
	    // from Database.BatchableContext.
	    // Query the AsyncApexJob object to retrieve the current job's information.
	    AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, ExtendedStatus,
	                             TotalJobItems
	                      FROM AsyncApexJob 
	                      WHERE Id = :BC.getJobId()];
	                
	    if(a.NumberOfErrors > 0)
	    {           
	      // Send an email to the Apex job's submitter notifying of job has error.
	      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	      String[] toAddresses = new String[] {System.Label.Batch_Default_Email};
	      mail.setToAddresses(toAddresses);
	      mail.setSubject('Batch Link Contact To AccountSID ' + a.Status);
	      mail.setPlainTextBody
	         ('The batch Apex job processed ' + a.TotalJobItems +
	         ' batche(s) with '+ a.NumberOfErrors + 
	         ' failures.\n\nError Description:\n '+a.ExtendedStatus);
	         
	      try
	      {  
	      		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	      }
	      catch(Exception ex)
	      {
	        	System.debug(' WARNING: Email could not be sent by CM batch due to following error: '+ex.getMessage());
	      }
	    }
    }
    
    // Schedulable Interface Method
    public void execute(SchedulableContext context)
    {
        BatchLinkContactToAccountSID bat = new BatchLinkContactToAccountSID(); 
        database.executebatch(bat);
    }
    
    /*******
	 *  Build a query using name oif fields
	 *  @param: Account_Sid_Mapping__c for Contact type fields.
	 *  @return String of fields conceneated with ',''
	*******/
    private String buildQuery(List<Account_Sid_Mapping__c> asidMapping)
    {
    	Set<String> asidFields = new Set<String>{'id',
    											 'OwnerUser_SID__c',
    											 'Contact__c',
    											 'Contact__r.LastModifiedDate',
    											 'Contact__r.Email',
    											 'Account__c',
    											 'OwnerUser_Email_Address__c'
    											 };
    											 
  		for(Account_Sid_Mapping__c asm : asidMapping)
  		{
  			asidFields.add(asm.Source_Field_API_Name__c);
  		}
    	return String.join(new List<String>(asidFields),', ');
    }
    
    
    
}