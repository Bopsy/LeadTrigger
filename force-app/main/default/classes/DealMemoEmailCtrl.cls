public class DealMemoEmailCtrl {
    public Id dealMemoId {get; set;}
    
    public Deal_Memo__c relatedTo {
        get{
            if(relatedTo == null){
                relatedTo = [SELECT Name, Opportunity__r.Name, Opportunity__r.CloseDate, Opportunity__r.eARR_post_Launch__c, Total_Percent_Attributed__c, 
                                    Deal_Memo_Attribution_Type__c, Sales_Ops_Notes__c
                             FROM Deal_Memo__c
                             WHERE Id = :dealMemoId];
            }
            return relatedTo;
        }
        set;
    }
    public List<Deal_Memo_Recipient__c> recipients{
        get{
            if(recipients == null){
                recipients = [SELECT Deal_Memo_Recipient__r.Name, Percent_Attributed__c FROM Deal_Memo_Recipient__c WHERE Deal_Memo__c = :dealMemoId];
            }
            return recipients;
        }
        set;
    }
}