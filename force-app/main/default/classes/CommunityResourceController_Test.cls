@isTest(SeeAllData=true)
public class CommunityResourceController_Test {
    /*@isTest(SeeAllData=true)
    static void getTableNamesTest(){
        Test.startTest();
        List<ContentWorkspace> tablenames = CommunityResourceController.getTabNames();
        Test.stopTest();
        System.assertEquals(tablenames!=null, true);
    }*/
    @isTest(SeeAllData=true)
    static void getFoldersTest(){
        Test.startTest();
        /*Id productLib = [SELECT Id,Name FROM ContentWorkspace  WHERE Name ='Products' LIMIT 1].Id;
        List<contentFolder> folder = CommunityResourceController.getFolders(productLib);
        List<ContentFolderMember> document = CommunityResourceController.getDocument(folder[0].Id);
        List<contentFolder> getTabNames  =  CommunityResourceController.getTabNamesOnLoad(folder[0].Id);
        List<contentFolder> getsearch =  CommunityResourceController.getsearch(productLib, 'test');*/
        List<ContentFolderMember> document = CommunityResourceController.getDocument('07H1W000000XeQQUA0');
        Test.stopTest();
        /*System.assertEquals(folder!=null, true);
        System.assertEquals(document!=null, true);*/
    }

}