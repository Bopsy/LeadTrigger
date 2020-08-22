trigger CountryPhoneNumberInterestTrigger on Opportunity_Country_Number__c (before insert) {
    CountryPhoneNumTypeHandler.linkToCountryPhoneNumberType(trigger.new, false);
}