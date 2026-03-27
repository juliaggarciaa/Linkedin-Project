public with sharing class GroqService {
    public static String callGroq(String prompt) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Groq/openai/v1/chat/completions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        
        Map<String, Object> body = new Map<String, Object>{
            'model' => 'llama-3.3-70b-versatile',
            'messages' => new List<Object>{
                new Map<String, String>{ 'role' => 'user', 'content' => prompt }
            }
        };
        req.setBody(JSON.serialize(body));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            List<Object> choices = (List<Object>)responseMap.get('choices');
            Map<String, Object> firstChoice = (Map<String, Object>)choices[0];
            Map<String, Object> message = (Map<String, Object>)firstChoice.get('message');
            return (String)message.get('content');
        } else {
            throw new CalloutException('Groq API Error: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
}
