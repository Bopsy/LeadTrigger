/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@IsTest
private class x7s_AdventureDocLinkTriggerHandlerTest {
    @testSetup
    static void testSetup() {
        Adventure__c testAdventure = new Adventure__c(Name = x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME, Title__c = x7s_Adventure_TestConstants.TEST_ADVENTURE_NAME);
        insert testAdventure;

        Account testAccount = new Account();
        testAccount = x7s_Adventure_TestUtils.createTestAccount();

        String base64Data = EncodingUtil.urlDecode(x7s_Adventure_TestConstants.BASE64FILE, 'UTF-8');

        ContentVersion fileVersion = new ContentVersion();
        fileVersion.versionData = EncodingUtil.base64Decode(base64Data);
        fileVersion.title = x7s_Adventure_TestConstants.FILENAME;
        fileVersion.pathOnClient ='/' + x7s_Adventure_TestConstants.FILENAME;
        fileVersion.ContentLocation = 'S';
        fileVersion.IsMajorVersion = false;
        insert fileVersion;
    }
    @IsTest
    static void accountLinkTest() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1][0];
        ContentVersion uploadedFile  = [SELECT Id, ContentDocumentId FROM ContentVersion];
        ContentDocumentLink fileLink = new ContentDocumentLink();
        fileLink.ContentDocumentId = uploadedFile.ContentDocumentId;
        fileLink.LinkedEntityId = testAccount.Id;
        fileLink.ShareType = 'I';
        insert fileLink;
        ContentDocumentLink resultLink = [SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :fileLink.Id];
        System.assertNotEquals('AllUsers',resultLink.Visibility);
    }
    @IsTest
    static void quickLinkTest() {
        Adventure__c testLink = [SELECT Id FROM Adventure__c LIMIT 1][0];
        ContentVersion uploadedFile  = [SELECT Id, ContentDocumentId FROM ContentVersion];
        ContentDocumentLink fileLink = new ContentDocumentLink();
        fileLink.ContentDocumentId = uploadedFile.ContentDocumentId;
        fileLink.LinkedEntityId = testLink.Id;
        fileLink.ShareType = 'I';
        insert fileLink;
        ContentDocumentLink resultLink = [SELECT Id, Visibility FROM ContentDocumentLink WHERE Id = :fileLink.Id];
        System.assertEquals('AllUsers',resultLink.Visibility);
    }
}