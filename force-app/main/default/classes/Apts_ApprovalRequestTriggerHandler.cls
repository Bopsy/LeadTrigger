/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           Apts_ApprovalRequestTriggerHandler
*
* @description    Service class to handle trigger logic on Apttus_Approval__Approval_Request__c object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-02-28
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class Apts_ApprovalRequestTriggerHandler {
    
    public static void updateQuote(List<Apttus_Approval__Approval_Request__c> lstApprovals){
        for(Apttus_Approval__Approval_Request__c objApproval: lstApprovals){
            if(objApproval.Quote_Proposal__c!=null){
                objApproval.Apttus_QPApprov__ProposalId__c = objApproval.Quote_Proposal__c;
            }
        }
    }
    
    public static void updateConfigTotal(List<Apttus_Approval__Approval_Request__c> lstApprovals, Boolean isDelete){
        Set<Id> configIds=new Set<Id>();
        for(Apttus_Approval__Approval_Request__c objApproval: lstApprovals){
            if(objApproval.Hours_to_Approve__c!=null && objApproval.Hours_to_Approve__c!=0){
                configIds.add(objApproval.Apttus_CQApprov__CartId__c);
            }
        }
        if(configIds!=null && configIds.size()>0){
            List<Apttus_Config2__ProductConfiguration__c> lstConfigs = new List<Apttus_Config2__ProductConfiguration__c>();
            Map<Id,Apttus_Config2__ProductConfiguration__c> mapConfigs = new Map<Id,Apttus_Config2__ProductConfiguration__c>(
                [Select Id, Total_Hours_to_Approve_Request__c from Apttus_Config2__ProductConfiguration__c
                 where Id IN: configIds]);
            if(mapConfigs.size()>0){
                for(Apttus_Approval__Approval_Request__c objApproval: lstApprovals){
                    if(objApproval.Hours_to_Approve__c!=null && objApproval.Hours_to_Approve__c!=0 && mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c)!=null){
                        if(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c==null){
                            mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c =0;
                        }
                        if(isDelete==true){
                            mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c -= objApproval.Hours_to_Approve__c;
                        }else{
                            mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c += objApproval.Hours_to_Approve__c;
                        }
                        if(!lstConfigs.contains(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c))){
                            lstConfigs.add(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c));
                        }
                    }
                }
                if(lstConfigs.size()>0)
                    database.update(lstConfigs, false);
            }
        }
    }
    
    public static void updateConfigTotalOnUpdate(List<Apttus_Approval__Approval_Request__c> lstApprovals,  Map<Id,Apttus_Approval__Approval_Request__c> oldMap, Map<Id,Apttus_Approval__Approval_Request__c> newMap){
        Set<Id> configIds=new Set<Id>();
        for(Apttus_Approval__Approval_Request__c objApproval: lstApprovals){
            if(oldMap.get(objApproval.Id).Apttus_Approval__DateApproved__c != newMap.get(objApproval.Id).Apttus_Approval__DateApproved__c 
               || oldMap.get(objApproval.Id).Apttus_Approval__DateAssigned__c != newMap.get(objApproval.Id).Apttus_Approval__DateAssigned__c){
                configIds.add(objApproval.Apttus_CQApprov__CartId__c);
            }
        }
        if(configIds!=null && configIds.size()>0){
            List<Apttus_Config2__ProductConfiguration__c> lstConfigs = new List<Apttus_Config2__ProductConfiguration__c>();
            Map<Id,Apttus_Config2__ProductConfiguration__c> mapConfigs = new Map<Id,Apttus_Config2__ProductConfiguration__c>(
                [Select Id, Total_Hours_to_Approve_Request__c from Apttus_Config2__ProductConfiguration__c
                 where Id IN: configIds]);
            if(mapConfigs.size()>0){
                for(Apttus_Approval__Approval_Request__c objApproval: lstApprovals){
                    if(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c)!=null){
                        if(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c==null){
                            mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c =0;
                        }
                        if(oldMap.get(objApproval.Id).Hours_to_Approve__c!=null && oldMap.get(objApproval.Id).Hours_to_Approve__c!=0){
                            mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c -= oldMap.get(objApproval.Id).Hours_to_Approve__c;
                        }                
                        if(newMap.get(objApproval.Id).Hours_to_Approve__c!=null && newMap.get(objApproval.Id).Hours_to_Approve__c!=0){
                            mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c).Total_Hours_to_Approve_Request__c += newMap.get(objApproval.Id).Hours_to_Approve__c;
                        }
                        if(!lstConfigs.contains(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c))){
                            lstConfigs.add(mapConfigs.get(objApproval.Apttus_CQApprov__CartId__c));
                        }
                    }
                }
                if(lstConfigs.size()>0)
                    database.update(lstConfigs, false);
            }
        }
    }
}