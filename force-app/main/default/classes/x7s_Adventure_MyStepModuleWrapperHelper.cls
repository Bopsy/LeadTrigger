/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_MyStepModuleWrapperHelper {


     public static x7s_Adventure_StepModuleWrapper createWrapper(Step_Module__c theStepModule, List<Module_Task__c> moduleTasks){

        x7s_Adventure_StepModuleWrapper stepModule = new x7s_Adventure_StepModuleWrapper();
        Decimal NumberOfCompletedTasks = 0;
        Decimal totalTaskAssigned = 0;
        Decimal taskProgress = 0 ;
        Boolean ModuleCompleted = false;

        If(moduleTasks.size() >0){
            stepModule.moduleTasks = moduleTasks;
            for(Module_Task__c myTask:moduleTasks){
                totalTaskAssigned = totalTaskAssigned+1;
                if(myTask.Completed__c ==true){
                    NumberOfCompletedTasks = NumberOfCompletedTasks +1;
                }
            }
      
            taskProgress = (NumberOfCompletedTasks /totalTaskAssigned) * 100;
            If (moduleTasks.size() == NumberOfCompletedTasks){
                ModuleCompleted = true;
            }

        }else{
            stepModule.moduleTasks = null;
        }

        stepModule.id = theStepModule.Id;
        stepModule.Adventure_Step_Id = theStepModule.Adventure_Step__c;
        stepModule.title = theStepModule.title__c;
        
        stepModule.order = (Integer)theStepModule.Order__c;
        stepModule.descriptionLabel = theStepModule.Description_Label__c;
        stepModule.descriptionLink = theStepModule.Description_URL__c;
        stepModule.tooltip = theStepModule.Tooltip_Description__c;
        stepModule.taskProgress = taskProgress.setScale(0);
        stepModule.completedFlag = ModuleCompleted;

        return stepModule;
    }
}