public with sharing class ProjectManagerController {
    
    public String stakeHolders {get; set;}
    public String endProjects {get; set;}
    final static Date thisWeekStartDate = Date.today().toStartOfWeek();
    final static Date thisWeekEndDate = thisWeekStartDate.addDays(7);
    
    public ProjectManagerController(){
        stakeHolders = getStakeHolders();
        endProjects = getEndProjects();
    }
    
    String getStakeHolders(){
        return JSON.serialize([SELECT Name, (SELECT Name, Project_Manager__r.Name, Stakeholder__c, End_Date__c FROM Projects__r ORDER BY CreatedDate) FROM Stakeholder__c]);
    }
    
    String getEndProjects(){
        return JSON.serialize([SELECT Project_Manager__r.Name, Name, End_Date__c FROM Project__c WHERE End_Date__c >= :thisWeekStartDate AND End_Date__c <= : thisWeekEndDate]);
    }
    
    @RemoteAction
    public static Project__c addProject(String projectString){
        Project__c newProject = (Project__c) JSON.deserialize(projectString, Project__c.class);
        newProject.Project_Manager__c = UserInfo.getUserId();
        insert newProject;
        return newProject;
    }
    
    @RemoteAction
    public static List<Phase__c> queryPhases(Id projectId, String type){
        List<Phase__c> phases = new List<Phase__c>();
        if(type == 'Project'){
            phases = [SELECT Id, Name, Status__c, BA_Hours__c, Dev_Hours__c, End_Date__c, Project__c, Start_Date__c, Type__c FROM Phase__c WHERE Project__c =:projectId ORDER BY Start_Date__c];
            
        }
        else if(type == 'Stakeholder'){
            phases = [SELECT Id, Name, Status__c, BA_Hours__c, Dev_Hours__c, End_Date__c, Project__c, Start_Date__c, Type__c FROM Phase__c WHERE Project__r.Stakeholder__c =:projectId ORDER BY Start_Date__c];
        }
        return phases;
    }
    
    @RemoteAction
    public static Phase__c addPhase(String phaseString){
        Phase__c newPhase = (Phase__c) JSON.deserialize(phaseString, Phase__c.class);
        insert newPhase;
        return newPhase;
    }
    
    @RemoteAction
    public static List<Milestone__c> queryMilestones(Id phaseId){
        return [SELECT Name, Due_Date__c, Total_Hours__c, Phase__c FROM Milestone__c WHERE Phase__c =: phaseId];
    }
}