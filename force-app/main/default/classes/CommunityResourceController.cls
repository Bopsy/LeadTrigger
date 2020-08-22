public class CommunityResourceController {
    
    //@AuraEnabled
    //public static List<ContentWorkspace> getTabNames(){
        // Get name of ContentWorkspace to display as tab in communityResource
        //List<ContentWorkspace> workSpaceNameList = new List<ContentWorkspace>(); /*where name in ('Products','Markets','Applications')*/ 
        //workSpaceNameList = [SELECT Id,Name FROM ContentWorkspace  ORDER BY Name Desc];
        //return workSpaceNameList;
    //}
    
    /*@AuraEnabled
    public static List<contentFolder> getFolders(Id selectedId){
        // Get the all Folders of Library which is selected on click
        List<contentFolder> conFol = new List<contentFolder>();
        conFol = [SELECT Id,name,ParentContentFolder.Name FROM contentFolder where ParentContentFolder.Name =: selectedId];
        return conFol;
    }*/ 
    
    @AuraEnabled
    public static List<ContentFolderMember> getDocument(Id selectedId){
        // Get the all files of Library which is selected on click
        List<ContentFolderMember> conDocument = new List<ContentFolderMember>();
     // SELECT ChildRecordId FROM ContentFolderMember WHERE ParentContentFolderId = '07H0x000000CanSEAS' ParentContentFolderId is folder name contentFolderId 
        conDocument = [SELECT ChildRecordId,ChildRecord.Title FROM ContentFolderMember WHERE ParentContentFolderId =: selectedId];
        return conDocument;
    } 
    
    /*@AuraEnabled
    public static List<contentFolder> getTabNamesOnLoad(id folderId){
         // Get the all files of Library on load first tab should be selected
          List<contentFolder> conFol = new List<contentFolder>();
            List<ContentWorkspace> workSpaceNameListOnLoad = new List<ContentWorkspace>(); // where name = 'Products'
            workSpaceNameListOnLoad = [SELECT Id,Name FROM ContentWorkspace ORDER BY Name Desc limit 1];
            system.debug(' value is : '+workSpaceNameListOnLoad[0].Id);
            Id selectedId = workSpaceNameListOnLoad[0].Id;
           
            conFol = [SELECT Id,name,ParentContentFolder.Name FROM contentFolder where ParentContentFolder.Name =: selectedId];
            return conFol;
    }
    
    @AuraEnabled
    public static List<contentFolder> getsearch(Id selectedId, String searchingText){ 
       //    List<ContentWorkspace> workSpaceNameListOnLoad = new List<ContentWorkspace>(); 
      //  workSpaceNameListOnLoad = [SELECT Id,Name FROM ContentWorkspace]; 
     //   system.debug(' value is : '+conDocAsset); 
    //    Id selectedId = workSpaceNameListOnLoad[0].Id; 
        List<contentFolder> conFol = new List<contentFolder>();
        conFol = [SELECT Id,name,ParentContentFolder.Name FROM contentFolder where ParentContentFolder.Name =: selectedId and name like :searchingText+'%' ];
        return conFol;
    } */
    
}