global class BatchRollupTwilioOrgCampaignMember implements Database.Batchable<SObject>, Schedulable{
    
    public class MemberStatus{
        public Integer acceptNumber {get; set;}
        public Integer applyNumber {get; set;}
        public Integer pendingNumber {get; set;}
        public Integer reapplyNumber {get; set;}
        public Integer rejectNumber {get; set;}
        
        public MemberStatus(Integer acceptNumber, Integer applyNumber, Integer pendingNumber, Integer reapplyNumber, Integer rejectNumber){
            this.acceptNumber = acceptNumber;
            this.applyNumber = applyNumber;
            this.pendingNumber = pendingNumber;
            this.reapplyNumber = reapplyNumber;
            this.rejectNumber = rejectNumber;
        }
        
        public Account setAccountFields(Id accountId){
            return new Account(Id = accountId, 
                               Twilio_org_Member_Accepted__c = this.acceptNumber,
                               Twilio_org_Member_Applied__c = this.applyNumber,
                               Twilio_org_Member_Pending__c = this.pendingNumber,
                               Twilio_org_Member_Re_applied__c = this.reapplyNumber,
                               Twilio_org_Member_Rejected__c = this.rejectNumber
                              );
        }
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRollupTwilioOrgCampaignMember());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id FROM Campaign WHERE Name = 'twilio.org']);
    }
    
    global void execute(Database.BatchableContext bc, List<Campaign> campaigns){
        Map<Id, MemberStatus> accountToStatusMap = new Map<Id, MemberStatus>();
        
        List<CampaignMember> members = [SELECT Contact.AccountId, Status FROM CampaignMember WHERE Type = 'Contact' AND CampaignId = :campaigns];

        if(members != null && !members.isEmpty()){
            for(CampaignMember member: members){
                MemberStatus status = accountToStatusMap.get(member.Contact.AccountId);
                if(status == null){
                    status = new MemberStatus(0, 0, 0, 0, 0);
                }
                if(member.Status == 'Accepted'){
                    status.acceptNumber++;
                }
                else if(member.Status == 'Applied'){
                    status.applyNumber++;
                }
                else if(member.Status == 'Pending'){
                    status.pendingNumber++;
                }
                else if(member.Status == 'Re-applied'){
                    status.reapplyNumber++;
                }
                else if(member.Status == 'Rejected'){
                    status.rejectNumber++;
                }
                accountToStatusMap.put(member.Contact.AccountId, status);
            }
        }
        
        List<Account> updateAccounts = new List<Account>();
        
        for(Id accountId: accountToStatusMap.keySet()){
            updateAccounts.add(accountToStatusMap.get(accountId).setAccountFields(accountId));
        }
        
        Database.update(updateAccounts, false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}