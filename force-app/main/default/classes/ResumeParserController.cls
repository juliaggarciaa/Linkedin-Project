public with sharing class ResumeParserController {
    @AuraEnabled
    public static void parseResume(String rawText) {
        // Prepare the prompt
        String prompt = 'Parse the following resume and return ONLY a JSON object with keys: "skills", "summary", "education", "yearsExperience". ' +
                      'Resume: ' + rawText;
        
        // Perform the callout FIRST (before any DML)
        String response = GroqService.callGroq(prompt);
        
        if (response.contains('```')) {
            response = response.substringAfter('json').substringBeforeLast('```').trim();
        } else if (response.contains('{')) {
            response = response.substring(response.indexOf('{'), response.lastIndexOf('}') + 1);
        }
        
        Map<String, Object> parsed = (Map<String, Object>)JSON.deserializeUntyped(response);
        
        // Now handle the DML
        My_Resume__c resume;
        List<My_Resume__c> resumes = [SELECT Id FROM My_Resume__c ORDER BY CreatedDate DESC LIMIT 1];
        if (resumes.isEmpty()) {
            resume = new My_Resume__c(Name = 'My Main Resume');
        } else {
            resume = resumes[0];
        }
        
        resume.Skills__c = (String)parsed.get('skills');
        resume.Experience_Summary__c = (String)parsed.get('summary');
        resume.Education__c = (String)parsed.get('education');
        String yrs = String.valueOf(parsed.get('yearsExperience'));
        resume.Years_of_Experience__c = Decimal.valueOf(yrs.replaceAll('[^0-9.]', ''));
        
        upsert resume;
    }
}