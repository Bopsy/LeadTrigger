/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_StepWrapper {

    @AuraEnabled public Id id{get;set;}
    @AuraEnabled public String stepName{get;set;}
    @AuraEnabled public String title{get;set;}
    @AuraEnabled public String subtitle{get;set;}
    @AuraEnabled public Decimal order{get;set;}
    @AuraEnabled public String iconImage{get;set;}
    @AuraEnabled public List<ContentDocumentLink> contentDocumentLinks {get;set;}
    @AuraEnabled public List<x7s_Adventure_StepModuleWrapper> stepModuleWrapperList{get;set;}
    

}