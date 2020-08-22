/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_StepWrapperHelper {

    public static x7s_Adventure_StepWrapper createWrapper(Adventure_Step__c theStep, List<x7s_Adventure_StepModuleWrapper> theStepModuleList){

        x7s_Adventure_StepWrapper stepWrapper = new x7s_Adventure_StepWrapper();

        stepWrapper.id = theStep.Id;
        stepWrapper.stepName = theStep.title__c;
        stepWrapper.title = theStep.subtitle__c;
        stepWrapper.subtitle = theStep.description__c;
        stepWrapper.order = theStep.Order__c;
        stepWrapper.iconImage = theStep.Icon_Image__c;
        stepWrapper.contentDocumentLinks = theStep.ContentDocumentLinks;
        stepWrapper.stepModuleWrapperList = theStepModuleList;       

        return stepWrapper;
    }

}