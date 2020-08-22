/*
 * Copyright (c) 2020. 7Summits Inc.
 */


public with sharing class x7s_Adventure_MyModuleTaskWrapperHelper {


    public static x7s_Adventure_MyModuleTaskWrapper createWrapper(List<Module_Task__c> tasksList){

        x7s_Adventure_MyModuleTaskWrapper stepModule = new x7s_Adventure_MyModuleTaskWrapper();

        Decimal NumberOfCompletedTasks = 0;
        Decimal totalTaskAssigned = 0;
        Decimal taskProgress = 0 ;
        Boolean ModuleCompleted = false;

        If(tasksList.size() >0){
            for(Module_Task__c myTask:tasksList){
                totalTaskAssigned = totalTaskAssigned+1;
                if(myTask.Completed__c ==true){
                    NumberOfCompletedTasks = NumberOfCompletedTasks +1;
                }
            }
            taskProgress = (NumberOfCompletedTasks /totalTaskAssigned) * 100;
            If (tasksList.size() == NumberOfCompletedTasks){
                ModuleCompleted = true;
            }
            stepModule.TaskProgress = taskProgress.setScale(0);
            stepModule.Completed = ModuleCompleted;
        }
        return stepModule;
    }
}