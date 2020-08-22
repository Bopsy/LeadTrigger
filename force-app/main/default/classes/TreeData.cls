public class TreeData {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public String value;
    @AuraEnabled
    public List<TreeData> children {set;get;}
    
    public TreeData(String label,String fieldName,String value){
        this.label=label;
        this.fieldName=fieldName;
         this.value=value;
    }
    
     public TreeData(String label,String fieldName,String value,List<TreeData> children){
        this.label=label;
        this.fieldName=fieldName;
         this.value=value;
         this.children = children;
    }
    
}