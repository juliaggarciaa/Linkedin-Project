public with sharing class TailoredResumeController {
    @AuraEnabled
    public static void generateDocs(Id suggestionId) {
        Job_Suggestion__c sugg = [SELECT Role_Title__c, Company_Name__c, Skill_Gap__c FROM Job_Suggestion__c WHERE Id = :suggestionId LIMIT 1];
        My_Resume__c resume = [SELECT Skills__c, Experience_Summary__c FROM My_Resume__c ORDER BY CreatedDate DESC LIMIT 1];
        
        String prompt = 'Generate a tailored resume, cover letter, and LinkedIn outreach message for the role: ' + sugg.Role_Title__c + 
                      ' at ' + sugg.Company_Name__c + '. Use this base resume: ' + resume.Experience_Summary__c + 
                      '. Return ONLY JSON with keys: "resume", "coverLetter", "outreach".';
        
        String response = GroqService.callGroq(prompt);
        if (response.contains('```')) {
            response = response.substringAfter('json').substringBeforeLast('```').trim();
        }
        
        Map<String, Object> parsed = (Map<String, Object>)JSON.deserializeUntyped(response);
        sugg.Tailored_Resume__c = (String)parsed.get('resume');
        sugg.Cover_Letter__c = (String)parsed.get('coverLetter');
        sugg.Outreach_Message__c = (String)parsed.get('outreach');
        update sugg;
    }
}