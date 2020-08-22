/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           SingleBITierTrigger
*
* @description    Trigger code on Single BI tier object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-01-29
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
trigger SingleBITierTrigger on Single_BI_Tier__c (after insert, after update, after delete, after undelete, before insert, before update) {
    
    List<Single_BI_Tier__c> lstSingleTier = new List<Single_BI_Tier__c>();
    Set<Id> setAgreementIds = new Set<Id>();
    
    if(Trigger.isBefore && Trigger.isInsert){
        for(Single_BI_Tier__c objSingleTier: Trigger.new){
            if(objSingleTier.Product_Group__c == 'Flex' && objSingleTier.Last_Additional_Schedule__c==false && objSingleTier.Discount_Rate_Start_Date__c!=null){
                lstSingleTier.add(objSingleTier);
                setAgreementIds.add(objSingleTier.Agreement__c);
            }
        }
        if(lstSingleTier.size()>0){
            //Call method to calculate flex duration on insert
            SingleBITierTriggerHandler.updateFlexTierDuration(lstSingleTier,setAgreementIds,false);
        }
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
        for(Single_BI_Tier__c objSingleTier: Trigger.new){
            if(objSingleTier.Product_Group__c == 'Flex' && 
               (Trigger.oldMap.get(objSingleTier.id).Discount_Rate_Start_Date__c != Trigger.newMap.get(objSingleTier.id).Discount_Rate_Start_Date__c ||
                Trigger.oldMap.get(objSingleTier.id).Discount_Rate_End_Date__c != Trigger.newMap.get(objSingleTier.id).Discount_Rate_End_Date__c ||
                Trigger.oldMap.get(objSingleTier.id).Last_Additional_Schedule__c != Trigger.newMap.get(objSingleTier.id).Last_Additional_Schedule__c)){
                    lstSingleTier.add(objSingleTier);
                    setAgreementIds.add(objSingleTier.Agreement__c);
                }
        }
        if(lstSingleTier.size()>0){
            //Call method to calculate flex duration on insert
            SingleBITierTriggerHandler.updateFlexTierDuration(lstSingleTier,setAgreementIds,false);
        }
    }
    
    Set<Id> lstSingleDiscountIds= new Set<Id>();
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUndelete || Trigger.isDelete)){
        for(Single_BI_Tier__c objSingleTier: Trigger.isDelete ? Trigger.old : Trigger.new){
            if(objSingleTier.Product_Group__c == 'Flex' && objSingleTier.Last_Additional_Schedule__c==false){
                lstSingleDiscountIds.add(objSingleTier.Single_BI_Discount__c);
            }
            if(objSingleTier.Product_Group__c == 'Flex' && objSingleTier.Last_Additional_Schedule__c==false && objSingleTier.Discount_Rate_Start_Date__c!=null){
                setAgreementIds.add(objSingleTier.Agreement__c);
            }
        }
        if(lstSingleDiscountIds.size()>0){
            //Call method to total flex commit
            SingleBITierTriggerHandler.updateSingleBIDiscount(lstSingleDiscountIds);
        }
        List<Apttus__APTS_Agreement__c> lstAgreementWithTier = [Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                Term_Range__c,(Select Id,Discount_Rate_Start_Date__c,Discount_Rate_End_Date__c,Flex_Tier_Total__c, Flex_Tier_Duration__c, 
                                                                               Flat_Price__c ,Monthly_Units_Purchased__c from Single_BI_Tiers__r where Last_Additional_Schedule__c=false and Product_Group__c='Flex'
                                                                               order by Discount_Rate_Start_Date__c) 
                                                                from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null or Apttus__Contract_End_Date__c!=null)
                                                        		and Term_Range__c!=null and Apttus__Status__c='Activated'
                                                                and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                and Id IN: setAgreementIds];
        if(lstAgreementWithTier.size()>0){
            SingleBITierTriggerHandler.updateOpportunities(lstAgreementWithTier);
        }
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        for(Single_BI_Tier__c objSingleTier: Trigger.new){
            if(objSingleTier.Product_Group__c == 'Flex' && 
               (Trigger.oldMap.get(objSingleTier.Id).Monthly_Units_Purchased__c != Trigger.newMap.get(objSingleTier.Id).Monthly_Units_Purchased__c || 
                Trigger.oldMap.get(objSingleTier.Id).Flat_Price__c != Trigger.newMap.get(objSingleTier.Id).Flat_Price__c || 
                Trigger.oldMap.get(objSingleTier.Id).Flex_Tier_Duration__c  != Trigger.newMap.get(objSingleTier.Id).Flex_Tier_Duration__c)){
                    lstSingleDiscountIds.add(objSingleTier.Single_BI_Discount__c);
                }
            if(objSingleTier.Product_Group__c == 'Flex' && 
               (Trigger.oldMap.get(objSingleTier.id).Discount_Rate_Start_Date__c != Trigger.newMap.get(objSingleTier.id).Discount_Rate_Start_Date__c ||
                Trigger.oldMap.get(objSingleTier.id).Discount_Rate_End_Date__c != Trigger.newMap.get(objSingleTier.id).Discount_Rate_End_Date__c ||
                Trigger.oldMap.get(objSingleTier.id).Last_Additional_Schedule__c != Trigger.newMap.get(objSingleTier.id).Last_Additional_Schedule__c)){
                    setAgreementIds.add(objSingleTier.Agreement__c);
                }
        }
        if(lstSingleDiscountIds.size()>0){
            //Call method to total flex commit
            SingleBITierTriggerHandler.updateSingleBIDiscount(lstSingleDiscountIds);
        }
        List<Apttus__APTS_Agreement__c> lstAgreementWithTier = [Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                Term_Range__c,(Select Id,Discount_Rate_Start_Date__c,Discount_Rate_End_Date__c,Flex_Tier_Total__c, Flex_Tier_Duration__c, 
                                                                               Flat_Price__c ,Monthly_Units_Purchased__c from Single_BI_Tiers__r where Last_Additional_Schedule__c=false and Product_Group__c='Flex'
                                                                               order by Discount_Rate_Start_Date__c) 
                                                                from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null or Apttus__Contract_End_Date__c!=null)
                                                        		and Term_Range__c!=null and Apttus__Status__c='Activated'
                                                                and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                and Id IN: setAgreementIds];
        if(lstAgreementWithTier.size()>0){
            SingleBITierTriggerHandler.updateOpportunities(lstAgreementWithTier);
        }
    }
}