/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@isTest
public with sharing class x7s_Adventure_ContentObjectHelperTest
{

    @isTest
    public static void testFormatPeakContentObject() {
        // Create a Peak Content Object from helper
        x7s_Adventure_ContentObjectHelper contentObjectHelper = new x7s_Adventure_ContentObjectHelper();
        x7s_Adventure_ContentObject testObject = x7s_Adventure_ContentObjectHelper.formatPeakContentObject(null,null);

        // Assert its name property was set
        System.assertEquals(testObject.adventure, null);
    }


}