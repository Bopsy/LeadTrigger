/*
 * Copyright (c) 2020. 7Summits Inc.
 */

trigger adventureDocLinkTrigger on ContentDocumentLink (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Trigger.isUpdate || Trigger.isInsert && Trigger.isBefore) {
        x7s_AdventureDocLinkTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}