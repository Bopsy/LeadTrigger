public class AgreementAllFieldsForTestOnly {

    public static void getAllFields(){
        Map <String, Schema.SObjectField> mapObjField = Apttus__APTS_Agreement__c.sObjectType.getDescribe().fields.getMap();
 
		String strfieldName = ''; //empty string to store the field names
 
        for(Schema.SObjectField field : mapObjField.Values()) {
            Schema.DescribeFieldResult fieldRes = field.getDescribe();
            system.debug('fieldRes=>'+fieldRes);
            if(fieldRes.isAccessible()){
                strfieldName += fieldRes.getName() + ',';
            }
        }
 		system.debug('strfieldName=>'+strfieldName);
		strfieldName = strfieldName.substring(0, strfieldName.length()-1);
        system.debug('strfieldName1=>'+strfieldName);
		List<Apttus__APTS_Agreement__c> theNewAgrmntList = Database.query('select ' + strfieldName + ' from Apttus__APTS_Agreement__c');
        
    }
}