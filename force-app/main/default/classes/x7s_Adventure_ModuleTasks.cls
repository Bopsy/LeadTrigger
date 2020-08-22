/*
 * Copyright (c) 2020. 7Summits Inc.
 */


public with sharing class x7s_Adventure_ModuleTasks{
   
    //Vikram Sisodia on 2/06/2020: Task complete/not complete action method (Checkbox action)
    @AuraEnabled
    public static Boolean taskCompleted(Id selectedTaskId, Boolean checkboxFlag){
        Boolean flagStatus = null;
        try{
            If(selectedTaskId != null) {
                List<Module_Task__c> taskSelectedList = new List<Module_Task__c>([SELECT Id,Completed__c FROM Module_Task__c WHERE Id =:selectedTaskId LIMIT 1]);
                List<Module_Task__c> updatedTaskList = new List<Module_Task__c>();
                If(taskSelectedList.size() > 0){
                    for(Module_Task__c taskRecord:taskSelectedList){
                        taskRecord.Completed__c = checkboxFlag;
                        updatedTaskList.add(taskRecord);
                    }
                    if (updatedTaskList.size() >0){
                        update updatedTaskList;
                        flagStatus = checkboxFlag;
                    }
                }
            }    
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }       
        return flagStatus;
    }
     // Vikram Sisodia 19-02-2020 : Module Task Progress (Progress Ring)
     @AuraEnabled
     public static Step_Module__c getModuleTaskProgress(String moduleId){
 
         try{
           
            Step_Module__c queryResult;
             if (moduleId != null){
                
                Step_Module__c updatedTaskProgress = [SELECT Task_Progress__c,Completed__c FROM Step_Module__c WHERE Id =: moduleId LIMIT 1];
                queryResult = updatedTaskProgress;
             }
             return queryResult;
         }catch(Exception ex){
             throw new AuraHandledException(ex.getMessage());
         }      
         
     }    

    // Vikram Sisodia 26-02-2020 : My Module Task Progress "Filtered tasks" (Progress Ring)
     @AuraEnabled
     public static x7s_Adventure_MyModuleTaskWrapper getMyModuleTaskProgress(String moduleId,ID ownerId){
 
         try{
          
            x7s_Adventure_MyModuleTaskWrapper myModule;
            
            if (moduleId != null && ownerId != null){
               
               List<Module_Task__c> tasksList = [SELECT Id,Completed__c FROM Module_Task__c WHERE Step_Module__c =: moduleId AND Owner__c =: ownerId]; 
               myModule = x7s_Adventure_MyModuleTaskWrapperHelper.createWrapper(tasksList);
               
            }
            
            return myModule;

         }catch(Exception ex){
             throw new AuraHandledException(ex.getMessage());
         }
         
    }

    // Vikram Sisodia 26-02-2020 : My Adventure Progress after "Filtered tasks" 
    @AuraEnabled
    public static x7s_Adventure_MyProgress getMyAdventureProgress(Id adventureId, Id ownerId){

        try{

            x7s_Adventure_MyProgress myAdventureProgress = new x7s_Adventure_MyProgress();
            Integer totalTasks =0;
            Integer totalCompleteTasks =0;
            Decimal adventureProgress =0;
            List<Id> myStepIdList = new List<Id>();
            List<Id> myModuleIdList = new List<Id>();
            if (ownerId != null && adventureId != null){
          
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
                        //String 	taskSummary = 'SELECT id,Completed__c FROM Module_Task__c WHERE Step_Module__c IN: myModuleIdList AND Owner__c =:OwnerId';
                        
                        String 	totalTaskSummary = 'SELECT count() FROM Module_Task__c WHERE Step_Module__c IN: myModuleIdList AND Owner__c =:ownerId';
                        totalTasks = Database.countQuery(totalTaskSummary);
            
                        String 	totalCompleteTaskSummary = 'SELECT count() FROM Module_Task__c WHERE Step_Module__c IN: myModuleIdList AND Owner__c =:ownerId AND Completed__c =true';
                        totalCompleteTasks =Database.countQuery(totalCompleteTaskSummary);
            
                        myAdventureProgress.totalTasksAssigned = totalTasks;
                        myAdventureProgress.totalCompletedTasks = totalCompleteTasks;
                        
                        if(totalTasks > 0) {
                            adventureProgress = (Decimal.valueOf(totalCompleteTasks) /  Decimal.valueOf(totalTasks)) * 100;
                        }
                        myAdventureProgress.adventureProgress =adventureProgress.setScale(0);
                }
            }
            return myAdventureProgress;
        }catch(Exception ex){
            System.debug('Error Line: '+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }  
       
    }
    @AuraEnabled
    public static x7s_Adventure_MyProgress getAdventureProgress(Id adventureId){

        try{

            x7s_Adventure_MyProgress myAdventureProgress = new x7s_Adventure_MyProgress();
            Integer totalTasks =0;
            Integer totalCompleteTasks =0;
            Decimal adventureProgress =0;
            List<Id> myStepIdList = new List<Id>();
            List<Id> myModuleIdList = new List<Id>();

            if(adventureId !=null ){
                String getAdventure = 'SELECT Id,Number_of_Completed_Tasks__c,Task_Progress__c,Number_of_Tasks__c From Adventure__c  WHERE Id =:adventureId LIMIT 1';
                Adventure__c  myAllAdventure = Database.query(getAdventure);
                    if(myAllAdventure != null){
                        totalTasks = Integer.valueOf(myAllAdventure.Number_of_Tasks__c) ;
                        totalCompleteTasks = Integer.valueOf(myAllAdventure.Number_of_Completed_Tasks__c);
                        adventureProgress = myAllAdventure.Task_Progress__c;
                    }
                myAdventureProgress.totalTasksAssigned = totalTasks;
                myAdventureProgress.totalCompletedTasks = totalCompleteTasks;
                myAdventureProgress.adventureProgress = adventureProgress.setScale(0);
               
            } 
            return myAdventureProgress;

        }catch(Exception ex){
            System.debug('Error Line: '+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }  
       
    }   
}