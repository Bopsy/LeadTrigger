/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           APTS_ProposalTriggerHandler
*
* @description    Service class that contains logic for APTS_ProposalTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-02-26
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class APTS_ProposalTriggerHandler {
    
    /***************************************************
        Added by Apttus Support
        Case: CAS-09701-F2Y8Y7
        Date: 15-03-2019
        Desc: To stop approval process to be fired based on the condition on TCR/Net unit price/color
    ****************************************************/
    public static void updateApprovalFields(List<Apttus_Proposal__Proposal__c> lstProposals, Map<Id,Apttus_Proposal__Proposal__c> oldMap){
        
        for(Apttus_Proposal__Proposal__c prObj : lstProposals){
                if(oldMap.get(prObj.Id).Apttus_QPApprov__Approval_Status__c != prObj.Apttus_QPApprov__Approval_Status__c && prObj.Apttus_QPApprov__Approval_Status__c=='Approved')
                    prObj.APTS_Original_Total_Committed_Revenue__c = prObj.Total_Committed_Revenue__c;
                
                if(prObj.Total_Committed_Revenue__c != oldMap.get(prObj.Id).Total_Committed_Revenue__c &&  prObj.Total_Committed_Revenue__c < prObj.APTS_Original_Total_Committed_Revenue__c)
                    prObj.APTS_TCR_Approval_Required__c = true;
                else
                    prObj.APTS_TCR_Approval_Required__c = false;
         }
         
    }
    
    public static void checkOnTotalHours(List<Apttus_Proposal__Proposal__c> lstProposals){
        if(lstProposals!=null){
            if(lstProposals.size()>0){
                for(Apttus_Proposal__Proposal__c objProposal: lstProposals){
                    objProposal.Total_Hours_to_Approve_Configuration__c = 0;
                }
            }
        }
    }
    
    public static void callGenerateStatus(List<Apttus_Proposal__Proposal__c> lstProposals, Map<Id,Apttus_Proposal__Proposal__c> oldMap,Map<Id,Apttus_Proposal__Proposal__c> newMap){
        Set<Id> setProposalIds = new Set<Id>();
        for(Apttus_Proposal__Proposal__c objProposal: lstProposals){
            if(oldMap.get(objProposal.Id).Total_Committed_Revenue__c != newMap.get(objProposal.Id).Total_Committed_Revenue__c ||
               oldMap.get(objProposal.Id).Term_Range__c != newMap.get(objProposal.Id).Term_Range__c){
                setProposalIds.add(objProposal.Id);
            }
        }
        if(setProposalIds.size()>0){
            Map<Id,Id> mapProposalWithConfig = new Map<Id,Id>();
            List<Apttus_Config2__ProductConfiguration__c> lstConfig = [Select Id,Apttus_QPConfig__Proposald__c from Apttus_Config2__ProductConfiguration__c 
                                                                       where Apttus_QPConfig__Proposald__c IN: setProposalIds order by LastModifieddate desc];
            for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfig){
                if(!mapProposalWithConfig.containsKey(objConfig.Apttus_QPConfig__Proposald__c)){
                    mapProposalWithConfig.put(objConfig.Apttus_QPConfig__Proposald__c,objConfig.Id);
                }else{
                    continue;
                }
            }
            List<Apttus_Config2__LineItem__c> lineItems = [Select Id,name,Apttus_Config2__OptionGroupLabel__c,BI_SID__c,
                                                           Apttus_Config2__OptionId__c,Apttus_Config2__ProductId__c,
                                                           Apttus_Config2__PricingGuidance__c,Percent_of_Spend__c,
                                                           Apttus_Config2__NetUnitPrice__c,Apttus_Config2__Guidance__c,
                                                           Apttus_Config2__AdjustmentType__c,Fixed_Discount_on_OF__c,
                                                           Apttus_Config2__Description__c, Deal_Guidance_Level_Formula__c,
                                                           Billing_Increment__c,Billing_Minute__c,Is_Bundle_Product__c,
                                                           Max_Flex_Quantity__c,Apttus_Config2__ChargeType__c,Bucket_Floor_Price__c,
                                                           Is_Bucket_Option__c,Total_SG_Email_Discount__c,Rule_Measure__c,
                                                           SG_Product_Type__c, Product_Family__c
                                                           from Apttus_Config2__LineItem__c
                                                           where Apttus_Config2__ConfigurationId__c IN: mapProposalWithConfig.values() and 
                                                           Is_Bucket_Option__c=false and Is_Bundle_Product__c=true];
            if(lineItems.size()>0){
                LineItemTriggerServices.generateDealGuidanceStatus(lineItems, true);
            }
        }
    }
    
    public static void onInsert(List<Apttus_Proposal__Proposal__c> lstProposals){
        Set<Id> setOppIds = new Set<Id>();
        for(Apttus_Proposal__Proposal__c objProposal: lstProposals){
            if(objProposal.Apttus_Proposal__Opportunity__c!=null){
                setOppIds.add(objProposal.Apttus_Proposal__Opportunity__c);
            }
        }
        if(setOppIds.size()>0){
            linkQuote(setOppIds);
        }
    }
    
    public static void onUpdate(Map<Id,Apttus_Proposal__Proposal__c> oldMap,List<Apttus_Proposal__Proposal__c> lstProposals){
        Set<Id> setOppIds = new Set<Id>();
        for(Apttus_Proposal__Proposal__c objProposal: lstProposals){
            if(objProposal.Apttus_Proposal__Opportunity__c!=null && objProposal.Apttus_Proposal__Opportunity__c!=oldMap.get(objProposal.id).Apttus_Proposal__Opportunity__c){
                setOppIds.add(objProposal.Apttus_Proposal__Opportunity__c);
                if(oldMap.get(objProposal.id).Apttus_Proposal__Opportunity__c!=null){
                    setOppIds.add(oldMap.get(objProposal.id).Apttus_Proposal__Opportunity__c);
                }
            }
        }
        if(setOppIds.size()>0){
            linkQuote(setOppIds);
        }
    }
    
    public static void linkQuote(Set<Id> setOppIds){
        Map<Id,Opportunity> mapOpp = new Map<Id,Opportunity>([Select Id,(Select Id,Apttus_QPApprov__Approval_Status__c from R00N70000001yUfDEAU order by lastmodifieddate desc)
                                                              from Opportunity where Id IN:setOppIds]);
        List<SendGrid_Price_Concession__c> lstSGPrice = [Select Id,Opportunity__c,Quote_Proposal__c from SendGrid_Price_Concession__c where 
                                                         Opportunity__c IN:setOppIds];
        if(lstSGPrice!=null && lstSGPrice.size()>0){
            for(SendGrid_Price_Concession__c objSGPrice: lstSGPrice){
                if(mapOpp.size()>0 && mapOpp.get(objSGPrice.Opportunity__c)!=null && mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU.size()>0){
                    objSGPrice.Quote_Proposal__c = mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU[0].Id;
                    for(Apttus_Proposal__Proposal__c objQuote: mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU){
                        if(objQuote.Apttus_QPApprov__Approval_Status__c=='Approved'){
                            objSGPrice.Quote_Proposal__c = objQuote.Id;
                            break;
                        }
                    }
                }else if(mapOpp.get(objSGPrice.Opportunity__c)==null || mapOpp.get(objSGPrice.Opportunity__c).R00N70000001yUfDEAU.size()==0){
                    objSGPrice.Quote_Proposal__c = null;
                }
            }
            update lstSGPrice;
        }
    }
    
    //built for tracking deals for customers driving COVID relief efforts. 
    //Logic is used to flag Contract Ops approval on the Agreement Attachment.
    public static void onUpdateQuote(Map<Id,Apttus_Proposal__Proposal__c> oldMap,Map<Id,Apttus_Proposal__Proposal__c> newMap){
        Set<Id> setIds = new Set<Id>();
        List<Apttus_Proposal__Proposal__c> lstProposals = new  List<Apttus_Proposal__Proposal__c>();
        lstProposals.addall(newMap.values());
        for(Apttus_Proposal__Proposal__c objProposal: lstProposals){
            if(objProposal.Applied_Commit_Discount__c!=oldMap.get(objProposal.id).Applied_Commit_Discount__c ||
               objProposal.Total_Committed_Revenue__c!=oldMap.get(objProposal.id).Total_Committed_Revenue__c){
                   setIds.add(objProposal.Id);
            }
        }
        List<Apttus__APTS_Agreement__c> lstAgreements = [Select id,Apttus_QPComply__RelatedProposalId__c ,Commit_Frequency__c  from Apttus__APTS_Agreement__c
                                                         where Apttus_QPComply__RelatedProposalId__c IN: setIds];
        if(lstAgreements!=null && lstAgreements.size()>0){
            for(Apttus__APTS_Agreement__c objAgr: lstAgreements){
                objAgr.X6th_tier_discount_with_TCR_0__c = false;
                if(newMap.get(objAgr.Apttus_QPComply__RelatedProposalId__c)!=null && newMap.get(objAgr.Apttus_QPComply__RelatedProposalId__c).Applied_Commit_Discount__c==100000
                   && newMap.get(objAgr.Apttus_QPComply__RelatedProposalId__c).Total_Committed_Revenue__c==0 
                   && objAgr.Commit_Frequency__c =='No Commit - PAYG'){
                       objAgr.X6th_tier_discount_with_TCR_0__c = true;
                   }else{
                       objAgr.X6th_tier_discount_with_TCR_0__c = false;
                   }
            }
            update lstAgreements;
        }
    }
}