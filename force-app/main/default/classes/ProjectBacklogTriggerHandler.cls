/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           ProjectBacklogTriggerHandler
*
* @description    Service class for ProjectBacklogTrigger
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
public class ProjectBacklogTriggerHandler {

    public static void handleOnInsert(List<Project_Team__c> lstProjBacklog){
        Set<Id> setGTMProjectIds = new Set<Id>();
        List<Project_Team__c> lstProjBacklog1 = new List<Project_Team__c>();
        List<GTM_Project_to_Project_Backlog_mappings__c> settings = GTM_Project_to_Project_Backlog_mappings__c.getAll().values();
        for(Project_Team__c objProjBacklog: lstProjBacklog){
            if(objProjBacklog.GTM_Project__c!=null){
                for(GTM_Project_to_Project_Backlog_mappings__c setting: settings){
                    if(setting.Project_Backlog_Field_API__c != null){
                        setGTMProjectIds.add(objProjBacklog.GTM_Project__c);
                        lstProjBacklog1.add(objProjBacklog);
                        break; 
                    }
                }
            }
        }
        if(lstProjBacklog1.size()>0){
            updateProjectBacklogSyncFields(setGTMProjectIds,lstProjBacklog1);
        }
    }
    
    public static void handleOnInsertTeams(List<Project_Team__c> lstProjBacklog){
        Set<Id> setGTMProjectIds = new Set<Id>();
        List<GTM_Project_to_Project_Backlog_mappings__c> settings = GTM_Project_to_Project_Backlog_mappings__c.getAll().values();
        for(Project_Team__c objProjBacklog: lstProjBacklog){
            if(objProjBacklog.GTM_Project__c!=null){
                if(objProjBacklog.Team__c!=null){
                    setGTMProjectIds.add(objProjBacklog.GTM_Project__c);
                }
            }
        }
        if(setGTMProjectIds.size()>0){
            updateGTMProjectTeams(setGTMProjectIds);
        }
    }
    
    public static void handleOnUpdate(Map<Id,Project_Team__c> oldMap, List<Project_Team__c> lstProjBacklog){
        Set<Id> setGTMProjectIds = new Set<Id>();
        Set<Id> setGTMProjectIds1 = new Set<Id>();
        Map<Id,Project_Team__c> mapGtmIDWithProjBacklog = new Map<Id, Project_Team__c>();
        List<GTM_Project_to_Project_Backlog_mappings__c> settings = GTM_Project_to_Project_Backlog_mappings__c.getAll().values();
        for(Project_Team__c objProjBacklog: lstProjBacklog){
            if(objProjBacklog.Team__c!=oldMap.get(objProjBacklog.Id).Team__c || objProjBacklog.GTM_Project__c!=oldMap.get(objProjBacklog.Id).GTM_Project__c){
                setGTMProjectIds.add(objProjBacklog.GTM_Project__c);
            }
            if(objProjBacklog.GTM_Project__c!=null){
                for(GTM_Project_to_Project_Backlog_mappings__c setting: settings){
                    if(setting.Project_Backlog_Field_API__c != null){
                        if(objProjBacklog.get(setting.Project_Backlog_Field_API__c)!=oldMap.get(objProjBacklog.Id).get(setting.Project_Backlog_Field_API__c)){
                            mapGtmIDWithProjBacklog.put(objProjBacklog.GTM_Project__c,objProjBacklog);
                            setGTMProjectIds1.add(objProjBacklog.GTM_Project__c);
                            break; 
                        }
                    }
                }
            }
        }
        if(setGTMProjectIds.size()>0){
            updateGTMProjectTeams(setGTMProjectIds);
        }
        if(mapGtmIDWithProjBacklog.size()>0){
            updateGTMProjectSyncFields(setGTMProjectIds1,mapGtmIDWithProjBacklog);
        }
    }
    
    public static void handleOnDelete(List<Project_Team__c> lstProjBacklog){
        Set<Id> setGTMProjectIds = new Set<Id>();
        for(Project_Team__c objProjBacklog: lstProjBacklog){
            if(objProjBacklog.Team__c!=null && objProjBacklog.GTM_Project__c!=null){
                setGTMProjectIds.add(objProjBacklog.GTM_Project__c);
            }
        }
        if(setGTMProjectIds.size()>0){
            updateGTMProjectTeams(setGTMProjectIds);
        }
    }
    
    public static void updateGTMProjectTeams(Set<Id> setGTMProjectIds){
        List<Workstream__c> lstToUpdate = new List<Workstream__c>();
        Map<Id,Workstream__c> mapGTMProject = new Map<Id,Workstream__c>([Select Id, Project_Backlog_Teams__c from Workstream__c where Id IN:setGTMProjectIds]);
        Map<Id,Project_Team__c> mapProjectBacklogs = new Map<Id,Project_Team__c>([Select Id,Team__c,Team_Text__c, GTM_Project__c from Project_Team__c where  
                                                                                  GTM_Project__c IN:setGTMProjectIds and Team_Text__c!=null]);
        if(mapGTMProject.size()>0){
            for(Workstream__c objGTMProj: mapGTMProject.values()){
                objGTMProj.Project_Backlog_Teams__c = null;
            }
            
            if(mapProjectBacklogs.size()>0){
                for(Project_Team__c objProjBacklog: mapProjectBacklogs.values()){
                    if(objProjBacklog.GTM_Project__c==mapGTMProject.get(objProjBacklog.GTM_Project__c).Id){
                        if(mapGTMProject.get(objProjBacklog.GTM_Project__c).Project_Backlog_Teams__c==null){
                            mapGTMProject.get(objProjBacklog.GTM_Project__c).Project_Backlog_Teams__c = objProjBacklog.Team_Text__c;
                        }else{
                            mapGTMProject.get(objProjBacklog.GTM_Project__c).Project_Backlog_Teams__c += ', '+objProjBacklog.Team_Text__c;
                        }
                    }
                }
            }
            lstToUpdate.addall(mapGTMProject.values());
            database.update(lstToUpdate,false);
        }
    }
    
    public static void updateGTMProjectSyncFields(Set<Id> setGTMProjectIds, Map<Id,Project_Team__c> mapGtmIDWithProjBacklog){
        String GtmQueryString = 'SELECT Id';
        for(GTM_Project_to_Project_Backlog_mappings__c  setting : GTM_Project_to_Project_Backlog_mappings__c.getAll().values()){
            GtmQueryString += ' ,' + setting.GTM_Project_Field_API__c ;
        }
        GtmQueryString += ' From Workstream__c Where Id IN:setGTMProjectIds' ;
        System.debug('++query '+GtmQueryString);
        List<Workstream__c> lstGTMProjects = database.query(GtmQueryString);
        for(Workstream__c objGTMProj: lstGTMProjects){
            for(GTM_Project_to_Project_Backlog_mappings__c setting : GTM_Project_to_Project_Backlog_mappings__c.getAll().values()){
            	objGTMProj.put(setting.GTM_Project_Field_API__c, mapGtmIDWithProjBacklog.get(objGTMProj.id).get(setting.Project_Backlog_Field_API__c)) ;
        	}
        }
        system.debug('+++lstGTMProjects '+lstGTMProjects);
        database.update(lstGTMProjects,false);
    }
    
    public static void updateProjectBacklogSyncFields(Set<Id> setGTMProjectIds, List<Project_Team__c> lstProjectBacklog){
        String GtmQueryString = 'SELECT Id';
        for(GTM_Project_to_Project_Backlog_mappings__c  setting : GTM_Project_to_Project_Backlog_mappings__c.getAll().values()){
            GtmQueryString += ' ,' + setting.GTM_Project_Field_API__c ;
        }
        GtmQueryString += ' From Workstream__c Where Id IN:setGTMProjectIds' ;
        System.debug('++query '+GtmQueryString);
        Map<Id,Workstream__c> mapGTMProjects = new Map<Id,Workstream__c>((List<Workstream__c>) database.query(GtmQueryString));
        if(lstProjectBacklog.size()>0){
            for(Project_Team__c objProj: lstProjectBacklog){
                for(GTM_Project_to_Project_Backlog_mappings__c setting : GTM_Project_to_Project_Backlog_mappings__c.getAll().values()){
                    objProj.put(setting.Project_Backlog_Field_API__c, mapGTMProjects.get(objProj.GTM_Project__c).get(setting.GTM_Project_Field_API__c)) ;
                }
            }
            system.debug('+++lstProjectBacklog '+lstProjectBacklog);
        }
    }
}