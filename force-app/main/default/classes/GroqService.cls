public with sharing class GroqService {
    @AuraEnabled
    public static String callGroq(String prompt) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Groq/openai/v1/chat/completions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // This line pulls the API Key securely from the Named Credential 'Password' field
        req.setHeader('Authorization', 'Bearer {!$Credential.Password}');
        
        Map<String, Object> body = new Map<String, Object>();
        body.put('model', 'llama-3.3-70b-versatile');
        
        List<Map<String, String>> messages = new List<Map<String, String>>();
        messages.add(new Map<String, String>{'role' => 'user', 'content' => prompt});
        body.put('messages', messages);
        
        req.setBody(JSON.serialize(body));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> choices = (List<Object>)result.get('choices');
            Map<String, Object> firstChoice = (Map<String, Object>)choices[0];
            Map<String, Object> message = (Map<String, Object>)firstChoice.get('message');
            return (String)message.get('content');
        } else {
            throw new AuraHandledException('Groq API Error: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
}
