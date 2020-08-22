/*
 * Copyright (c) 2020. 7Summits Inc.
 */

@isTest
public with sharing class x7s_Adventure_MyProgressTest {


    @isTest
    public static void testAdventureMyProgressTest(){
        
        x7s_Adventure_MyProgress myAdventureProgress = new x7s_Adventure_MyProgress(); 
        
        myAdventureProgress.totalTasksAssigned = 10;
        myAdventureProgress.totalCompletedTasks = 5;
        myAdventureProgress.adventureProgress = (Decimal.valueOf(myAdventureProgress.totalCompletedTasks) /  Decimal.valueOf(myAdventureProgress.totalTasksAssigned)) * 100;
        
      
        System.assertEquals(myAdventureProgress.totalTasksAssigned,10);
        System.assertEquals( myAdventureProgress.totalCompletedTasks, 5);
        System.assertEquals(myAdventureProgress.adventureProgress,50);
    }
    
}