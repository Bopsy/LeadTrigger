public with sharing class BillableItemPickerCtrl {
    public class ErrorException extends Exception{}
    public class BillableItemWrapper{
        public string Name;
        public string Country;
        public String Region;
        public String productFamily;
        public string GroupName;
        public Decimal listPrice;
        public Decimal discount;
        public Decimal percent;
        public Boolean percentDiscount;
        public String id;
    }
    
    public class GroupItemWrapper{
        public string Name;
        public string productFamily;
        public String id;
    }
    
    public String getGroups(){
        List<GTM_Grouping__c> groups = [SELECT Name__c, Product_Family__c FROM GTM_Grouping__c WHERE Status__c = 'Active' ORDER BY Name__c];
        List<GroupItemWrapper> wrappers = new List<GroupItemWrapper>();
        for(GTM_Grouping__c aGroup: groups){
            GroupItemWrapper newWrapper = new GroupItemWrapper();
            newWrapper.Name = aGroup.Name__c;
            newWrapper.productFamily = aGroup.Product_Family__c;
            newWrapper.Id = aGroup.Id;
            wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    public Apttus__APTS_Agreement__c agreement {get; set;}
    public List<Single_BI_Discount__c> existingDiscounts {get; set;}
    public BillableItemPickerCtrl(ApexPages.standardController stdCtrl){
        agreement = [SELECT Average_Monthly_Committed_Revenue__c FROM Apttus__APTS_Agreement__c WHERE Id=:stdCtrl.getRecord().Id];
        existingDiscounts = [SELECT Agreement__c, Billable_Item__r.Name, Billable_Item__r.Product_Family__c, Billable_Item__c,  Billable_Item__r.Territory__c, Billable_Item__r.Region__c, Billable_Item__r.Price__c, Discount_Type__c, Flat_Price__c, Percent_Off__c, GTM_Group__r.Name FROM Single_BI_Discount__c WHERE Agreement__c =:agreement.Id ORDER BY Billable_Item__r.Product_Family__c];
    }
    
    @RemoteAction
    public static void saveData(String dataString, String agreementId, String accountSIDs){
        List<Single_BI_Discount__c> oldDiscounts = [SELECT Id FROM Single_BI_Discount__c WHERE Agreement__c =: agreementId];
        List<Single_BI_Discount__c> discounts = (List<Single_BI_Discount__c>) JSON.deserialize(dataString, List<Single_BI_Discount__c>.class);
        Apttus__APTS_Agreement__c updateAgreement = new Apttus__APTS_Agreement__c(Id = agreementId, Account_SIDs__c = accountSIDs);
        Savepoint sp = Database.setSavepoint();
        try{
            delete oldDiscounts;
            insert discounts;
            update updateAgreement;
        }
        catch(DMLException e){
            Database.rollback(sp);
            throw new ErrorException(e.getMessage());
        }
    }
    
    public String getExistingItems(){
        List<BillableItemWrapper> wrappers = new List<BillableItemWrapper>();
        for(Single_BI_Discount__c discount: existingDiscounts){
           BillableItemWrapper newWrapper = new BillableItemWrapper(); 
           newWrapper.Id = discount.Billable_Item__c;
           newWrapper.Name = discount.Billable_Item__r.Name;
           newWrapper.Country = discount.Billable_Item__r.Territory__c;
           newWrapper.Region = discount.Billable_Item__r.Region__c;
           newWrapper.productFamily = discount.Billable_Item__r.Product_Family__c;
           newWrapper.listPrice = discount.Billable_Item__r.Price__c;
           newWrapper.percentDiscount = discount.Discount_Type__c == 'Percent';
           if(discount.GTM_Group__r.Name != null)
                newWrapper.groupName = discount.GTM_Group__r.Name;
           else
                newWrapper.groupName = 'NO GROUP';
           newWrapper.discount = discount.Flat_Price__c;
           newWrapper.percent = discount.Percent_Off__c;
           wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    
    public String getBillableItems(){
        String queryString = 'SELECT Name, Product_Family__c, Territory__c, Discount_Type__c, Region__c, Product__c, Price__c, (SELECT GTM_Group__r.Name__c FROM GTM_Group_Billable_Items__r)';
        List<String> discountFields = new List<String>();
        Integer startIndex = 0;
        discountFields.add('X50kFlatPrice__c');
        discountFields.add('X50kPercentOff__c');
        discountFields.add('X25kFlatPrice__c');
        discountFields.add('X25kPercentOff__c');
        discountFields.add('X10kFlatPrice__c');
        discountFields.add('X10kPercentOff__c');
        discountFields.add('X5kFlatPrice__c');
        discountFields.add('X5kPercentOff__c');
        discountFields.add('X1kFlatPrice__c');
        discountFields.add('X1kPercentOff__c');
        queryString += ', X50kFlatPrice__c, X50kPercentOff__c';
        queryString += ', X25kFlatPrice__c, X25kPercentOff__c';
        queryString += ', X10kFlatPrice__c, X10kPercentOff__c';
        queryString += ', X5kFlatPrice__c, X5kPercentOff__c';
        queryString += ', X1kFlatPrice__c, X1kPercentOff__c';
        
        if(agreement.Average_Monthly_Committed_Revenue__c >= 50000){
            startIndex = 0;
        }
        else if(agreement.Average_Monthly_Committed_Revenue__c >= 25000) {
            startIndex = 2;
        }
        else if(agreement.Average_Monthly_Committed_Revenue__c >= 10000) {
            startIndex = 4;
            
        }
        else if(agreement.Average_Monthly_Committed_Revenue__c >= 5000) {
            startIndex = 6;
            
        }
        else if(agreement.Average_Monthly_Committed_Revenue__c >= 1000) {
            startIndex = 8;
            
        }
        queryString += ' FROM Billable_Item__c WHERE Product_Family__c != null AND Status__c = \'ACTIVE\' ORDER BY Name';
        
        List<Billable_Item__c> items = (List<Billable_Item__c>) Database.query(queryString);
        List<BillableItemWrapper> wrappers = new List<BillableItemWrapper>();
        
        for(Billable_Item__c item: items){
            BillableItemWrapper newWrapper = new BillableItemWrapper();
            newWrapper.Id = item.Id;
            newWrapper.Name = item.Name;
            newWrapper.Country = item.Territory__c;
            newWrapper.Region = item.Region__c;
            newWrapper.productFamily = item.Product_Family__c;
            if(item.GTM_Group_Billable_Items__r != null && !item.GTM_Group_Billable_Items__r.isEmpty() && item.GTM_Group_Billable_Items__r[0].GTM_Group__r.Name__c != null){
                newWrapper.GroupName = item.GTM_Group_Billable_Items__r[0].GTM_Group__r.Name__c;
            }
            else{
                newWrapper.GroupName = 'NO GROUP';
            }
            newWrapper.listPrice = item.Price__c;
            newWrapper.percentDiscount = item.Discount_Type__c == 'Percent';
            if(agreement.Average_Monthly_Committed_Revenue__c == null || agreement.Average_Monthly_Committed_Revenue__c < 1000){
                newWrapper.discount = item.Price__c;
                newWrapper.percent = 0;
            }
            else{
                for(Integer i = startIndex; i < discountFields.size(); i += 2){
                    newWrapper.discount = (Decimal) item.get(discountFields[i]);
                    newWrapper.percent = (Decimal) item.get(discountFields[i+1]);
                    if(newWrapper.percent != null || newWrapper.discount != null) break;
                }
                if(newWrapper.discount == null && newWrapper.percent != null){
                    newWrapper.discount = newWrapper.percent * item.Price__c / 100;
                }
                else if(item.Price__c == 0){
                    newWrapper.percent = 0;
                    newWrapper.discount = 0;
                }
                else if(newWrapper.discount != null && newWrapper.percent == null){
                    newWrapper.percent = newWrapper.discount / item.Price__c * 100;
                }
                if(newWrapper.discount == null && newWrapper.percent == null){
                    newWrapper.discount = item.Price__c;
                    newWrapper.percent = 0;
                }
            }
            wrappers.add(newWrapper);
        }
        return JSON.serialize(wrappers);
    }
    
}