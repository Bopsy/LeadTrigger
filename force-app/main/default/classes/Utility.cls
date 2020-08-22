public with sharing class Utility {

	//----------------------------------------------------------------------------------------------------------
	// Returns true if field value is added or changed 
	//----------------------------------------------------------------------------------------------------------
	public static Boolean isNewOrChanged(Sobject obj, String fldName, Map<Id, Sobject> oldMap) {
		if (obj != null && fldName != null && oldMap != null) {
			return ((obj.get(fldName) != oldMap.get((Id)obj.get('id')).get(fldName) ? true : false));
		}
		return (obj.get(fldName) != null);
	}
}