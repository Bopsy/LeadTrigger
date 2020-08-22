public class UCISearchController {


    
    public String city {get;set;}
    public String country {get;set;}
    public String employeeSize {get;set;}
    public Id quarterBackId {get;set;}
    public String quarterBackName {get;set;}
    public String teamName {get;set;}
    public String State {get;set;}
    public String ZipCode {get;set;}
    public String zipCodeFloor {get;set;}
    public String zipCodeCeiling {get;set;}
    public Id groupId {get;set;}
    public Id memberId {get;set;}
    public Lead newLead {get; set;}
    public Id specialistId {get; set;}
    public String specialistName {get; set;}
    public Id oppOwnerId {get;set;}
    public String ownerName {get;set;}
    public Boolean authyProduct {get; set;}

	public Boolean debugMode {get;set;}
	
    public UCISearchController() {
        debugMode = (Apexpages.currentPage().getParameters().get('debug') != null);
        newLead = new Lead();
    }

    // fired when the search button is clicked
    public PageReference runSearch() {
        employeeSize = Apexpages.currentPage().getParameters().get('employeeSize');
		state = Apexpages.currentPage().getParameters().get('state');
		country = Apexpages.currentPage().getParameters().get('country');
		zipCode = Apexpages.currentPage().getParameters().get('zipCode');
        
		System.debug('runSearch(' + employeeSize + ', ' + state + ', ' + country + ', ' + zipCode + ')');
        getRoutingInfo(employeeSize, state, country, zipCode);

        return null;
    }

    // get the routing information
    public void getRoutingInfo(String employeeSize, String state, String country, String zipCode) {
    	OpportunityRoutingServices.OppWrapper oppData = new OpportunityRoutingServices.OppWrapper();
    	oppData.employeeSize = employeeSize;
        oppData.State = state;
        oppData.Country = country;
        oppData.ZipCode = zipCode;
        oppData.AESwitch = false;
        oppData.ignoreAE = true;
        oppData.product = '.*';
        oppData.AEOwner = UserInfo.getUserId();
	
		System.debug(oppData);
					
	    OpportunityRoutingServices.OppSettingWrapper oppOwner = OpportunityRoutingServices.findOppOwner(oppData);
		if(oppOwner != null) OpportunityRoutingServices.getRoundRobinOwnerId(oppOwner);	
		System.debug(oppOwner);

			
		if (oppOwner != null) {
			city = oppOwner.city;
	        country = oppOwner.country;
	        employeeSize = oppOwner.employeeSize;
	        quarterBackId = oppOwner.oppOwnerId;
	        teamName = oppOwner.teamName;
	        state = oppOwner.state;
	        zipCode = oppOwner.zipCode;
	        quarterBackName = oppOwner.ownerName;
	        zipCodeFloor = oppOwner.zipCodeFloor;
	        zipCodeCeiling = oppOwner.zipCodeCeiling;
	        groupId = oppOwner.groupId;
	        memberId = oppOwner.memberId;

	        oppData.AEOwner = oppOwner.oppOwnerId;

			oppOwner = OpportunityRoutingServices.findOppOwner(oppData);
			if(oppOwner != null) OpportunityRoutingServices.getRoundRobinOwnerId(oppOwner);
			if (oppOwner != null) {	
				oppOwnerId = oppOwner.oppOwnerId;
				ownerName = oppOwner.ownerName;
			}
    
			System.debug(oppOwner);
			
			if(authyProduct){
			    oppData.product = '.*';
			    oppData.solutionCategory = 'Account Security';
			    
			    OpportunityRoutingServices.OppSettingWrapper specialistOwner = OpportunityRoutingServices.findSpecialist(oppData);
			    if(specialistOwner != null){
			        specialistId = specialistOwner.specialistId;
			        specialistName = specialistOwner.specialistName;
			    }
			}
		}
    }

	// Build select options
	public List<SelectOption> employeeSizeOptions {
		get {
			if (employeeSizeOptions == null) {
				employeeSizeOptions = new List<SelectOption>();
				employeeSizeOptions.add(new SelectOption('Under 1,000', 'Under 1,000'));
				employeeSizeOptions.add(new SelectOption('1,001-2,500', '1,001-2,500'));
				employeeSizeOptions.add(new SelectOption('2,501+', '2,501+'));
			}
			return employeeSizeOptions;
		}
		set;
	}
}