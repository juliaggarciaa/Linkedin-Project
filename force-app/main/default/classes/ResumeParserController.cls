public with sharing class ResumeParserController {
    @AuraEnabled
    public static void parseResume(String rawText, String base64PDF) {
        String contentToParse = rawText;
        
        // If it's a PDF, we first extract the text using Groq
        if (String.isNotBlank(base64PDF)) {
            String extractPrompt = 'Extract all text content from this base64-encoded PDF resume and return it as plain text. Do not add any explanation or greeting. Just return the extracted text: ' + base64PDF.left(30000); // Limit to avoid token issues
            contentToParse = GroqService.callGroq(extractPrompt);
        }

        if (String.isBlank(contentToParse)) {
            throw new AuraHandledException('Resume content is empty.');
        }

        // Prepare the parsing prompt
        String prompt = 'Parse the following resume and return ONLY a JSON object with keys: "skills", "summary", "education", "yearsExperience". ' +
                      'Resume: ' + contentToParse;
        
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
        
        resume.Raw_Resume_Text__c = contentToParse;
        resume.Skills__c = formatField(parsed.get('skills'));
        resume.Experience_Summary__c = formatField(parsed.get('summary'));
        resume.Education__c = formatField(parsed.get('education'));
        
        Object yearsExpObj = parsed.get('yearsExperience');
        if (yearsExpObj != null) {
            String yrs = String.valueOf(yearsExpObj);
            // Only attempt conversion if the string is not 'null' and not blank
            if (!yrs.equalsIgnoreCase('null') && String.isNotBlank(yrs)) {
                String cleanedYrs = yrs.replaceAll('[^0-9.]', '');
                if (String.isNotBlank(cleanedYrs)) {
                    resume.Years_of_Experience__c = Decimal.valueOf(cleanedYrs);
                }
            }
        }
        
        upsert resume;
    }

    private static String formatField(Object val) {
        if (val == null) return '';
        if (val instanceof List<Object>) {
            List<String> items = new List<String>();
            for (Object o : (List<Object>)val) items.add(String.valueOf(o));
            return String.join(items, ', ');
        }
        return String.valueOf(val);
    }
}