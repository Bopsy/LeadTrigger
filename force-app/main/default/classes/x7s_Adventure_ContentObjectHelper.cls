/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_ContentObjectHelper
{

    public static x7s_Adventure_ContentObject formatPeakContentObject(Adventure__c theAdventure, List<x7s_Adventure_StepWrapper> theStepWrapper){

        x7s_Adventure_ContentObject contentObject = new x7s_Adventure_ContentObject();
        contentObject.adventure = theAdventure;
        contentObject.adventureStepWrapper = theStepWrapper;

        return contentObject;

    }
}