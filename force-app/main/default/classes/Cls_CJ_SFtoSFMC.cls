/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-14-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class Cls_CJ_SFtoSFMC {
	
	public static HttpResponse sendRequest(String setting, String body){

		WebService__mdt serviceMetadata = WebService__mdt.getInstance(setting);

		try {

			HttpRequest req = new HttpRequest();
			req.setEndpoint(serviceMetadata.Endpoint__c);
			req.setMethod('POST');
			req.setHeader('Content-Type', 'application/json');
			req.setHeader('api-key', serviceMetadata.API_KEY__c);
			req.setBody(body);

			Http http = new Http();
			HttpResponse res = http.send(req);

			System.debug('Brevo Response: ' + res.getBody());
			return res;

		} catch (Exception exc) {
			System.debug( ' Exception Message: ' + exc.getMessage() );
			System.debug( ' Stack Trace: ' + exc.getStackTraceString() );
			throw exc;
		}


	}
}