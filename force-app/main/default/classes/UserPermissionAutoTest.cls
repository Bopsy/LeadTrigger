@isTest
public class UserPermissionAutoTest {
    private static testMethod void test() {
	    Profile p = [SELECT Id, Name FROM Profile WHERE Name='**Global AM']; 
        System.debug('===> gobalAM Profile: ' + p.id);
        
        insert new PermissionAutoSetting__c(SetupOwnerId=UserInfo.getOrganizationId(), name='**Global AM',Profile_ID__c=p.id,Library_ID__c='05840000000XcUIAA0',
                                            Library_Permission_ID__c='05P40000000GnUbEAK',
                                            Permission_ID_List__c ='0PS40000000bV59GAE,0PS1W000000TNEaWAO,0PS40000000fgNDGAY,0PS40000000bVJBGA2',
                                            Package_ID_List__c='05040000000blo2AAA,05040000000XZjAAAW,0501W000000CzsiQAC,0501W000000CzsnQAC,0501W000000CzsdQAC');
        
        System.runAs(new user(ID = UserInfo.getUserID())) { 
            Test.startTest();
            User u = new User(Alias = 'standmia', Email='ncui111091@twilio.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = '00e400000014Iym', 
                              TimeZoneSidKey='America/Los_Angeles', UserName='ramdonguyy@123.com');
            
            insert u;
            Test.stopTest();
            
            User miauser = [SELECT ID, Profile.Name FROM USER WHERE Alias = 'standmia' limit 1];
            System.debug('===> miauser Profile: ' + miauser.Profile.Name);
            
            List<PermissionSetAssignment> lstcurrentUserPerSet= [   SELECT Id, PermissionSet.Name,AssigneeId
                                                                 FROM PermissionSetAssignment
                                                                 WHERE AssigneeId = :miauser.id ];
            
            List<ContentWorkspaceMember> lstcurrentUserlibSet = [ SELECT ContentWorkspaceId, MemberId 
                                                                 FROM ContentWorkspaceMember
                                                                 WHERE MemberId = :miauser.id ];                                          
            System.assertEquals(5, lstcurrentUserPerSet.size(), 'The permission set assignments should be created as 5');
            System.assertEquals(1, lstcurrentUserlibSet.size(), 'The library assignments should be created as 1');
            
            List<UserPackageLicense> userPackageListExist = [ SELECT id, PackageLicenseid, Userid
                                                             FROM UserPackageLicense
                                                             WHERE UserId =: u.id ];
            
            System.assertEquals(5, userPackageListExist.size(), 'The package assignments should be created as 5');
        }

	}
    
    private static testMethod void negativeTest() {
        Profile marketing = [SELECT Id FROM Profile WHERE Name='**Marketing']; 
        insert new PermissionAutoSetting__c(SetupOwnerId=UserInfo.getOrganizationId(), name='**Global AM',Profile_ID__c='00e400000014IymAAE',Library_ID__c='05840000000XcUIAA0',
                                            Library_Permission_ID__c='05P40000000GnUbEAK',
                                            Permission_ID_List__c ='0PS40000000bV59GAE,0PS1W000000TNEaWAO,0PS40000000fgNDGAY,0PS40000000bVJBGA2',
                                            Package_ID_List__c='05040000000blo2AAA,05040000000XZjAAAW,0501W000000CzsiQAC,0501W000000CzsnQAC,0501W000000CzsdQAC');
        System.runAs(new user(ID = UserInfo.getUserID())) { 
            Test.startTest();
            User u = new User(Alias = 'standt', Email='ncui11101@twilio.com', 
                              EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                              LocaleSidKey='en_US', ProfileId = marketing.Id, 
                              TimeZoneSidKey='America/Los_Angeles', UserName='ramdonguy@123.com');
            
            insert u;
            Test.stopTest();
            
            List<PermissionSetAssignment> lstcurrentUserPerSet= [   SELECT Id, PermissionSet.Name,AssigneeId
                                                                 FROM PermissionSetAssignment
                                                                 WHERE AssigneeId = :u.id ];
            
            List<ContentWorkspaceMember> lstcurrentUserlibSet = [ SELECT ContentWorkspaceId, MemberId 
                                                                 FROM ContentWorkspaceMember
                                                                 WHERE MemberId = :u.id ];                                          
            System.assertEquals(1, lstcurrentUserPerSet.size(), 'The permission set assignments should be created as 1');
            System.assertEquals(0, lstcurrentUserlibSet.size(), 'The library assignments should be created as 0');
            
            List<UserPackageLicense> userPackageListExist = [ SELECT id, PackageLicenseid, Userid
                                                             FROM UserPackageLicense
                                                             WHERE UserId =: u.id ];
            
            System.assertEquals(0, userPackageListExist.size(), 'The package assignments should be created as 5');
        }
	}

}