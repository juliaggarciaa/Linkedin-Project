public with sharing class RejectionAnalyzerController {
    @AuraEnabled
    public static void analyzeRejection(Id applicationId) {
        Job_Application__c app = [SELECT Id, Job_Suggestion__r.Role_Title__c, Job_Suggestion__r.Skill_Gap__c FROM Job_Application__c WHERE Id = :applicationId LIMIT 1];
        String prompt = 'Analyze why a candidate might be rejected for ' + app.Job_Suggestion__r.Role_Title__c + 
                      ' given these skill gaps: ' + app.Job_Suggestion__r.Skill_Gap__c + '. Provide coaching.';
        String response = GroqService.callGroq(prompt);
        // We'll update the Job Suggestion's Rejection_Analysis__c via the Application record
        Job_Suggestion__c sugg = [SELECT Id FROM Job_Suggestion__c WHERE Id = :app.Job_Suggestion__c LIMIT 1];
        sugg.Rejection_Analysis__c = response;
        update sugg;
    }
}