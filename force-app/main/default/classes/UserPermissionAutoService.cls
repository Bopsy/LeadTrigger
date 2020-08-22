/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           UserPermissionAutoService
*
* @description    helper that automatically give **GlobalAM user Apttus_CLM_Sales_User 
				  and Apttus_CPQ_Twilio permission sets/Library/package
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2019-07-15
* @modified       2019-09-03
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes add packageLicense Assginment
*
**/

public class UserPermissionAutoService {
    @TestVisible
    public static Boolean bypassTrigger = false;
    
    public static void afterInsert(List<User> records){
        if(bypassTrigger) return;
        
        Map<String, PermissionAutoSetting__c> profileMAP = PermissionAutoSetting__c.getAll();
        if (profileMAP == NULL || profileMAP.values() == NULL) return;
        
        //newProfileMAP==>  Key: Profile IDs ; Value: PermissionAutoSetting__c data
        Map<String, PermissionAutoSetting__c> newProfileMAP = new Map<String, PermissionAutoSetting__c>();
        for(PermissionAutoSetting__c profileData: profileMAP.values()) {
            newProfileMAP.put(profileData.Profile_ID__c, profileData);
        }
        
        if(newProfileMAP.keySet() == NULL) return;    
        List<User> filterUser = filterRecords(records, newProfileMAP.keySet());
        //exit if there is no qulified user
        if(filterUser.size() == 0) return;
            
        assignPermission(filterUser, newProfileMAP);
        assignLibrary(filterUser, newProfileMAP); 
        assignPackage(filterUser, newProfileMAP);
    }
    
    public static void afterUpdate(List<User> records){
        if(bypassTrigger) return;
        
        Map<String, PermissionAutoSetting__c> profileMAP = PermissionAutoSetting__c.getAll();
        if (profileMAP == NULL || profileMAP.values() == NULL) return;
        
        //newProfileMAP==>  Key: Profile IDs ; Value: PermissionAutoSetting__c data
        Map<String, PermissionAutoSetting__c> newProfileMAP = new Map<String, PermissionAutoSetting__c>();
        for(PermissionAutoSetting__c profileData: profileMAP.values()) {
            newProfileMAP.put(profileData.Profile_ID__c, profileData);
        }
        
        if(newProfileMAP.keySet() == NULL) return;    
        List<User> filterUser = filterRecords(records, newProfileMAP.keySet());
        //exit if there is no qulified user
        if(filterUser.size() == 0) return;
            
        assignPermission(filterUser, newProfileMAP);
        assignLibrary(filterUser, newProfileMAP); 
        assignPackage(filterUser, newProfileMAP);
    }
    
    @TestVisible
    private static List<User> filterRecords(List<User> newRecords, Set<String> profileIdSet) {
        List<User> result = new List<User>();
        
        for (User newRec : newRecords) {
            if (newRec.ProfileID != NULL && profileIdSet.contains(newRec.ProfileID) && newRec.isactive == true ) {
                result.add(newRec);
            }
        }
        return result;
    }
    
    @TestVisible
    private static void assignLibrary(List<User> records, Map<String, PermissionAutoSetting__c> newProfileMAP) {
        if(records == NULL || records.size() == 0) return;
        List<ContentWorkspaceMember> userLibraryListRet = new List<ContentWorkspaceMember>();
        List<ContentWorkspaceMember> userLibraryListExist = [ SELECT ContentWorkspaceId, MemberId 
                                                              FROM ContentWorkspaceMember
                                                              WHERE MemberId IN: records ];
        Set<String> lib = new Set<String>();
        for (ContentWorkspaceMember content: userLibraryListExist) {
            lib.add(content.ContentWorkspaceId + '-' + content.MemberId);
        }
        
        
        for(User newUser: records) {
            if (newUser.ProfileID == NULL) continue;
            PermissionAutoSetting__c profileData = newProfileMAP.get(newUser.ProfileID);
            if (profileData == NULL || profileData.Library_ID__c == NULL 
                || profileData.Library_Permission_ID__c == NULL) continue;
            String check = profileData.Library_ID__c + '-' + newUser.Id;
            if (!lib.contains(check)) {
                userLibraryListRet.add(new ContentWorkspaceMember(ContentWorkspaceId = profileData.Library_ID__c , 
                                       MemberId = newUser.id,
                                       ContentWorkspacePermissionId = profileData.Library_Permission_ID__c));
            }
        }
        database.insert(userLibraryListRet,false);
    }
        
    
    @TestVisible
    private static void assignPermission(List<User> records, Map<String, PermissionAutoSetting__c> newProfileMAP) {
        //exit if there is no **GLOBAL-AM user
        if(records == NULL || records.size() == 0) return;
        
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        
        List<PermissionSetAssignment> lstUserPerSet = [ SELECT Id, PermissionSetId, AssigneeId
                                                        FROM PermissionSetAssignment
                                                        WHERE AssigneeId IN: records ];
        Set<String> psa = new Set<String>();
        for(PermissionSetAssignment perSet: lstUserPerSet) {
            psa.add(perSet.PermissionSetId + '-' + perSet.AssigneeId);
        }
       
        for (User newUser: records) {
            if (newUser.ProfileID == NULL) continue;
            PermissionAutoSetting__c profileData = newProfileMAP.get(newUser.ProfileID);
            if (profileData == NULL || profileData.Permission_ID_List__c == NULL) continue;
            
            List<String> permissions = profileData.Permission_ID_List__c.split(',');
            for (String permissionID: permissions) {
                String check = permissionID + '-' + newUser.Id;
                if (!psa.contains(check)) {
                    permissionSetList.add(new PermissionSetAssignment(PermissionSetId = permissionID, 
                                                                      AssigneeId = newUser.Id));
                }
            }
            
        }
        insert permissionSetList;
         
    	
    	
    }
    
    @TestVisible
    private static void assignPackage(List<User> records, Map<String, PermissionAutoSetting__c> newProfileMAP) {
        if(records == NULL || records.size() == 0) return;
        
        //list of package wanna to be inserted
        List<UserPackageLicense> userPackageListRet = new List<UserPackageLicense> ();
        
        //list of packages users already had
        List<UserPackageLicense> userPackageListExist = [ SELECT id, PackageLicenseid, Userid
                                                  		  FROM UserPackageLicense
                                                  	      WHERE UserId IN: records ];
                
        Set<String> pck = new Set<String>();
        for(UserPackageLicense packageAssignment: userPackageListExist) {
            pck.add(packageAssignment.PackageLicenseid + '-' + packageAssignment.UserId);
        }
        
        
        for (User newUser: records) {
            if (newUser.ProfileID == NULL) continue;
            PermissionAutoSetting__c profileData = newProfileMAP.get(newUser.ProfileID);
            if (profileData == NULL || profileData.Package_ID_List__c == NULL) continue;
            
            List<String> lstPackagesIDs = profileData.Package_ID_List__c.split(',');
            for (String packagesID: lstPackagesIDs) {
                String check = packagesID + '-' + newUser.Id;
                if (!pck.contains(check)) {
                    userPackageListRet.add(new UserPackageLicense(
                            			   PackageLicenseid = packagesID, UserId = newUser.Id));
                }
            }
            
        }
        database.insert(userPackageListRet,false);
    }
    
}