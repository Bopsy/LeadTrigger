/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           GTMProjectTriggerHandler
*
* @description    Service class for GTMProjectTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-08-19
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class GTMProjectTriggerHandler {

    public static void handleOnInsert(List<Workstream__c> lstGTMProjects){
        Map<Id,Workstream__c> mapGTMProjectToConsider = new Map<Id,Workstream__c>();
        List<GTM_Project_to_Project_Backlog_mappings__c> settings = GTM_Project_to_Project_Backlog_mappings__c.getAll().values();
        for(Workstream__c objGTMProject: lstGTMProjects){
            for(GTM_Project_to_Project_Backlog_mappings__c setting: settings){
                if(setting.GTM_Project_Field_API__c != null){
                    if(objGTMProject.get(setting.GTM_Project_Field_API__c)!=null){
                        mapGTMProjectToConsider.put(objGTMProject.Id,objGTMProject);
                        break; 
                    }
                }
            }
        }
        if(mapGTMProjectToConsider.size()>0){
            updateProjectBacklogSyncFields(mapGTMProjectToConsider);
        }
    }
    
    public static void handleOnUpdate(Map<Id,Workstream__c> oldMap, List<Workstream__c> lstGTMProjects){
        Map<Id,Workstream__c> mapGTMProjectToConsider = new Map<Id,Workstream__c>();
        List<GTM_Project_to_Project_Backlog_mappings__c> settings = GTM_Project_to_Project_Backlog_mappings__c.getAll().values();
        for(Workstream__c objGTMProject: lstGTMProjects){
            for(GTM_Project_to_Project_Backlog_mappings__c setting: settings){
                if(setting.GTM_Project_Field_API__c != null){
                    if(objGTMProject.get(setting.GTM_Project_Field_API__c)!=oldMap.get(objGTMProject.Id).get(setting.GTM_Project_Field_API__c)){
                        mapGTMProjectToConsider.put(objGTMProject.Id,objGTMProject);
                        break; 
                    }
                }
            }
        }
        if(mapGTMProjectToConsider.size()>0){
            updateProjectBacklogSyncFields(mapGTMProjectToConsider);
        }
    }
    
    public static void updateProjectBacklogSyncFields(Map<Id,Workstream__c> mapGTMProjectToConsider){
        Set<Id> setIds = new Set<Id>();
        setIds.addAll(mapGTMProjectToConsider.keyset());
        String GtmQueryString = 'SELECT Id,GTM_Project__c';
        for(GTM_Project_to_Project_Backlog_mappings__c  setting : GTM_Project_to_Project_Backlog_mappings__c.getAll().values()){
            GtmQueryString += ' ,' + setting.Project_Backlog_Field_API__c ;
        }
        GtmQueryString += ' From Project_Team__c Where GTM_Project__c IN:setIds' ;
        System.debug('++query '+GtmQueryString);
        List<Project_Team__c> lstProjectBacklog = database.query(GtmQueryString);
        if(lstProjectBacklog!=null && lstProjectBacklog.size()>0){
            for(Project_Team__c objProj: lstProjectBacklog){
                for(GTM_Project_to_Project_Backlog_mappings__c setting : GTM_Project_to_Project_Backlog_mappings__c.getAll().values()){
                    objProj.put(setting.Project_Backlog_Field_API__c, mapGTMProjectToConsider.get(objProj.GTM_Project__c).get(setting.GTM_Project_Field_API__c)) ;
                }
            }
            system.debug('+++lstProjectBacklog '+lstProjectBacklog);
            database.update(lstProjectBacklog,false);
        }
    }
}