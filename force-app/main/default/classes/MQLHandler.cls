public with sharing class MQLHandler {

    // This method the MQL (FSR__c) records to their corresponding Short_Code__c records
    // by email address.
    public static void linkShortCodesByLeadOrContact(List<FSR__c> mqlRecords) {

        // If no short codes to process the nothing to do
        if (!mqlRecords.isEmpty()) {
    
            Map<Id,Id> leads = new Map<Id,Id>();
            Map<Id,Id> contacts = new Map<Id,Id>();
            for (FSR__c mql : mqlRecords) {
                if (mql.Contact__c != null) {
                    contacts.put(mql.Contact__c, mql.Id);
                    //System.debug('MQLHandler.linkShortCodesByLeadOrContact(): Mapping Contact(' + mql.Contact__c + ') to FSR__c/MQL(' + mql.Id + ')');
                } else if(mql.Lead__c != null){
                    leads.put(mql.Lead__c, mql.Id);
                    //System.debug('MQLHandler.linkShortCodesByLeadOrContact(): Mapping Lead(' + mql.Lead__c + ') to FSR__c/MQL(' + mql.Id + ')');
                }
            }
            
            // Query the Short Codes by Contact and Lead and push MQL Id to record it there is a match
            List<Short_Code__c> shortCodesToUpdate = new List<Short_Code__c>();
            for (Short_Code__c sc : [
                SELECT Id, Contact__c, Lead__c, MQL__c
                FROM Short_Code__c
                WHERE Contact__c IN :contacts.keySet()
                OR Lead__c IN :leads.keySet()
                LIMIT 50000
            ]) {
                if (contacts.containsKey(sc.Contact__c)) {
                    sc.MQL__c = contacts.get(sc.Contact__c);
                    shortCodesToUpdate.add(sc);
                    //System.debug('MQLHandler.linkShortCodesByLeadOrContact(): Linking by Contact(' + sc.Contact__c + ') - Short_Code__c(' + sc.Id + ') to FSR__c/MQL(' + sc.MQL__c + ')');
                } else if (leads.containsKey(sc.Lead__c)) {
                    sc.MQL__c = leads.get(sc.Lead__c);
                    shortCodesToUpdate.add(sc);
                    //System.debug('MQLHandler.linkShortCodesByLeadOrContact(): Linking by Lead('+ sc.Lead__c + ') - Short_Code__c(' + sc.Id + ') to FSR__c/MQL(' + sc.MQL__c + ')');
                }
            }
            if(!shortCodesToUpdate.isEmpty()){
                update shortCodesToUpdate;
            }
        }
    }

    // When an MQL, which has a Short Code Application, is set to "Rejected" with one of the following reasons,
    // set the related Short Code Application to “Archive”:
    //     Incomplete Record/Email Bounce
    //     No Response
    //     Fraud
    //     Does not want to talk/Unsubscribed
    //     No Clear Project
    // If the MQL is only related to a Lead, no further action needed.
    // If the MQL is related to a Contact, notify the Contact's Account Owner of MQL/Short Code Application being rejected.
    public static void archiveShortCode(List<FSR__c> mqlRecords) {
        /*Set<String> reasonsToNotifyOwner = new Set<String> {
            'Incomplete Record/Email Bounce',
            'No Response',
            'Fraud',
            'Does not want to talk/Unsubscribed',
            'No Clear Project'
        };
        

        List<FSR__c> notifyOfArchive = new List<FSR__c>();
        Set<Id> mqlIds = new Set<Id>();
        for (FSR__c mql : mqlRecords) {
            if (mql.MQL_Status__c == '3 - Rejected' && reasonsToNotifyOwner.contains(mql.Rejected_Reason__c)) {
                mqlIds.add(mql.Id);
                
                if (mql.Contact__c != null) {
                    notifyOfArchive.add(mql);
                }
            }
        }
        
        if(notifyOfArchive.isEmpty()) return;
        
        List<Short_Code__c> shortCodes = new List<Short_Code__c>();
        for (Short_Code__c s : [
            SELECT Id, Status__c
            FROM Short_Code__c
            WHERE MQL__c IN :mqlIds
            LIMIT 50000
        ]) {
            shortCodes.add(new Short_Code__c(Id = s.Id, Status__c = 'Archived'));
        }
        update shortCodes;
        
        if (!notifyOfArchive.isEmpty()) {
            sendEmailNotificationOfArchive(notifyOfArchive);
        }*/
    }

    public static void sendEmailNotificationOfArchive(List<FSR__c> mqlList) {
        // Configurable variables
        /*String emailFromDisplayName = 'MQL Rejected';

        // Determine if this is running in a sandbox and setting variables accordingly
        Organization org = [ SELECT Id, IsSandbox FROM Organization LIMIT 1];
        String orgURL     = org.IsSandbox ? 'https://test.salesforce.com' : 'https://twlo.my.salesforce.com';
        String emailFrom  = org.IsSandbox ? 'jonathan.f.griggs@gmail.com' : 'sc@twilio.com';

        List<FSR__c> mqls = [ SELECT Id, Name, Contact__r.Account.OwnerId FROM FSR__c WHERE Id IN :mqlList LIMIT 50000];

        // Setup a email message list for email notifications
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        
        for (FSR__c mql : mqls) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String emailSubject = 'MQL Rejected Notification: ' + mql.Name;
            String emailMessage = 'MQL Rejected: ' + mql.Name + ' (' + mql.Id + ')';

            email.setTargetObjectId(mql.Contact__r.Account.OwnerId);
            email.setReplyTo(emailFrom);
            email.setSenderDisplayName(emailFromDisplayName); 
            email.saveAsActivity = false;
            email.setSubject(emailSubject);
            email.setPlainTextBody(emailMessage);
            mailList.add(email);
        }

        // Send out the email notifications in the mail list
        System.debug('Sending email notifications');
        if (!mailList.isEmpty() || Test.isRunningTest()) {
            System.debug('SENDING EMAIL');
            //Messaging.sendEmail(mailList);
        }*/
    }
}