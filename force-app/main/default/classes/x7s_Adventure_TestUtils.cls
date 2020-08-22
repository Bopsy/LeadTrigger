/*
 * Copyright (c) 2020. 7Summits Inc.
 */
@isTest
public class x7s_Adventure_TestUtils
{
	public x7s_Adventure_TestUtils() {

	}
	
    public static User createStandardUserNoContact(){
		List<Profile> standardProfileList = [SELECT Id FROM Profile WHERE Name = :x7s_Adventure_TestConstants.COMMUNITY_PROFILE];
		User testUser;
		if (!x7s_Adventure_Utils.isNullOrEmpty(standardProfileList)) {
			Profile standardProfile = standardProfileList[0];
			testUser = new User(Alias = x7s_Adventure_TestConstants.STANDARD_ALIAS, Email= x7s_Adventure_TestConstants.STANDARD_EMAIL, EmailEncodingKey= x7s_Adventure_TestConstants.ENCODING, FirstName= x7s_Adventure_TestConstants.FIRSTNAME, LastName= x7s_Adventure_TestConstants.LASTNAME, LanguageLocaleKey= x7s_Adventure_TestConstants.LOCALE,LocaleSidKey= x7s_Adventure_TestConstants.LOCALE, ProfileId = standardProfile.Id,TimeZoneSidKey= x7s_Adventure_TestConstants.TIMEZONE, UserName= x7s_Adventure_TestConstants.STANDARD_USERNAME);
		}

		return testUser;
	}
    
	// Create a standard user
	public static User createStandardUser(){
		Contact contact = createTestContact(); 
		User testUser;

		List<Profile> standardProfileList = [SELECT Id FROM Profile WHERE Name = :x7s_Adventure_TestConstants.COMMUNITY_PROFILE];

		if (!x7s_Adventure_Utils.isNullOrEmpty(standardProfileList)) {
			Profile standardProfile = standardProfileList[0];
			testUser = new User(Alias = x7s_Adventure_TestConstants.STANDARD_ALIAS, Email= x7s_Adventure_TestConstants.STANDARD_EMAIL, EmailEncodingKey= x7s_Adventure_TestConstants.ENCODING, FirstName= x7s_Adventure_TestConstants.FIRSTNAME, LastName= x7s_Adventure_TestConstants.LASTNAME, LanguageLocaleKey= x7s_Adventure_TestConstants.LOCALE,LocaleSidKey= x7s_Adventure_TestConstants.LOCALE, ProfileId = standardProfile.Id,TimeZoneSidKey= x7s_Adventure_TestConstants.TIMEZONE, UserName= x7s_Adventure_TestConstants.STANDARD_USERNAME);
			testUser.ContactId = contact.id;
		}

		return testUser;
	}

	// Create a guest user
	public static User createGuestUser(){
		List<Profile> standardProfileList;
		User guestUser;

		try {
			standardProfileList = [SELECT Id FROM Profile WHERE Name='Standard User'];
		} catch (DmlException e) {
			System.debug(e);
		}

		if (!x7s_Adventure_Utils.isNullOrEmpty(standardProfileList)) {
			Profile standardProfile = standardProfileList[0];
			guestUser = new User(Alias = x7s_Adventure_TestConstants.GUEST_ALIAS, Email= x7s_Adventure_TestConstants.GUEST_EMAIL, EmailEncodingKey= x7s_Adventure_TestConstants.ENCODING, FirstName= x7s_Adventure_TestConstants.FIRSTNAME,LastName= x7s_Adventure_TestConstants.LASTNAME, LanguageLocaleKey= x7s_Adventure_TestConstants.LOCALE,LocaleSidKey= x7s_Adventure_TestConstants.LOCALE, ProfileId = standardProfile.Id,TimeZoneSidKey= x7s_Adventure_TestConstants.TIMEZONE, UserName= x7s_Adventure_TestConstants.GUEST_USERNAME);
		}

		return guestUser;
	}

	// Create an account so we can create a Contact
	public static Account createTestAccount(){
		Account account = new Account(name= x7s_Adventure_TestConstants.ACCOUNT_NAME);
		insert account;
		return account;
	}

	// Create a contact associated with an account
	public static Contact createTestContact(){
		Account account = createTestAccount();
		Contact contact = new Contact(firstName= x7s_Adventure_TestConstants.FIRSTNAME, lastName= x7s_Adventure_TestConstants.LASTNAME, email= x7s_Adventure_TestConstants.STANDARD_EMAIL);
		contact.accountId = account.id;
		insert contact;

		return contact;
	}

	// Create an attachment
	public static Attachment createAttachment(Id parentId){
		Attachment attachment = new Attachment();
		Blob bodyBlob=Blob.valueOf('');
		attachment.ParentId = parentId;
		attachment.body = bodyBlob;
		attachment.Name = x7s_Adventure_TestConstants.FIRSTNAME;
		return attachment;
	}
//
//	// Fake ID
//	public static String getFakeId(Schema.SObjectType sot)
//	{
//		Integer s_num = 1;
//		String result = String.valueOf(s_num++);
//		return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
//	}
//
//	// Internal Chatter Group (No Network Id)
//	public static CollaborationGroup createChatterGroup(String groupName, String collaborationType){
//		CollaborationGroup testGroup = new CollaborationGroup(
//				Name=groupName,
//				CollaborationType=collaborationType
//		);
//		return testGroup;
//	}
//
//	// Community Chatter Group (Has Network Id)
//	// Note: Apex does not allow the creation of a Network(Community) within Tests. The Network Id will need to be
//	// referenced on the fly within the individual org where a Network(Community) already exists
//	public static CollaborationGroup createChatterGroup(String groupName, String collaborationType,String networkId){
//		CollaborationGroup testGroup = new CollaborationGroup(
//				Name=groupName,
//				CollaborationType=collaborationType,
//				NetworkId=networkId
//		);
//		return testGroup;
//	}
//
//	// Chatter Group Membership
//	// Note: when adding a group member, if the group is not attached to a Network(community), then the user must be a
//	// non-community user (Not a partner profile).
//	public static CollaborationGroupMember createGroupMembership(String groupId, Id userId){
//		CollaborationGroupMember groupMembership = new CollaborationGroupMember();
//		groupMembership.CollaborationGroupId = groupId;
//		groupMembership.MemberId = userId;
//		groupMembership.CollaborationRole = 'Standard';
//		return groupMembership;
//	}
//
//	public static Opportunity createOpportunity(Id userId,String forecastCategoryName){
//		Opportunity newOpportunity = new Opportunity(
//				Amount = x7s_Adventure_TestConstants.AMOUNT,
//				OwnerId = userId,
//				ForecastCategoryName = forecastCategoryName,
//				Name = x7s_Adventure_TestConstants.OPP_NAME,
//				StageName = x7s_Adventure_TestConstants.STAGE_NAME,
//				CloseDate = x7s_Adventure_TestConstants.TODAY
//		);
//		return newOpportunity;
//	}
//
//
//	public static List<Topic> createTopics(Integer howMany,Id networkId) {
//		List<topic> topicList = new List<topic>();
//		for(Integer i=0;i<howMany;i++){
//			Topic topicObj = new Topic(Name='Test00' + i, Description='Test',NetworkId = networkId);
//			topicList.add(topicObj);
//		}
//		return topicList;
//	}
//
//	public static TopicAssignment createTopicAssignment(Id strTopicId, Id strEntityId,Id networkId) {
//		TopicAssignment topicAssigmnt = new TopicAssignment(EntityId = strEntityId, TopicId = strTopicId,NetworkId = networkId);
//		return topicAssigmnt;
//	}
//
//	public static List<FeedItem> createFeedItems(Integer howMany,Id networkId,Id parentId){
//		List<FeedItem> feedItems = new List<FeedItem>();
//
//		for(Integer i=0;i<howMany;i++){
//			FeedItem feedItem = new FeedItem();
//			feedItem.Title = x7s_Adventure_TestConstants.TEST_MESSAGE;
//			feedItem.Body = x7s_Adventure_TestConstants.TEST_DESCRIPTION;
//			feedItem.ParentId = parentId;
//			feedItem.NetworkScope = networkId;
//			feedItems.add(feedItem);
//		}
//
//		return feedItems;
//	}
}