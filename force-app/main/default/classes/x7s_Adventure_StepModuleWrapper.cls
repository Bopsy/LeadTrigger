/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_StepModuleWrapper {

    @AuraEnabled public Id id{get;set;}
    @AuraEnabled public Id Adventure_Step_Id{get;set;}
    @AuraEnabled public String title{get;set;}
    @AuraEnabled public Integer order{get;set;}
    @AuraEnabled public String descriptionLabel{get;set;}
    @AuraEnabled public String descriptionLink{get;set;}
    @AuraEnabled public String tooltip{get;set;}
    @AuraEnabled public List<Module_Task__c> moduleTasks {get;set;}
    @AuraEnabled public Double taskProgress {get;set;}
    @AuraEnabled public Boolean completedFlag {get;set;}
    @AuraEnabled public Boolean isLastTask {get;set;}
}