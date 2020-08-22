/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_MyProgress {

    @AuraEnabled public Integer totalTasksAssigned{get;set;} 
    @AuraEnabled public Integer totalCompletedTasks{get;set;}  
    @AuraEnabled public Decimal adventureProgress{get;set;} 
   


    public x7s_Adventure_MyProgress() {
        totalTasksAssigned = 0;
        totalCompletedTasks = 0;
        adventureProgress = 0.0;
    }
}