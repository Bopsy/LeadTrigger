public without sharing class TriggerUtil {
    public static void setLeadError(List<sObject> objs, String emsg) {
        for (sObject o : objs) {
            o.addError(emsg);
        }
    }
}