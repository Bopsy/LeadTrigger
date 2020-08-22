/* 
 * Class:   CompeteAPIClient
 * Purpose: Gets the Compete.com score for a domain
 *
 */
global class CompeteAPIClient {

	/* The following domains will be ignored */
	public static Set<String> getBlacklist() {
		return new Set<String> {
			'126.com',
			'gmx.com',
			'charter.net',
			'cardona.com',
			'dispostable.com',
			'earthlink.net',
			'hushmail.com',
			'libero.it',
			'live.co.uk',
			'mail.com',
			'mail.pf',
			'mail.ru',
			'mailcatch.com',
			'mailinator.com',
			'me.com',
			'twilio.com',
			'rediffmail.com',
			'tiscali.it',
			'freemail.hu',
			'sharklasers.com',
			'gmail.com',
			'orange.fr'
		};
	}


	@future(callout=true)
	public static void futureUpdateLead(String id, String emailDomain) {
		updateLead(id, emailDomain);
	}
	
	@future(callout=true)
	public static void futureUpdateLeads(List<String> ids, List<String> domains) {
		updateLeads(ids,domains);
	}
	
	public static void updateLeads(List<String> ids, List<String> domains) {
		List<Lead> updateLeads = new List<Lead>();
		for (Integer i=0; i<ids.size(); i++) {
			Integer score = CompeteAPIClient.getCompeteScore(domains[i]);
			if (score!=null)
				updateLeads.add(new Lead(Id=ids[i],Compete_Score__c=score));
		}
		if (!updateLeads.isEmpty())
			update updateLeads;
	}
	
	public static void updateLead(String id, String emailDomain) {
		if (emailDomain!=null) {
			Integer score = getCompeteScore(emailDomain);
			if (score!=null)
		  		update new Lead(Id=id,Compete_Score__c=score);
		}
	}

	webservice static Integer getCompeteScore(String domain) {
		Integer score = null;
		if (!getBlacklist().contains(domain)) {
			// http://apps.compete.com/sites/twilio.com/trended/uv/?apikey=ae82a538e549625e5af3145f1f7e1554&latest=1
			String url = 'http://apps.compete.com/sites/'+domain
					+ '/trended/uv/?apikey='+getCompeteApiKey()+'&latest=1';
					
			try {
				String response = doHTTPGet(url);
				score = parseCompeteResponse(response);
				System.debug('CompeteAPIClient : Domain='+domain+'   Score='+score);
			} catch (Exception e) {
				System.debug('Compete Score Exception: '+e.getMessage());
			}
		}
		return score;
	}
	
	private static Integer parseCompeteResponse(String jsonResponse) {
		/*
		  {
		    "status":"OK"
		    "data":{
		      "trends":{
		        "uv":[
		          {
		            "date":"201202",
		            "value":22119
		          }
		        ]
		      },
		      "trends_low_sample":false,
		      "query_cost":1,
		      "trends_frequency":"monthly"
		    }
		  }
		*/
		Integer score = null;
		if (jsonResponse.contains('"status":"OK"')) {
			// parse
			try {
				Map<String,Object> responseMap = TwilioParser.jsonToMap(jsonResponse);
				if (responseMap!=null && responseMap.get('status')=='OK') {
					Map<String,Object> dataMap = (Map<String,Object>)responseMap.get('data');
					if (dataMap!=null) {
						Map<String,Object> trendsMap = (Map<String,Object>)dataMap.get('trends');
						if (trendsMap!=null) {
							List<Object> uvList = (List<Object>)trendsMap.get('uv');
							if (uvList!=null && !uvList.isEmpty()) {
								Map<String,Object> scoreObj = (Map<String,Object>)uvList.get(0);
								score = Integer.valueOf(scoreObj.get('value'));
							}
						}
					}
				}
			} catch (Exception e) {
				System.debug('Parse exception: '+e.getMessage());
			}
		}
		return score;
	}
	 
	private static String doHTTPGet(String url) {
		// Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
	    HttpRequest req = new HttpRequest();
	    req.setEndpoint(url);
	    req.setMethod('GET');
	    
		// Send the request, and return a response
	    Http h = new Http();
		HttpResponse res = h.send(req);
	    return res.getBody();
	}
	
	private static String getCompeteApiKey() {
		    Compete_API_Config__c competeCfg = Compete_API_Config__c.getOrgDefaults();
	    	if (competeCfg==null)
	    		throw new MissingCustomSettingsException('Please enter your Compete API key under custom settings (go to Setup | Develop | Custom Settings | Manage Compete API Config)');
			return competeCfg.APIKey__c;
	}
	
	private class MissingCustomSettingsException extends Exception {}
	
	
	/* TEST METHODS */
	
	static testmethod void test_parseCompeteResponse() {
		
		String json0 = '{"status":"OK","data":{"trends":{"uv":[{"date":"201202","value":22119}]},"trends_low_sample":false,"query_cost":1,"trends_frequency":"monthly"}}';
		Integer score0 = CompeteAPIClient.parseCompeteResponse(json0);
		System.assertEquals(22119, score0);
		
		
		String json1 = '{"status":"OK","data":{"trends":{"uv":[{"date":"201202","value":22119}]},"trends_low_sample":false,"query_cost":1,"trends_frequency":"monthly"}}';
		Integer score1 = CompeteAPIClient.parseCompeteResponse(json1);
		System.assertEquals(22119, score1);
		
		String json2 = '{"status":"OK","data":{"trends":{"uv":[{"date":"201202","value":30123456}]},"trends_low_sample":false,"query_cost":1,"trends_frequency":"monthly"}}';
		Integer score2 = CompeteAPIClient.parseCompeteResponse(json2);
		System.assertEquals(30123456, score2);
	}
}