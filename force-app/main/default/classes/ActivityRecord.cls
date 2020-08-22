global class ActivityRecord implements Comparable {

    public Id Id {get;set;}
    public Date ActivityDate {get;set;}
    public String Subject {get;set;}
    public String Description {get;set;}
    public Boolean IsTask {get;set;}
    public String Status {get;set;}
    public Id OwnerId {get;set;}
    public String OwnerName {get;set;}
    public DateTime LastModifiedDate {get;set;}
    public DateTime CreatedDate {get;set;}

    public ActivityRecord(OpenActivity activity) {
        Id = activity.Id;
        ActivityDate = activity.ActivityDate;
        Subject = activity.Subject;
        Description = activity.Description;
        IsTask = activity.IsTask;
        Status = activity.Status;
        OwnerId = activity.OwnerId;
        OwnerName = activity.Owner.Name;
        LastModifiedDate = activity.LastModifiedDate;
        CreatedDate = activity.CreatedDate;
    }
    
    public ActivityRecord(ActivityHistory activity) {
        Id = activity.Id;
        ActivityDate = activity.ActivityDate;
        Subject = activity.Subject;
        Description = activity.Description;
        IsTask = activity.IsTask;
        Status = activity.Status;
        OwnerId = activity.OwnerId;
        OwnerName = activity.Owner.Name;
        LastModifiedDate = activity.LastModifiedDate;
        CreatedDate = activity.CreatedDate;
    }    
    
    // Compare ActivityRecords based on the ActivityDate but in descending order.
    global Integer compareTo(Object compareTo) {
        ActivityRecord compareToRecord = (ActivityRecord)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (ActivityDate < compareToRecord.ActivityDate) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (ActivityDate < compareToRecord.ActivityDate) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}