/*
 * Copyright (c) 2020. 7Summits Inc.
 */
public with sharing class x7s_Adventure_ContentObject
{

    @AuraEnabled public Adventure__c adventure{get;set;}
    @AuraEnabled public List<x7s_Adventure_StepWrapper> adventureStepWrapper{get;set;}

}