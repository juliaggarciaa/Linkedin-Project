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

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPipelineData() {
        List<String> validStages = new List<String>{'Saved', 'Applied', 'Recruiter Screen', 'Interview', 'Final Round', 'Offer', 'Rejected/Withdrawn'};
        Map<String, List<Object>> stageMap = new Map<String, List<Object>>();
        for (String s : validStages) stageMap.put(s, new List<Object>());

        List<Job_Application__c> apps = [SELECT Id, Job_Suggestion__r.Role_Title__c, Job_Suggestion__r.Company_Name__c, Application_Stage__c, Momentum_Score__c 
                                        FROM Job_Application__c ORDER BY CreatedDate DESC];
        
        for (Job_Application__c a : apps) {
            String stage = a.Application_Stage__c != null ? a.Application_Stage__c : 'Saved';
            if (stageMap.containsKey(stage)) {
                stageMap.get(stage).add(new Map<String, Object>{
                    'Id' => a.Id,
                    'role' => a.Job_Suggestion__r.Role_Title__c,
                    'company' => a.Job_Suggestion__r.Company_Name__c,
                    'score' => a.Momentum_Score__c
                });
            }
        }

        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (String s : validStages) {
            result.add(new Map<String, Object>{
                'name' => s, 
                'apps' => stageMap.get(s),
                'appCount' => (Integer)stageMap.get(s).size()
            });
        }
        return result;
    }
}