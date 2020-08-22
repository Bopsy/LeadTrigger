/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_StepModuleWrapperHelper {

    public static x7s_Adventure_StepModuleWrapper createWrapper(Step_Module__c theStepModule, List<Module_Task__c> moduleTasks){

        Decimal taskProgress = 0 ;
        x7s_Adventure_StepModuleWrapper stepModule = new x7s_Adventure_StepModuleWrapper();   
        stepModule.id = theStepModule.Id;
        stepModule.Adventure_Step_Id = theStepModule.Adventure_Step__c;    
        stepModule.title = theStepModule.title__c;
        //stepModule.moduleTasks = moduleTasks;
        stepModule.order = (Integer)theStepModule.Order__c;    
        stepModule.descriptionLabel = theStepModule.Description_Label__c;
        stepModule.descriptionLink = theStepModule.Description_URL__c;
        stepModule.tooltip = theStepModule.Tooltip_Description__c;     
        //Module progress
        stepModule.completedFlag = theStepModule.Completed__c;
        If(moduleTasks.size() > 0){
            stepModule.moduleTasks = moduleTasks;
            stepModule.taskProgress = theStepModule.Task_Progress__c.setScale(0);
        }else{
            stepModule.moduleTasks = null;
            stepModule.taskProgress =taskProgress.setScale(0);
        }

        return stepModule;
    }

}