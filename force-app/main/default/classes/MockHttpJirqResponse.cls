@isTest
global class MockHttpJirqResponse implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
    
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"fields":{"dueDate":"2018-05-01", "summary":"this is a test", "description":"test description", "assignee":{"displayName": "Tester testerson"},"status":{"name":"testing"}}}');
        res.setStatusCode(200);
        return res;
    }
}