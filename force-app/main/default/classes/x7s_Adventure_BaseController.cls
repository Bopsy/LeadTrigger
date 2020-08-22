/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_BaseController {

    /* Method to return Adventure and related Adventure Steps, Step Modules and Module Tasks */
    @AuraEnabled
    public static x7s_Adventure_Response getAdventure(String adventureId, String ownerId, String setupName){
      
        x7s_Adventure_Response peakResponse = new x7s_Adventure_Response();
        x7s_Adventure_Setting__mdt defaultSetup = new x7s_Adventure_Setting__mdt();
        x7s_Adventure_MyProgress myAdventureProgress = new x7s_Adventure_MyProgress(); 
       
        String adventureQuery = 'SELECT Id, Name, title__c, Title_Image__c, Header_Image__c, Banner_Image__c,Show_Checkboxes__c,Task_Progress__c,Number_of_Tasks__c,Number_of_Completed_Tasks__c, ' +
                '(SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.title, ContentDocument.FileExtension ' +
                'FROM ContentDocumentLinks) ' +
                'FROM Adventure__c WHERE Id =: adventureId';

        String adventureStepQuery = 'SELECT Id, Name, title__c, subtitle__c, Order__c, Icon_Image__c, description__c, (SELECT Id, ContentDocumentId, ' +
                'ContentDocument.LatestPublishedVersionId, ContentDocument.title, ContentDocument.FileExtension ' +
                'FROM ContentDocumentLinks) FROM Adventure_Step__c WHERE Adventure__r.Id =: adventureId ORDER BY Order__c';

        try{
            //Query the Adventure
            List<Adventure__c> theAdventures = Database.query(adventureQuery);
            Map<Id,List<x7s_Adventure_StepModuleWrapper>> stepModuleMap = new Map<Id, List<x7s_Adventure_StepModuleWrapper>>();
            List<x7s_Adventure_StepWrapper> stepWrapperList = new List<x7s_Adventure_StepWrapper>();


            List<Adventure_Step__c> adventureSteps = new List<Adventure_Step__c>();
            if(!x7s_Adventure_Utils.isNullOrEmpty(theAdventures)) {

                //Query the Adventure Steps
                adventureSteps = Database.query(adventureStepQuery);

                if (!x7s_Adventure_Utils.isNullOrEmpty(adventureSteps)) {

                    stepModuleMap = mapRelatedStepModules(adventureSteps,ownerId);

                    //For each Adventure step, create a wrapper using fields from query and map values for step modules and module tasks
                    for (Adventure_Step__c theStep : adventureSteps) {
                        if (theStep != NULL) {
                            x7s_Adventure_StepWrapper stepWrapper = x7s_Adventure_StepWrapperHelper.createWrapper(theStep, stepModuleMap.get(theStep.Id));
                            stepWrapperList.add(stepWrapper);
                        }
                    }
                }
                if(setupName !=null &&  !String.IsBlank(setupName)){
                    defaultSetup = getConfiguration(setupName);
                }
                if(ownerId != null && !String.IsBlank(ownerId)){
                    myAdventureProgress = getMyAdventureProgress(adventureId,ownerId);
                }
               
            }

            //Create Peak_Content Object to return Adventure, Adventure_Steps, Step_Modules, and Module_Tasks
            x7s_Adventure_ContentObject peakContentObject = x7s_Adventure_ContentObjectHelper.formatPeakContentObject(theAdventures[0],stepWrapperList);

            peakResponse.peakResults.add(peakContentObject);
            peakResponse.success = TRUE;
            peakResponse.globalSetting = defaultSetup;
            peakResponse.adventureProgress = myAdventureProgress;
            


        } catch (exception e) {
            //System.debug('Error Message: '+e.getMessage() +' , Error Line Number: '+ e.getLineNumber());
            peakResponse.success = FALSE;
            peakResponse.messages.add(e.getMessage());
        }       
        return peakResponse;
    }

    /* Method to Map Adventure_Step Id's to their related Step Modules */
    @AuraEnabled
    public static Map<Id, List<x7s_Adventure_StepModuleWrapper>> mapRelatedStepModules(List<Adventure_Step__c> adventureSteps, String ownerId){

        Map<Id, List<x7s_Adventure_StepModuleWrapper>> adventureStepModuleWrapperMap = new Map<Id, List<x7s_Adventure_StepModuleWrapper>>();
        String moduleTaskQuery ='';     
        
        //Get a list of Adventure Step Ids
        List<String> adventureStepIds = new List<String>();
        for(Adventure_Step__c theAdventureStep : adventureSteps){
            adventureStepIds.add(theAdventureStep.Id);
        }
        
        String stepModuleQuery = 'SELECT Id, Name, Adventure_Step__c, Title__c, Order__c, Tooltip_Description__c, Description_URL__c, Description_Label__c,Task_Progress__c,Completed__c FROM Step_Module__c WHERE Adventure_Step__c IN: adventureStepIds ORDER BY Order__c';
       
       // Filter My Task
        If (!String.IsBlank(ownerId)){
            
            moduleTaskQuery = 'SELECT Id, Title__c, Name, Content_URL__c, Icon_Name__c, Step_Module__c, isNew__c,Completed__c,Owner__c,Restrict_to_User__c, (SELECT Id, ContentDocumentId, ' +
                'ContentDocument.LatestPublishedVersionId, ContentDocument.title, ContentDocument.FileExtension ' +
                'FROM ContentDocumentLinks) FROM Module_Task__c WHERE Step_Module__c IN: stepModules AND Owner__c =: ownerId ORDER BY Order__c ';
        }else {  
            
            moduleTaskQuery = 'SELECT Id, Title__c, Name, Content_URL__c, Icon_Name__c, Step_Module__c, isNew__c,Completed__c,Owner__c,Restrict_to_User__c, (SELECT Id, ContentDocumentId, ' +
                'ContentDocument.LatestPublishedVersionId, ContentDocument.title, ContentDocument.FileExtension ' +
                'FROM ContentDocumentLinks) FROM Module_Task__c WHERE Step_Module__c IN: stepModules ORDER BY Order__c';  
        }
       
        if(!x7s_Adventure_Utils.isNullOrEmpty(adventureStepIds)) {
            try {

                //Query Step Modules and Module Tasks
                List<Step_Module__c> stepModules = Database.query(stepModuleQuery);
                List<Module_Task__c> moduleTasks = Database.query(moduleTaskQuery);

                //Create a Map of Step Modules and related Module Tasks
                Map<Id, List<Module_Task__c>> stepTaskMap = new Map<Id, List<Module_Task__c>>();

                for(Module_Task__c theModuleTask: moduleTasks){

                    if(!stepTaskMap.containsKey(theModuleTask.Step_Module__c)){
                        List<Module_Task__c> moduleTaskList = new List<Module_Task__c>();
                        moduleTaskList.add(theModuleTask);

                        stepTaskMap.put(theModuleTask.Step_Module__c, moduleTaskList);
                    }else{
                        stepTaskMap.get(theModuleTask.Step_Module__c).add(theModuleTask);
                    }
                }

                //Wrap the Step Modules with their related Module Tasks
                //Checking the filter is option
                List<x7s_Adventure_StepModuleWrapper> moduleWrappers = new List<x7s_Adventure_StepModuleWrapper>();
                If (!String.IsBlank(ownerId)){
                    //My Module tasks only
                    for(Step_Module__c theStepModule : stepModules){
                        if(theStepModule != NULL) {
                           if(stepTaskMap.containsKey(theStepModule.Id)){
                                moduleWrappers.add(x7s_Adventure_MyStepModuleWrapperHelper.createWrapper(theStepModule, stepTaskMap.get(theStepModule.Id)));
                           }else{
                                moduleWrappers.add(x7s_Adventure_MyStepModuleWrapperHelper.createWrapper(theStepModule, new List<Module_Task__c>()));
                           }
                        }
                    }
                }else{
                    //All Module tasks
                    for(Step_Module__c theStepModule : stepModules){
                        if(theStepModule != NULL) {
                            if(stepTaskMap.containsKey(theStepModule.Id)){
                                 moduleWrappers.add(x7s_Adventure_StepModuleWrapperHelper.createWrapper(theStepModule, stepTaskMap.get(theStepModule.Id)));
                            }else{
                                 moduleWrappers.add(x7s_Adventure_StepModuleWrapperHelper.createWrapper(theStepModule, new List<Module_Task__c>()));
                            }
                            
                        }
                    }
                }

                //Build the Map <Adventure ID, List of Step Modules>
                for(x7s_Adventure_StepModuleWrapper theWrapper : moduleWrappers){

                    //If the Map doesn't yet have the Key
                    if(!adventureStepModuleWrapperMap.containsKey(theWrapper.Adventure_Step_Id)){

                        //Create the Step Module Wrapper List
                        List<x7s_Adventure_StepModuleWrapper> newValueList = new List<x7s_Adventure_StepModuleWrapper>();
                        newValueList.add(theWrapper);

                        //and Map it to the Adventure Step Id
                        adventureStepModuleWrapperMap.put(theWrapper.Adventure_Step_Id, newValueList);

                    //If Map does contain the key, add the value
                    }else{
                        adventureStepModuleWrapperMap.get(theWrapper.Adventure_Step_Id).add(theWrapper);
                    }
                }

            } catch (exception e) {
                System.debug('ERROR ==' + e.getMessage());
            }
        }

        return adventureStepModuleWrapperMap;
    }

    // Vikram Sisodia 14-02-2020 : adventure default configuration
    @AuraEnabled
    public static x7s_Adventure_Setting__mdt getConfiguration(String metadataName){

        try{
           
            x7s_Adventure_Setting__mdt adentureSetupList = [SELECT Enable_Checkbox_Display__c,Enable_New_Task_Flag__c,Full_Clone_Error_Text__c,No_Assigned_Tasks_Text__c,
            Full_Clone_Success_Text__c,Override_Action_Color__c,Override_Link_Color__c,Task_Completion_Checked_Text__c,Task_Completion_Unchecked_Text__c 
            FROM x7s_Adventure_Setting__mdt WHERE DeveloperName = : metadataName LIMIT 1];
            return adentureSetupList;
           

        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }      
        
    }
    @AuraEnabled
    public static x7s_Adventure_MyProgress getMyAdventureProgress(Id adventureId, String ownerId){

        try{

            x7s_Adventure_MyProgress myAdventureProgress = new x7s_Adventure_MyProgress();
            Integer totalTasks =0;
            Integer totalCompleteTasks =0;
            Decimal adventureProgress =0;
            List<Id> myStepIdList = new List<Id>();
            List<Id> myModuleIdList = new List<Id>();
         
            List<Adventure_Step__c> myAdventure = new List<Adventure_Step__c>([SELECT Id From Adventure_Step__c WHERE Adventure__c =:adventureId]);
           
            If (myAdventure.size() > 0 ) {
    
                for(Adventure_Step__c adve:myAdventure){
                    myStepIdList.add(adve.Id);
                }
               
                String stepMyModuleQuery = 'SELECT Id FROM Step_Module__c WHERE Adventure_Step__c IN: myStepIdList';
                
                List<Step_Module__c> stepModules = Database.query(stepMyModuleQuery);
               
                for(Step_Module__c moduleId:stepModules){
                    myModuleIdList.add(moduleId.Id);
                }
                //String    taskSummary = 'SELECT id,Completed__c FROM Module_Task__c WHERE Step_Module__c IN: myModuleIdList AND Owner__c =:ownerId';
                
                String  totalTaskSummary = 'SELECT count() FROM Module_Task__c WHERE Step_Module__c IN: myModuleIdList AND Owner__c =:ownerId';
                totalTasks = Database.countQuery(totalTaskSummary);
    
                String  totalCompleteTaskSummary = 'SELECT count() FROM Module_Task__c WHERE Step_Module__c IN: myModuleIdList AND Owner__c =:ownerId AND Completed__c =true';
                totalCompleteTasks =Database.countQuery(totalCompleteTaskSummary);
    
                myAdventureProgress.totalTasksAssigned = totalTasks;
                myAdventureProgress.totalCompletedTasks = totalCompleteTasks;
                
                if(totalTasks > 0) {
                    adventureProgress = (Decimal.valueOf(totalCompleteTasks) /  Decimal.valueOf(totalTasks)) * 100;
                }
                myAdventureProgress.adventureProgress =adventureProgress.setScale(0);
            }
            
            return myAdventureProgress;

        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }  
       
    }
    // Dhana Prasad 07-04-2020 get current user accountId and recent adventure of that account : 
    @AuraEnabled
    public static Id currentUserRecentAdventure(){
        ID contactId = [Select contactid from User where id =: Userinfo.getUserid()].contactId;
        ID AccID  = [Select AccountID from Contact where id =: contactId].AccountId;
        ID advId = [SELECT Id FROM Adventure__c WHERE Account__c =: AccID ORDER BY CreatedDate DESC LIMIT 1].Id;
        if(advId != null) {
            return advId;
        }
        return null;
        
    }


}