@IsTest
public class Cls_EntryCriteriaAnalyzerTest {
    
    @IsTest
    static void testDoesRecordApply() {
        
        // Crear un registro de prueba
        Lead testLead = new Lead(
            LastName = 'Doe',
            FirstName = 'John',
            LeadSource = 'webstore',
            IsConverted = false,
            Email = 'test@test.com',
            Phone = '635112310'
        );

        insert testLead;


        Test.setCreatedDate(testLead.Id, DateTime.newInstance(2023, 1, 1, 0, 0, 0));

        // Criterio que debería aplicar
        String criteria = 
            'String;LeadSource;notEquals;Null|' +
            'String;LeadSource;In;webstore,Web de la marca OR String;LeadSource;In;webstore|' +
            'Boolean;IsConverted;equals;false|' +
            'String;LeadSource;contains;store|' +
            'Date;CreatedDate;after;2022-12-31';

        Boolean result = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteria);
        System.assert(result, 'El registro debería aplicar al criterio.');

        // Criterio que no debería aplicar
        String criteriaNotMatching = 
            'String;LeadSource;equals;webstore|' +
            'Boolean;IsConverted;equals;true|' +
            'Date;CreatedDate;before;2022-12-31';

        Boolean resultNotMatching = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteriaNotMatching);
        System.assert(!resultNotMatching, 'El registro no debería aplicar al criterio.');
    }

    @IsTest
    static void testDoesRecordApply_NullAndNotNull() {

        // Crear un registro de prueba con campos nulos
        Lead testLead = new Lead(
            LastName = 'Doe',
            FirstName = 'John',
            LeadSource = null,
            Email = 'test@test.com',
            Phone = '635112310',
            IsConverted = false
        );

        insert testLead;

        // Criterio que verifica nulo
        String criteriaNull = 'String;LeadSource;equals;Null';
        Boolean resultNull = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteriaNull);
        System.assert(resultNull, 'El campo LeadSource debería ser nulo.');

        // Criterio que verifica no nulo
        String criteriaNotNull = 'String;LeadSource;equals;NotNull';
        Boolean resultNotNull = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteriaNotNull);
        System.assert(!resultNotNull, 'El campo LeadSource no debería ser no nulo.');

        // Criterio que verifica nulo
        String criteriaNull2 = 'String;LeadSource;notEquals;NotNull';
        Boolean resultNull2 = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteriaNull2);
        System.assert(resultNull, 'El campo LeadSource debería ser nulo.');

        // Criterio que verifica no nulo
        String criteriaNotNull2 = 'String;LeadSource;notEquals;Null';
        Boolean resultNotNull2 = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteriaNotNull2);
        System.assert(!resultNotNull, 'El campo LeadSource no debería ser no nulo.');
    }

    @IsTest
    static void testDoesRecordApply_SubFields() {

    
        // Crear datos relacionados
        Account account = new Account(Name = 'Test Account');
        insert account;

        Lead testLead = new Lead(
            LastName = 'Doe',
            FirstName = 'John',
            Company = 'Test Company',
            Email = 'test@test.com',
            Phone = '635112310'
        );

        insert testLead;

        Lead leadTest = [SELECT FirstName FROM Lead WHERE Id =: testLead.Id LIMIT 1];

        // Criterio que verifica un subcampo
        String criteria = 'String;FirstName;equals;John';
        Boolean result = Cls_EntryCriteriaAnalyzer.doesRecordApply(leadTest, criteria);
        System.assert(result, 'El registro debería aplicar al criterio con subcampo.');
    }

    @IsTest
    static void testDoesRecordApply_MultipleConditions() {


        // Crear un registro de prueba
        Lead testLead = new Lead(
            LastName = 'Doe',
            FirstName = 'John',
            LeadSource = 'webstore',
            IsConverted = false,
            Email = 'test@test.com',
            Phone = '635112310',
            AnnualRevenue = 1000
        );

        insert testLead;

        
        Test.setCreatedDate(testLead.Id, DateTime.newInstance(2023, 1, 1, 0, 0, 0));

        // Criterios múltiples
        String criteria = 
            'String;LeadSource;equals;webstore|' +
            'Boolean;IsConverted;equals;false|' +
            'Decimal;AnnualRevenue;greaterThan;500|' +
            'Date;CreatedDate;after;2022-12-31';

        // Criterios múltiples
        String criteria2 = 
            'String;LeadSource;equals;webstore|' +
            'Boolean;IsConverted;equals;false|' +
            'Decimal;AnnualRevenue;lessThan;1500|' +
            'Integer;Phone;equals;635112310|' +
            'Date;CreatedDate;before;2022-12-31';
        
        // Criterios múltiples
        String criteria3 = 
            'String;LeadSource;notIn;Web de la marca, valorImaginario|' +
            'Boolean;IsConverted;equals;false|' +
            'Decimal;AnnualRevenue;greaterOrEquals;1000|' +
            'Date;CreatedDate;onOrAfter;2022-12-31';

        // Criterios múltiples
        String criteria4 = 
            'String;LeadSource;equals;webstore|' +
            'Boolean;IsConverted;equals;false|' +
            'Decimal;AnnualRevenue;lessOrEquals;1000|' +
            'Date;CreatedDate;onOrBefore;2022-12-31';

        Boolean result = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteria);
        Boolean result2 = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteria2);
        Boolean result3 = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteria3);
        Boolean result4 = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, criteria4);
        System.assert(result, 'El registro debería aplicar con condiciones múltiples.');
    }

    @IsTest
    static void testErrorHandling() {
        
        // Crear un registro de prueba
        Lead testLead = new Lead(
            LastName = 'Doe',
            FirstName = 'John',
            LeadSource = 'webstore',
            Email = 'test@test.com',
            Phone = '635112310',
            IsConverted = false
        );

        insert testLead;

        // Criterio mal formado
        String malformedCriteria = 'String;LeadSource;;webstore';
        Boolean result = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, malformedCriteria);
        System.assert(!result, 'El criterio mal formado no debería aplicar.');

        // Criterio con campo inexistente
        String nonExistentFieldCriteria = 'String;NonExistentField;equals;value';
        Boolean resultNonExistentField = Cls_EntryCriteriaAnalyzer.doesRecordApply(testLead, nonexistentFieldCriteria);
        System.assert(!resultNonExistentField, 'El campo inexistente no debería aplicar.');
    }
}