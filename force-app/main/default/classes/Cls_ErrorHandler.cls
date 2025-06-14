public without sharing class Cls_ErrorHandler {

    public static String STR_ERROR_SALESFORCE   = 'Salesforce';
    public static String STR_ERROR_INTEGRATION  = 'Integración';
    public static Set< String > setValidErrors  = new Set< String >{ STR_ERROR_INTEGRATION, STR_ERROR_SALESFORCE };

    // Sync Methods
    // Use case: Cls_ErrorHandler.insertError( stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName );
    public static void insertError( String strError, String strCode, String strType, 
                                    Integer intErrorLine, String strClassName, String strClassMethod ) {

        insertError( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, null, null );
    }

    // Use case: Cls_ErrorHandler.insertError( stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData );
    public static void insertError( String strError, String strCode, String strType,
                                    Integer intErrorLine, String strClassName, String strClassMethod, String strData ) {

        insertError( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, null );
    }

    // Use case: Cls_ErrorHandler.insertError( stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData, stringOrigin );
    public static void insertError( String strError, String strCode, String strType,
                                    Integer intErrorLine, String strClassName, String strClassMethod,
                                    String strData, String strOrigin ) {

        Error__c errorToInsert = generateError( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, strOrigin );
        insert errorToInsert;
    }


    // Async Methods
    // Use case: Cls_ErrorHandler.insertErrorFuture( stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName );
    public static void insertErrorFuture(   String strError, String strCode, String strType, 
                                            Integer intErrorLine, String strClassName, String strClassMethod ) {

        insertErrorFuture( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, null, null );
    }

    // Use case: Cls_ErrorHandler.insertErrorFuture( stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData );
    public static void insertErrorFuture(   String strError, String strCode, String strType,
                                            Integer intErrorLine, String strClassName, String strClassMethod, String strData ) {

        insertErrorFuture( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, null );
    }

    // Use case: Cls_ErrorHandler.insertErrorFuture( stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData, stringOrigin );
    @future
    public static void insertErrorFuture(   String strError, String strCode, String strType,
                                            Integer intErrorLine, String strClassName, String strClassMethod,
                                            String strData, String strOrigin ) {

        Error__c errorToInsert = generateError( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, strOrigin );
        insert errorToInsert;
    }


    // List Methods
    // Use case: Cls_ErrorHandler.addErrorToList( listErrors, stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName );
    public static void addErrorToList(  List< Error__c > listErrors, String strError, String strCode, String strType, 
                                        Integer intErrorLine, String strClassName, String strClassMethod ) {

        addErrorToList( listErrors, strError, strCode, strType, intErrorLine, strClassName, strClassMethod, null, null );
    }

    // Use case: Cls_ErrorHandler.addErrorToList( listErrors, stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData );
    public static void addErrorToList(  List< Error__c > listErrors, String strError, String strCode, String strType,
                                        Integer intErrorLine, String strClassName, String strClassMethod, String strData ) {

        addErrorToList( listErrors, strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, null );
    }

    // Use case: Cls_ErrorHandler.addErrorToList( listErrors, stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData, stringOrigin );
    public static void addErrorToList(  List< Error__c > listErrors, String strError, String strCode, String strType,
                                        Integer intErrorLine, String strClassName, String strClassMethod,
                                        String strData, String strOrigin ) {

        listErrors.add( generateError( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, strOrigin ) );
    }

    // Use case: Cls_ErrorHandler.addErrorToList( listErrors, stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName );
    public static void addErrorToListAndInsert( List< Error__c > listErrors, String strError, String strCode, String strType, 
                                                Integer intErrorLine, String strClassName, String strClassMethod ) {

        addErrorToListAndInsert( listErrors, strError, strCode, strType, intErrorLine, strClassName, strClassMethod, null, null );
        insert listErrors;
        listErrors.clear();
    }

    // Use case: Cls_ErrorHandler.addErrorToList( listErrors, stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData );
    public static void addErrorToListAndInsert(  List< Error__c > listErrors, String strError, String strCode, String strType,
                                        Integer intErrorLine, String strClassName, String strClassMethod, String strData ) {
        
        addErrorToListAndInsert( listErrors, strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, null );
        insert listErrors;
        listErrors.clear();
    }

    // Use case: Cls_ErrorHandler.addErrorToListAndInsert( listErrors, stringError, stringErrorCode, stringType, integerErrorLine, stringClassName, stringMethodName, stringData, stringOrigin );
    public static void addErrorToListAndInsert(  List< Error__c > listErrors, String strError, String strCode, String strType,
                                        Integer intErrorLine, String strClassName, String strClassMethod, String strData, String strOrigin ) {

        listErrors.add( generateError( strError, strCode, strType, intErrorLine, strClassName, strClassMethod, strData, strOrigin ) );
        insert listErrors;
        listErrors.clear();
    }

    // Use case: Cls_ErrorHandler.insertListErrors( listErrors );
    public static void insertListErrors( List< Error__c > listErrors ){

        if( !listErrors.isEmpty() ){
            insert listErrors;
            listErrors.clear();
        }
    }


    // Data generation
    public static Error__c generateError(   String strError, String strCode, String strType, Integer intErrorLine, 
                                            String strClassName, String strClassMethod, String strData, String strOrigin ) {
        
        String strFirstName = Userinfo.getFirstName();
        String strOrgName   = Userinfo.getOrganizationName();
        String strProfile   = UserInfo.getProfileId();
        String strUserId    = UserInfo.getUserId();
        
        // Return if no error data to log
        if ( String.isEmpty( strError ) ) {
            return null;
        }
        
        // Sanitize length inputs
        strType         =   ( String.isNotBlank( strType ) )                ? strType.left( 225 )           : 'Otro error';
        strCode         =   ( String.isNotBlank( strCode ) )                ? strCode                       : 'Sin codigo';
        intErrorLine    =   ( intErrorLine != null && intErrorLine > 0 )    ? intErrorLine                  : 0;
        strError        =   ( String.isNotBlank( strError ) )               ? strError.left( 2000 )         : '';
        strCode         =   ( String.isNotBlank( strCode ) )                ? strCode.left( 250 )           : '';
        strData         =   ( String.isNotBlank( strData ) )                ? strData.left( 32000 )         : '';
        strClassMethod  =   ( String.isNotBlank( strClassMethod ) )         ? strClassMethod.left( 225 )    : '';
        strClassName    =   ( String.isNotBlank( strClassName ) )           ? strClassName.left( 225 )      : '';
        strFirstName    =   ( String.isNotBlank( strFirstName ) )           ? strFirstName.left( 80 )       : '';
        strOrgName      =   ( String.isNotBlank( strOrgName ) )             ? strOrgName.left( 225 )        : '';
        strOrigin       =   ( setValidErrors.contains( strOrigin ) )        ? strOrigin                     : 'Otros';

        return new Error__c(
            Error__c            = strError,
            Type__c             = strType,
            LineNumber__c       = intErrorLine,
            Clase__c            = strClassName,
            Metodo__c           = strClassMethod,
            UserFName__c        = strFirstName,
            Organizacion__c     = strOrgName,
            UserProfileName__c  = strProfile,
            User__c             = strUserId,
            CodigoError__c      = strCode,
            Data__c             = strData,
            Causante__c         = strOrigin
        );
    }
}