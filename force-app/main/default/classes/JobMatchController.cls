public with sharing class JobMatchController {
    @AuraEnabled(cacheable=true)
    public static List<Job_Suggestion__c> getExistingSuggestions() {
        return [SELECT Id, Role_Title__c, Company_Name__c, Match_Score__c, Why_It_Fits__c, Skill_Gap__c, Apply_URL__c, Status__c 
                FROM Job_Suggestion__c ORDER BY CreatedDate DESC LIMIT 50];
    }

    @AuraEnabled
    public static void findJobs() {
        My_Resume__c resume = [SELECT Skills__c, Experience_Summary__c FROM My_Resume__c ORDER BY CreatedDate DESC LIMIT 1];
        String prompt = 'Based on these skills: ' + resume.Skills__c + ' and experience: ' + resume.Experience_Summary__c + 
                      ', suggest 5 job roles. Return ONLY a JSON array of objects with keys: "roleTitle", "companyName", "matchScore", "whyItFits", "skillGap", "applyUrl".';
        
        String response = GroqService.callGroq(prompt);
        if (response.contains('[')) {
            response = response.substring(response.indexOf('['), response.lastIndexOf(']') + 1);
        }
        
        List<Object> rawList = (List<Object>)JSON.deserializeUntyped(response);
        List<Job_Suggestion__c> newSugg = new List<Job_Suggestion__c>();
        for (Object obj : rawList) {
            Map<String, Object> m = (Map<String, Object>)obj;
            newSugg.add(new Job_Suggestion__c(
                Role_Title__c = (String)m.get('roleTitle'),
                Company_Name__c = (String)m.get('companyName'),
                Match_Score__c = Decimal.valueOf(String.valueOf(m.get('matchScore'))),
                Why_It_Fits__c = (String)m.get('whyItFits'),
                Skill_Gap__c = (String)m.get('skillGap'),
                Apply_URL__c = (String)m.get('applyUrl'),
                Status__c = 'Saved'
            ));
        }
        insert newSugg;
    }
}