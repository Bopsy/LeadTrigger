@isTest
private class BatchSLAHoursCalculationTest
{
    static testMethod void testBatchSLAHoursCalculation_SlaTimeInHoursReporting(){
        String timeZoneKey = 'America/Los_Angeles';
        User user = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
        //user.TimeZoneSidKey = timeZoneKey;
        //insert user;
        FSR__c mql = new FSR__c();
        
        Blob blobKey = Crypto.GenerateAESKey(128);
        String hexKey = EncodingUtil.ConvertTohex(blobKey);
        String uniqueKey = hexKey.substring(hexKey.length() - (hexKey.length()/4));
        
        mql.name = uniqueKey;
        mql.FSR_Key__c = uniqueKey;
        mql.OwnerId = user.Id;
        mql.SLA_Start_Time__c = DateTime.newInstanceGMT(1996, 1, 8, 9, 0, 0);
        mql.Dispositioned_Date__c = DateTime.newInstanceGMT(1996, 1, 9, 10, 15, 0);
        
        insert mql;
        
        Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(new List<String>{timeZoneKey});
        BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZoneKey);
        
        Double mqlExpectedResult = ((double)BusinessHours.diff(bHours.id, mql.SLA_Start_Time__c, mql.Dispositioned_Date__c) / 1000 / 60 / 60);
        
        Test.startTest();
        BatchSLAHoursCalculation batch = new BatchSLAHoursCalculation(1);
        database.executebatch(batch);
        Test.stopTest();
        
        List<FSR__c> mqlList = getMQLs();
        
        //System.assertEquals(mqlExpectedResult, mqlList[0].SLA_Time_in_Hours_Batch__c);
    }
    
    static testMethod void testBatchSLAHoursCalculation_USTimeZone()
    {
        String timeZoneKey = 'America/Los_Angeles';
        User user = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
        //user.TimeZoneSidKey = timeZoneKey;
        //insert user;
        List<FSR__c> mqlList = null;
        
        Integer counter = 10;
        
        mqlList = TestDataFactory.createFSRList(counter);
        for(FSR__c mql :mqlList)
        {
            mql.OwnerId = user.Id;
        }
        insert mqlList;
        
        //Fetch MQL from DB as we need SLA_Start_Time__c,OwnerId fields
        mqlList = getMQLs();
        
        Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(new List<String>{timeZoneKey});
        BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZoneKey);
        Map<Id, Datetime> mqlIdToExpectedSLATimeMap = new Map<Id, Datetime>();
        
        for(FSR__c mql :mqlList)
        {
            mqlIdToExpectedSLATimeMap.put(mql.Id, BusinessHours.nextStartDate(bHours.id, mql.CreatedDate));
        }
        
        Test.startTest();
        BatchSLAHoursCalculation batch = new BatchSLAHoursCalculation(1);
        database.executebatch(batch);
        Test.stopTest();
        
        List<FSR__c> updatedMqlList = getMQLs();
        
        System.assertEquals(mqlList.size(), updatedMqlList.size());
        
        for(FSR__c mql :updatedMqlList)
        {
            //System.assertEquals(mqlIdToExpectedSLATimeMap.get(mql.Id), mql.SLA_Start_Time__c);
        }
    }
    
    static testMethod void testBatchSLAHoursCalculation_DefaultHoursFallback()
    {
        String timeZoneKey = 'America/New_York';
        User user = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
        //user.TimeZoneSidKey = timeZoneKey;
        //insert user;
        List<FSR__c> mqlList = null;
        
        Integer counter = 1;
        
        mqlList = TestDataFactory.createFSRList(counter);
        for(FSR__c mql :mqlList)
        {
            mql.OwnerId = user.Id;
        }
        insert mqlList;
        
        //Fetch MQL from DB as we need SLA_Start_Time__c,OwnerId fields
        mqlList = getMQLs();
        
        Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(new List<String>{timeZoneKey});
        BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZoneKey);
        Map<Id, Datetime> mqlIdToExpectedSLATimeMap = new Map<Id, Datetime>();
        for(FSR__c mql :mqlList)
        {
            mqlIdToExpectedSLATimeMap.put(mql.Id, BusinessHours.nextStartDate(bHours.id, mql.CreatedDate));
        }
        
        Test.startTest();
        BatchSLAHoursCalculation batch = new BatchSLAHoursCalculation();
        database.executebatch(batch);
        Test.stopTest();
        
        List<FSR__c> updatedMqlList = getMQLs();
        
        System.assertEquals(mqlList.size(), updatedMqlList.size());
        
        for(FSR__c mql :updatedMqlList)
        {
            //System.assertEquals(mqlIdToExpectedSLATimeMap.get(mql.Id), mql.SLA_Start_Time__c);
        }
    }
    
    static testMethod void testBatchSLAHoursCalculation_BulkTest()
    {
        List<String> timeZoneKeyList = new List<String>{'Asia/Seoul', 'America/Los_Angeles'};
            
            Map<String, List<FSR__c>> timeZoneToMqlMap = new Map<String, List<FSR__c>>();
        Integer counter = 1;
        
        for(String timeZoneKey :timeZoneKeyList)
        {
            User user = [SELECT Id, TimeZoneSidKey FROM User Limit 1];
            //user.TimeZoneSidKey = timeZoneKey;
            //insert user;
            
            List<FSR__c> mqlList = TestDataFactory.createFSRList(counter);
            for(FSR__c mql :mqlList)
            {
                mql.OwnerId = user.Id;
            }
            insert mqlList;
            mqlList = [ SELECT Id, CreatedDate FROM FSR__c WHERE Id IN :mqlList ];
            
            timeZoneToMqlMap.put(timeZoneKey, mqlList);
        }
        
        Map<Id, Datetime> mqlIdToExpectedSLATimeMap = new Map<Id, Datetime>();
        Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(timeZoneKeyList);
        for(String timeZoneKey : timeZoneKeyList)
        {
            BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZoneKey);
            for(FSR__c mql :timeZoneToMqlMap.get(timeZoneKey))
            {
                mqlIdToExpectedSLATimeMap.put(mql.Id, BusinessHours.nextStartDate(bHours.id, mql.CreatedDate));
            }
        }
        
        Test.startTest();
        BatchSLAHoursCalculation batch = new BatchSLAHoursCalculation(1);
        database.executebatch(batch);
        Test.stopTest();
        
        List<FSR__c> updatedMqlList = getMQLs();
        
        System.assertEquals(mqlIdToExpectedSLATimeMap.keySet().size(), updatedMqlList.size());
        
        //for(FSR__c mql :updatedMqlList)
        //{
            //System.assertEquals(mqlIdToExpectedSLATimeMap.get(mql.Id), mql.SLA_Start_Time__c);
        //}
    }
    
    private static List<FSR__c> getMQLs()
    {
        return [SELECT Id,Name,CreatedDate,SLA_Start_Time__c,SLA_Changed__c,OwnerId,Dispositioned_Date__c,SLA_Time_in_Hours_Batch__c from FSR__c];
    }
    
    static testMethod void testSchedule()
    {
        final String CRON_EXP = '0 0 * * * ?';
        
        Test.startTest();
        
        Id jobId = System.schedule('SLA Batch - Hourly Test', CRON_EXP, new BatchSLAHoursCalculation());
        
        Test.stopTest();
        
        CronTrigger cronTrigger = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(CRON_EXP, cronTrigger.CronExpression, 'The scheduled CRON expression should match what was configured');
    }
    
    static testMethod void testBatchSLAHoursCalculation_SLAChanged() {
      String timeZoneKey = 'America/Los_Angeles';
        User user = [SELECT Id, TimeZoneSidKey FROM User WHERE TimeZoneSidKey = :timeZoneKey AND IsActive = true Limit 1];
        //user.TimeZoneSidKey = timeZoneKey;
        //insert user;
        FSR__c mql = new FSR__c();
        
        Blob blobKey = Crypto.GenerateAESKey(128);
        String hexKey = EncodingUtil.ConvertTohex(blobKey);
        String uniqueKey = hexKey.substring(hexKey.length() - (hexKey.length()/4));
        
        mql.name = uniqueKey;
        mql.FSR_Key__c = uniqueKey;
        mql.OwnerId = user.Id;
        mql.SLA_Start_Time__c = System.now();
        mql.Dispositioned_Date__c = System.now();
        insert mql;
        List<FSR__c> mqlList = getMQLs();
        System.assertEquals(True, mqlList[0].SLA_Changed__c);
        Map<String, BusinessHours> timeZoneToBusinessHoursMap = BatchUtils.getBusinessHours(new List<String>{timeZoneKey});
        BusinessHours bHours = timeZoneToBusinessHoursMap.get(timeZoneKey);
        
        Double mqlExpectedResult = ((double)BusinessHours.diff(bHours.id, mql.SLA_Start_Time__c, mql.Dispositioned_Date__c) / 1000 / 60 / 60);
        
        Test.startTest();
        BatchSLAHoursCalculation batch = new BatchSLAHoursCalculation(1);
        database.executebatch(batch);
        Test.stopTest();
        
        mqlList = getMQLs();
        System.assertEquals(False, mqlList[0].SLA_Changed__c);
    }
    
}