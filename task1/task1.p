
/*------------------------------------------------------------------------
    File        : task1.p
    Purpose     : 

    Syntax      :

    Description : importing the input file

    Author(s)   : Subhash Sanjeevi
    Created     : Mon Jun 26 10:45:47 EEST 2023
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE VARIABLE lcLine      AS CHARACTER NO-UNDO.
DEFINE VARIABLE liEmpNo     AS INTEGER   NO-UNDO.
DEFINE VARIABLE liEmpNum    AS INTEGER   NO-UNDO.
DEFINE VARIABLE lcRelType   AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcFirstName AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcLastName  AS CHARACTER NO-UNDO.
DEFINE VARIABLE lcDOB       AS CHARACTER NO-UNDO.
DEFINE VARIABLE ldtDOB      AS DATE      NO-UNDO.
DEFINE VARIABLE lcRelName   AS CHARACTER NO-UNDO.

DEFINE VARIABLE lcRelations AS CHARACTER NO-UNDO INITIAL "Employee,Son,Daughter,Spouse".

DEFINE STREAM strin.
    
/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

INPUT STREAM strin FROM "task1/input/EmployeesReport_20220401_101220.csv".

LOG-MANAGER:LOGFILE-NAME = "task1/log/family_import_with_changing_values.log".

REPEAT TRANS:
    
    IMPORT STREAM strin UNFORMATTED lcLine.
    
    IF TRIM(ENTRY(1,lcLine,";"),"""") EQ "EmpNum" OR 
       TRIM(ENTRY(1,lcLine,";"),"""") EQ "Total Employees" THEN NEXT.
    
    IF NUM-ENTRIES(lcLine,";") NE 5 THEN DO:
        LOG-MANAGER:WRITE-MESSAGE("EmpNum " + STRING(liEmpNum) + " - Invalid No of Entries", "ERROR").    
        NEXT.
    END.
    
    ASSIGN liEmpNo     = INTEGER(TRIM(ENTRY(1,lcLine,";"),""""))
           lcRelType   = TRIM(ENTRY(2,lcLine,";"),"""")
           lcFirstName = TRIM(ENTRY(3,lcLine,";"),"""") 
           lcLastName  = TRIM(ENTRY(4,lcLine,";"),"""")
           lcDOB       = TRIM(ENTRY(5,lcLine,";"),"""")
           ldtDOB      = DATE(INTEGER(ENTRY(2,lcDOB,"-")),
                              INTEGER(ENTRY(3,lcDOB,"-")),
                              INTEGER(ENTRY(1,lcDOB,"-"))) NO-ERROR.
           
    IF ERROR-STATUS:ERROR THEN DO:
        LOG-MANAGER:WRITE-MESSAGE("EmpNum " + STRING(liEmpNum) + " - Invalid input values", "ERROR").    
        NEXT.        
    END.
    
    IF LOOKUP(lcRelType,lcRelations) EQ 0 THEN DO:
        LOG-MANAGER:WRITE-MESSAGE("EmpNum " + STRING(liEmpNum) + " - Invalid Relation Type", "ERROR").    
        NEXT.
    END.               
    
    IF (liEmpNo NE 0 AND lcRelType NE "Employee") OR
       (liEmpNo EQ 0 AND lcRelType EQ "Employee") THEN DO:
        LOG-MANAGER:WRITE-MESSAGE(lcLine + " - Invalid values", "ERROR").    
        NEXT.
    END.    
       
    lcRelName = "".
    
    IF liEmpNo NE 0 THEN DO:
        FIND FIRST Employee NO-LOCK WHERE
                   Employee.EmpNum EQ liEmpNo NO-ERROR.
                   
        IF NOT AVAILABLE Employee THEN DO:
            LOG-MANAGER:WRITE-MESSAGE("EmpNum " + STRING(liEmpNum) + " doesn't exists", "ERROR").    
            NEXT.                
        END.
        ELSE liEmpNum = Employee.EmpNum.
    END.
    ELSE DO:
        
        IF liEmpNum EQ 0 THEN DO:
            LOG-MANAGER:WRITE-MESSAGE(lcLine + " - No employee number is recorded", "WARN").
            NEXT.
        END.    
        
        lcRelName = lcFirstName + " " + lcLastName.
        
        FIND FIRST Family EXCLUSIVE-LOCK WHERE
                   Family.EmpNum       EQ liEmpNum   AND
                   Family.RelativeName EQ lcRelName NO-ERROR.
                   
        IF NOT AVAILABLE Family THEN DO:
            CREATE Family.
            ASSIGN Family.EmpNum       = liEmpNum
                   Family.Relation     = lcRelType
                   Family.RelativeName = lcRelName
                   Family.BirthDate    = ldtDOB.
               
            LOG-MANAGER:WRITE-MESSAGE("EmpNum " + STRING(liEmpNum) + " New Family Records created", "INFO").
            NEXT.       
        END.
        ELSE DO:
            ASSIGN Family.Relation  = lcRelType
                   Family.BirthDate = ldtDOB.
                   
            LOG-MANAGER:WRITE-MESSAGE("EmpNum " + STRING(liEmpNum) + " Family records updated", "INFO").       
        END.                                      
    END.

END.
    
INPUT STREAM strin CLOSE.

LOG-MANAGER:CLOSE-LOG().
