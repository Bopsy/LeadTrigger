/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           ConfigurationTriggerHandler
*
* @description    Service class to handle trigger logic on Apttus_Config2__ProductConfiguration__c object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-03-01
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public without sharing class ConfigurationTriggerHandler {
    
    /***************************************************
                Added by Apttus Support
                Case: CAS-09701-F2Y8Y7
                Date: 15-03-2019
                Desc: To stop approval process to be fired based on the condition on TCR/Net unit price/color
    ****************************************************/
    public static void updateLineItemRecordsForApproval(List<Apttus_Config2__ProductConfiguration__c> lstConfigs, Map<Id,Apttus_Config2__ProductConfiguration__c> oldMap){
    
        if(lstConfigs.size()==1 && lstConfigs[0].Apttus_CQApprov__Approval_Status__c!=oldMap.get(lstConfigs[0].Id).Apttus_CQApprov__Approval_Status__c && lstConfigs[0].Apttus_CQApprov__Approval_Status__c=='Approved'){
                list<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
                
                lineItemList = [select id,name,Apttus_Config2__Guidance__c,APTS_Approved_Guidance__c,APTS_Approved_Net_Unit_Price__c,Apttus_Config2__NetUnitPrice__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:lstConfigs[0].Id];
                
                for(Apttus_Config2__LineItem__c li : lineItemList){
                    li.APTS_Approved_Guidance__c = li.Apttus_Config2__Guidance__c;
                    li.APTS_Approved_Net_Unit_Price__c= li.Apttus_Config2__NetUnitPrice__c;
                }
                
                if(lineItemList!=null && lineItemList.size()>0)
                    update lineItemList;
            }
    }
    
    public static void checkOnTotalHours(List<Apttus_Config2__ProductConfiguration__c> lstConfigs){
        if(lstConfigs!=null){
            if(lstConfigs.size()>0){
                for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
                    objConfig.Total_Hours_to_Approve_Request__c =0;
                }
            }
        }
    }
    
    public static void updateProposalTotalOnInsert(List<Apttus_Config2__ProductConfiguration__c> lstConfigs, Boolean isDelete){
        Set<Id> proposalIds=new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
            if(objConfig.Total_Hours_to_Approve_Request__c!=null && objConfig.Total_Hours_to_Approve_Request__c!=0){
                proposalIds.add(objConfig.Apttus_QPConfig__Proposald__c);
            }
        }
        if(proposalIds!=null && proposalIds.size()>0){
            List<Apttus_Proposal__Proposal__c> lstProposal = new List<Apttus_Proposal__Proposal__c>();
            Map<Id,Apttus_Proposal__Proposal__c> mapProposal = new Map<Id,Apttus_Proposal__Proposal__c>([Select Id, Total_Hours_to_Approve_Configuration__c from Apttus_Proposal__Proposal__c
                                                              where Id IN: proposalIds]);
            if(mapProposal.size()>0){
                for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
                    if(objConfig.Total_Hours_to_Approve_Request__c!=null && objConfig.Total_Hours_to_Approve_Request__c!=0 && mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c)!=null){
                        if(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c==null){
                            mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c=0;
                        }
                        if(isDelete==true){
                            mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c -= objConfig.Total_Hours_to_Approve_Request__c;
                        }else{
                            mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c += objConfig.Total_Hours_to_Approve_Request__c;
                        }
                        if(!lstProposal.contains(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c))){
                            lstProposal.add(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c));
                        }  
                    }
                }
                if(lstProposal.size()>0)
                database.update(lstProposal, false);
            }
        }
    }
    
    public static void updateProposalTotalOnUpdate(List<Apttus_Config2__ProductConfiguration__c> lstConfigs, 
                                                 Map<Id,Apttus_Config2__ProductConfiguration__c> oldMap, Map<Id,Apttus_Config2__ProductConfiguration__c> newMap){
        Set<Id> proposalIds=new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
            if(oldMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c != newMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c){
                proposalIds.add(objConfig.Apttus_QPConfig__Proposald__c);
            }
        }
        if(proposalIds!=null && proposalIds.size()>0){
            List<Apttus_Proposal__Proposal__c> lstProposal = new List<Apttus_Proposal__Proposal__c>();
            Map<Id,Apttus_Proposal__Proposal__c> mapProposal = new Map<Id,Apttus_Proposal__Proposal__c>([Select Id, Total_Hours_to_Approve_Configuration__c from Apttus_Proposal__Proposal__c
                                                              where Id IN: proposalIds]);
            if(mapProposal.size()>0){
                for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
                    if(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c)!=null){
                        if(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c==null){
                            mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c=0;
                        }
                        if(oldMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c!=null && oldMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c!=0){
                            mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c -= oldMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c;
                        } 
                        if(newMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c!=null && newMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c!=0){
                            mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c).Total_Hours_to_Approve_Configuration__c += newMap.get(objConfig.Id).Total_Hours_to_Approve_Request__c;
                        } 
                        if(!lstProposal.contains(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c))){
                            lstProposal.add(mapProposal.get(objConfig.Apttus_QPConfig__Proposald__c));
                        } 
                    }       
                }
                if(lstProposal.size()>0)
                database.update(lstProposal, false);
            }
        }
    }
    
    public static void updateDealDeskApprovalCountOnInsert(List<Apttus_Config2__ProductConfiguration__c> lstConfigs, Boolean isDelete){
        Set<Id> proposalIdsForRollup=new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
            if(objConfig.Discounts_for_deal_desk_approval__c>0 && (objConfig.Apttus_cqapprov__approval_status__c=='Approved' || objConfig.Apttus_cqapprov__approval_status__c=='Rejected')){
                proposalIdsForRollup.add(objConfig.Apttus_QPConfig__Proposald__c);
            }
        }
        if(proposalIdsForRollup!=null && proposalIdsForRollup.size()>0){
            List<Apttus_Proposal__Proposal__c> lstProposal = new List<Apttus_Proposal__Proposal__c>();
            Map<Id,Apttus_Proposal__Proposal__c> mapProposalForRollup = new Map<Id,Apttus_Proposal__Proposal__c>([Select Id, Product_Configurations_with_DD_Approvals__c from Apttus_Proposal__Proposal__c
                                                              where Id IN: proposalIdsForRollup]);
            if(mapProposalForRollup.size()>0){
                for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
                    if(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c)!=null){
                        if(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c==null){
                            mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c=0;
                        }
                        if(isDelete==true && mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c>0){
                            mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c -= 1;
                        }else{
                            mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c += 1;
                        }
                        if(!lstProposal.contains(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c))){
                            lstProposal.add(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c));
                        }  
                    }
                }
                if(lstProposal.size()>0)
                database.update(lstProposal, false);
            }
        }
    }
    
    public static void updateDealDeskApprovalCountOnUpdate(List<Apttus_Config2__ProductConfiguration__c> lstConfigs, 
                                                 Map<Id,Apttus_Config2__ProductConfiguration__c> oldMap, Map<Id,Apttus_Config2__ProductConfiguration__c> newMap){
        Set<Id> proposalIdsForRollup=new Set<Id>();
        for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
            if(oldMap.get(objConfig.Id).Discounts_for_deal_desk_approval__c != newMap.get(objConfig.Id).Discounts_for_deal_desk_approval__c || 
               oldMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c!= newMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c){
                proposalIdsForRollup.add(objConfig.Apttus_QPConfig__Proposald__c);
            }
        }
        if(proposalIdsForRollup!=null && proposalIdsForRollup.size()>0){
            List<Apttus_Proposal__Proposal__c> lstProposal = new List<Apttus_Proposal__Proposal__c>();
            Map<Id,Apttus_Proposal__Proposal__c> mapProposalForRollup = new Map<Id,Apttus_Proposal__Proposal__c>([Select Id, Product_Configurations_with_DD_Approvals__c from Apttus_Proposal__Proposal__c
                                                              where Id IN: proposalIdsForRollup]);
            if(mapProposalForRollup.size()>0){
                for(Apttus_Config2__ProductConfiguration__c objConfig: lstConfigs){
                    if(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c)!=null){
                        if(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c==null){
                            mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c=0;
                        }
                        if(oldMap.get(objConfig.Id).Discounts_for_deal_desk_approval__c>0 && 
                           (oldMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c=='Approved' || oldMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c=='Rejected')){
                               if(newMap.get(objConfig.Id).Discounts_for_deal_desk_approval__c==0 || 
                                  (newMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c!='Approved' && newMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c!='Rejected')){
                                      if(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c>0){
                                          mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c -= 1;
                                      }
                              }
                        } 
                        if(oldMap.get(objConfig.Id).Discounts_for_deal_desk_approval__c==0 || 
                           (oldMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c!='Approved' && oldMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c!='Rejected')){
                               if(newMap.get(objConfig.Id).Discounts_for_deal_desk_approval__c>0 && 
                                  (newMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c=='Approved' || newMap.get(objConfig.Id).Apttus_cqapprov__approval_status__c=='Rejected')){
                                      mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c).Product_Configurations_with_DD_Approvals__c += 1;
                                  }
                        }
                        if(!lstProposal.contains(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c))){
                            lstProposal.add(mapProposalForRollup.get(objConfig.Apttus_QPConfig__Proposald__c));
                        } 
                    }    
                }
                if(lstProposal.size()>0)
                database.update(lstProposal, false);
            }
        }
    }
}