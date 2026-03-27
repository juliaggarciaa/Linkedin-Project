public with sharing class InterviewPrepController {
    @AuraEnabled
    public static void generateInterviewQuestions(Id applicationId) {
        Job_Application__c app = [SELECT Id, Job_Suggestion__r.Role_Title__c, Job_Suggestion__r.Why_It_Fits__c FROM Job_Application__c WHERE Id = :applicationId LIMIT 1];
        String prompt = 'Generate 5 interview questions and answer frameworks for the role: ' + app.Job_Suggestion__r.Role_Title__c + '. Return as plain text.';
        String response = GroqService.callGroq(prompt);
        app.Notes__c = response;
        update app;
    }
}