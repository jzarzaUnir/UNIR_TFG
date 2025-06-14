@isTest
public class Cls_DynamicQueryBuilderTest {
    @isTest
    static void testDynamicQueryBuilder() {
        // Datos de prueba
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;

        // Probar la construcción básica de la query
        Cls_DynamicQueryBuilder queryBuilder = new Cls_DynamicQueryBuilder('Contact')
            .addField('Id')
            .addField('LastName')
            .addConditionSentence('1', 'AccountId = :accountId')
            .setLogicalOperators('1');

        queryBuilder.addBindVariable('accountId', testAccount.Id);

        String query = queryBuilder.buildQuery();
        System.assert(query.contains('SELECT Id, LastName FROM Contact WHERE AccountId = :accountId'), 'Query construction failed');

        // Ejecutar la query
        List<SObject> result = queryBuilder.executeQuery();
        System.assertEquals(1, result.size(), 'Query did not return expected results');
        System.assertEquals(testContact.Id, result[0].Id, 'Returned contact does not match');

        // Probar subqueries
        Cls_DynamicQueryBuilder subQuery = new Cls_DynamicQueryBuilder('Opportunity')
            .addFields(new List<String>{'Id','Name'})
            .addConditionSentence('1', 'AccountId = :accountId')
            .setLogicalOperators('1');

        subQuery.addBindVariable('accountId', testAccount.Id);

        queryBuilder = new Cls_DynamicQueryBuilder('Account')
            .addField('Id')
            .addField('Name')
            .addSubQuery(subQuery);

        query = queryBuilder.buildQuery();
        System.assert(query.contains('(SELECT Id, Name FROM Opportunity WHERE AccountId = :accountId)'), 'Subquery construction failed');

        // Probar TYPEOF
        Map<String, List<String>> typeOfConditions = new Map<String, List<String>>{
            'User' => new List<String>{'Id', 'Name'},
            'Group' => new List<String>{'Id', 'DeveloperName'}
        };
        queryBuilder = new Cls_DynamicQueryBuilder('Contact')
            .addField('Id')
            .addTypeOf('Owner', typeOfConditions);

        query = queryBuilder.buildQuery();
        System.assert(query.contains('TYPEOF Owner WHEN User THEN Id, Name WHEN Group THEN Id, DeveloperName END'), 'TYPEOF construction failed');

        // Probar límites
        queryBuilder = new Cls_DynamicQueryBuilder('Contact')
            .addField('Id')
            .setLimit(1);

        query = queryBuilder.buildQuery();
        System.assert(query.contains('LIMIT 1'), 'LIMIT clause construction failed');

        // Probar ordenación
        queryBuilder = new Cls_DynamicQueryBuilder('Contact')
            .addField('Id')
            .setOrderBy('LastName ASC');

        query = queryBuilder.buildQuery();
        System.assert(query.contains('ORDER BY LastName ASC'), 'ORDER BY clause construction failed');
    }
}