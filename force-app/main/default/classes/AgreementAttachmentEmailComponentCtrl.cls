public class AgreementAttachmentEmailComponentCtrl {

    public Id agreementId {get; set;}
    public Id agreementAttachmentId {get; set;}
    public Apttus__APTS_Agreement__c agreementObject {
        get{
            if(agreementObject == null){
                agreementObject = [SELECT Name, Total_Committed_Revenue__c, Commit_Frequency__c, Account_SIDs__c, Payment_Type__c, Prepay_Frequency__c FROM Apttus__APTS_Agreement__c WHERE Id =: agreementId];
            }
            return agreementObject;
        }
        set;
        
    }
    
    public List<Single_BI_Discount__c> needApprovalBIs {
        get{
            if(needApprovalBIs == null){
                List<Exception_BI__c> exceptionBIs = [SELECT Single_BI_Discount__c FROM Exception_BI__c WHERE Agreement_Attachment__c =: agreementAttachmentId];
                Set<Id> biIds = new Set<Id>();
                for(Exception_BI__c bi: exceptionBIs){
                    biIds.add(bi.Single_BI_Discount__c);
                }
                needApprovalBIs = [SELECT Tier_Approval__c, Billable_Item_Name__c, Discount_Type__c, Flat_Price__c, Percent_Off__c, Product_Family__c, Product_Group__c, Root_Price__c FROM Single_BI_Discount__c	WHERE Id =: biIds];
            }
            return needApprovalBIs;
        }
        set;
    }
    
    public Agreement_Attachment__c obj {
        get{
            if (obj == null){
                String queryString = 'SELECT Name';
                for(Agreement_Attachment_Mapping__c fieldMap: Agreement_Attachment_Mapping__c.getAll().values()){
                    queryString += ', ' + fieldMap.Attachment_Field_Name__c;
                }
                queryString += ' FROM Agreement_Attachment__c WHERE Id =: agreementAttachmentId';
                obj = (Agreement_Attachment__c) Database.query(queryString);
            }
            return obj;
        }
        set;
    }
}