@isTest
public class Cls_ErrorHandlerTest {

    @isTest
    static void testInsertError() {

        String error        = 'Test Error';
        String code         = 'TEST_CODE';
        String type         = 'Salesforce';
        Integer lineNumber  = 100;
        String className    = 'Cls_ErrorHandler';
        String methodName   = 'testInsertError';

        Test.startTest();
        Cls_ErrorHandler.insertError( error, code, type, lineNumber, className, methodName );
        Cls_ErrorHandler.insertError( error, code, type, lineNumber, className, methodName, null );
        Cls_ErrorHandler.insertError( error, code, type, lineNumber, className, methodName, null, null );
        Test.stopTest();

        Error__c insertedError = [  SELECT CodigoError__c, Type__c, Clase__c, Metodo__c, Error__c
                                    FROM Error__c 
                                    WHERE CodigoError__c = :code 
                                    LIMIT 1 ];

        System.assertEquals( error, insertedError.Error__c );
        System.assertEquals( code, insertedError.CodigoError__c );
        System.assertEquals( type, insertedError.Type__c );
        System.assertEquals( className, insertedError.Clase__c );
        System.assertEquals( methodName, insertedError.Metodo__c );
    }

    @isTest
    static void testInsertErrorFuture() {

        String error        = 'Future Test Error';
        String code         = 'FUTURE_CODE';
        String type         = 'Integration';
        Integer lineNumber  = 200;
        String className    = 'Cls_ErrorHandler';
        String methodName   = 'testInsertErrorFuture';

        Test.startTest();
        Cls_ErrorHandler.insertErrorFuture( error, code, type, lineNumber, className, methodName );
        Cls_ErrorHandler.insertErrorFuture( error, code, type, lineNumber, className, methodName, null );
        Cls_ErrorHandler.insertErrorFuture( error, code, type, lineNumber, className, methodName, null, null );
        Test.stopTest();

        Error__c insertedError = [  SELECT CodigoError__c, Type__c, Clase__c, Metodo__c , Error__c
                                    FROM Error__c 
                                    WHERE CodigoError__c = :code 
                                    LIMIT 1 ];

        System.assertEquals( error, insertedError.Error__c );
        System.assertEquals( code, insertedError.CodigoError__c );
        System.assertEquals( type, insertedError.Type__c );
        System.assertEquals( className, insertedError.Clase__c );
        System.assertEquals( methodName, insertedError.Metodo__c );
    }

    @isTest
    static void testAddErrorToListAndInsert() {

        List< Error__c > errorList  = new List< Error__c >();
        String error                = 'List Test Error';
        String code                 = 'LIST_CODE';
        String type                 = 'Integration';
        Integer lineNumber          = 300;
        String className            = 'Cls_ErrorHandler';
        String methodName           = 'testAddErrorToListAndInsert';

        Test.startTest();
        Cls_ErrorHandler.addErrorToList( errorList, error, code, type, lineNumber, className, methodName );
        Cls_ErrorHandler.addErrorToListAndInsert( errorList, error, code, type, lineNumber, className, methodName );

        Cls_ErrorHandler.addErrorToList( errorList, error, code, type, lineNumber, className, methodName, null );
        Cls_ErrorHandler.addErrorToListAndInsert( errorList, error, code, type, lineNumber, className, methodName, null );

        Cls_ErrorHandler.addErrorToList( errorList, error, code, type, lineNumber, className, methodName, null, null );
        Cls_ErrorHandler.addErrorToListAndInsert( errorList, error, code, type, lineNumber, className, methodName, null, null );

        Cls_ErrorHandler.addErrorToList( errorList, error, code, type, lineNumber, className, methodName );
        Cls_ErrorHandler.insertListErrors( errorList );
        Test.stopTest();

        Error__c insertedError = [  SELECT CodigoError__c, Type__c, Clase__c, Metodo__c, Error__c
                                    FROM Error__c 
                                    WHERE CodigoError__c = :code 
                                    LIMIT 1 ];

        List< Error__c > listErrors = [ SELECT Id FROM Error__c LIMIT 50000 ];                                    

        System.assertEquals( error, insertedError.Error__c );
        System.assertEquals( code, insertedError.CodigoError__c );
        System.assertEquals( type, insertedError.Type__c );
        System.assertEquals( className, insertedError.Clase__c );
        System.assertEquals( methodName, insertedError.Metodo__c );

        System.assert( errorList.isEmpty() );
        System.assertEquals( 7, listErrors.size() );
    }


    @isTest
    static void testInsertListErrors() {

        List< Error__c > errorList = new List< Error__c >{
            Cls_ErrorHandler.generateError( 'Error 1', 'CODE_1', 'Integration', 1, 'Class1', 'Method1', null, null ),
            Cls_ErrorHandler.generateError( 'Error 2', 'CODE_2', 'Salesforce', 2, 'Class2', 'Method2', null, null )
        };

        Test.startTest();
        Cls_ErrorHandler.insertListErrors( errorList );
        Test.stopTest();

        List< Error__c > insertedErrors = [ SELECT CodigoError__c, Type__c, Clase__c, Metodo__c, Error__c
                                            FROM Error__c 
                                            WHERE CodigoError__c IN ( 'CODE_1', 'CODE_2' )
                                            LIMIT 50000 ];

        System.assertEquals( 2, insertedErrors.size() );
    }


    @isTest
    static void testGenerateError() {

        String error        = 'Generated Test Error';
        String code         = 'GENERATE_CODE';
        String type         = 'Integration';
        Integer lineNumber  = 400;
        String className    = 'Cls_ErrorHandler';
        String methodName   = 'testGenerateError';
        String data         = 'Test Data';
        String origin       = 'Salesforce';

        Test.startTest();
        Error__c generatedError = Cls_ErrorHandler.generateError( error, code, type, lineNumber, className, methodName, data, origin );
        Test.stopTest();

        System.assertNotEquals( null, generatedError );
        System.assertEquals( error, generatedError.Error__c );
        System.assertEquals( code, generatedError.CodigoError__c );
        System.assertEquals( type, generatedError.Type__c );
        System.assertEquals( className, generatedError.Clase__c );
        System.assertEquals( methodName, generatedError.Metodo__c );
        System.assertEquals( data, generatedError.Data__c );
        System.assertEquals( origin, generatedError.Causante__c );
    }


    @isTest
    static void testFailData() {

        String error        = '';
        String code         = 'GENERATE_CODE';
        String type         = 'Integration';
        Integer lineNumber  = 400;
        String className    = 'Cls_ErrorHandler';
        String methodName   = 'testGenerateError';
        String data         = 'Test Data';
        String origin       = 'Salesforce';

        Test.startTest();
        Error__c generatedError = Cls_ErrorHandler.generateError( error, code, type, lineNumber, className, methodName, data, origin );
        Test.stopTest();

        List< Error__c > listErrors = [ SELECT Id FROM Error__c LIMIT 50000 ]; 

        System.assert( listErrors.isEmpty() );
    }
}