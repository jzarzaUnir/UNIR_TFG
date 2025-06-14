@isTest
public class Cls_DynamicJSONGeneratorTest {

	@isTest
	static void testCreateJson() {
		// Recuperar datos simulados creados en testSetup
		Account acc = [SELECT Id FROM Account LIMIT 1];
		update acc;

		Contact con1 = new Contact(LastName = 'Doe', Email = 'test@test.com', Birthdate = Date.newInstance(2000,02,07), AccountId = acc.Id);
		Contact con2 = new Contact(LastName = 'Smith', Email = 'test@test.com', Birthdate = Date.newInstance(2000,02,07),  AccountId = acc.Id);
		insert new List<Contact>{con1, con2};

		Account testAccount = [SELECT Id, Name,AnnualRevenue,CreatedDate,CreatedBy.Id,Owner.Id,Owner.Name, (SELECT Id, LastName, Email, Birthdate FROM Contacts) FROM Account WHERE Id =: acc.Id LIMIT 1];
		// Crear mapas simulados para los parámetros del método
		Map<String, String> camposLista = new Map<String, String>{
			'Name' => 'Name',
			'Annual_Revenue' => 'AnnualRevenue',
			'Created_By' => 'CreatedBy.Id',
			'CreatedDate' => 'CreatedDate',
			'Owner:User:Id' => 'Owner.Id',
			'Owner:Group:Id' => 'Owner.Id',
			'Owner:Name' => 'Owner.Name',
			'Contacts' => 'Contacts'
		};
		Map<String, Map<String, String>> mapCamposRelated = new Map<String, Map<String, String>>{
			'Contacts' => new Map<String, String>{
				'LastName' => 'LastName',
				'Email' => 'Email',
				'Birthdate' => 'Birthdate'
			}
		};

		// Instanciar la clase
		Cls_DynamicJSONGenerator jsonGenerator = new Cls_DynamicJSONGenerator();

		// Invocar el método createJsonObject
		Test.startTest();
		jsonGenerator.createJsonObject(testAccount, camposLista, mapCamposRelated);
		String jsonGenerado = jsonGenerator.retriveJson();
		System.debug(jsonGenerado);
		Test.stopTest();

		// Validar que el JSON dinámico se generó correctamente
		System.assertNotEquals(jsonGenerado, null, 'Se generó correctamente el JSON');
	}
	
}